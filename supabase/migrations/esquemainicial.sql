-- =============================================================================
-- MIGRACIÓN 01: ESQUEMA INICIAL 3NF, RLS Y LÓGICA DE NEGOCIO (TDSPORT)
-- =============================================================================

-- Habilitar extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. TABLA: perfiles (Extensión pública de auth.users)
-- -----------------------------------------------------------------------------
CREATE TABLE public.perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    es_pro BOOLEAN DEFAULT FALSE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Trigger para crear perfil automáticamente al registrarse en Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.perfiles (id, nombre, telefono, fecha_nacimiento, es_pro)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nombre', 'Usuario'),
        NEW.raw_user_meta_data->>'telefono',
        (NEW.raw_user_meta_data->>'fecha_nacimiento')::DATE,
        FALSE
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 2. TABLAS DE CATÁLOGOS Y TORNEOS
-- -----------------------------------------------------------------------------
CREATE TABLE public.estados_partido (
    id INT PRIMARY KEY,
    descripcion VARCHAR(20) NOT NULL UNIQUE
);

-- Poblar catálogo base (1=Futuro, 2=En Juego, 3=Finalizado)
INSERT INTO public.estados_partido (id, descripcion) VALUES
    (1, 'FUTURO'),
    (2, 'EN_JUEGO'),
    (3, 'FINALIZADO');

CREATE TABLE public.equipos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    escudo_url VARCHAR(255)
);

CREATE TABLE public.torneos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    formato VARCHAR(50) NOT NULL, -- 'LIGA' o 'GRUPOS_ELIMINATORIA'
    estado_activo BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- -----------------------------------------------------------------------------
-- 3. TABLA: partidos
-- -----------------------------------------------------------------------------
CREATE TABLE public.partidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    torneo_id UUID NOT NULL REFERENCES public.torneos(id) ON DELETE CASCADE,
    local_id UUID NOT NULL REFERENCES public.equipos(id),
    visitante_id UUID NOT NULL REFERENCES public.equipos(id),
    fecha_hora TIMESTAMP WITH TIME ZONE NOT NULL,
    goles_local INT,
    goles_visitante INT,
    estado_id INT NOT NULL DEFAULT 1 REFERENCES public.estados_partido(id),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT check_equipos_distintos CHECK (local_id <> visitante_id)
);

-- -----------------------------------------------------------------------------
-- 4. TABLAS: quinielas Y participantes (Junction Table)
-- -----------------------------------------------------------------------------
CREATE TABLE public.quinielas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    torneo_id UUID NOT NULL REFERENCES public.torneos(id) ON DELETE CASCADE,
    creador_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    codigo_acceso VARCHAR(10) NOT NULL UNIQUE,
    limite_usuarios INT NOT NULL CHECK (limite_usuarios > 0),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.quiniela_usuarios (
    quiniela_id UUID NOT NULL REFERENCES public.quinielas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    puntos_totales INT DEFAULT 0 NOT NULL,
    unido_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (quiniela_id, usuario_id)
);

-- -----------------------------------------------------------------------------
-- 5. TABLA: pronosticos
-- -----------------------------------------------------------------------------
CREATE TABLE public.pronosticos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    partido_id UUID NOT NULL REFERENCES public.partidos(id) ON DELETE CASCADE,
    quiniela_id UUID NOT NULL REFERENCES public.quinielas(id) ON DELETE CASCADE,
    pred_goles_local INT NOT NULL CHECK (pred_goles_local >= 0),
    pred_goles_visitante INT NOT NULL CHECK (pred_goles_visitante >= 0),
    puntos_obtenidos INT DEFAULT 0 NOT NULL,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_pronostico_usuario_partido_quiniela UNIQUE (usuario_id, partido_id, quiniela_id)
);

-- -----------------------------------------------------------------------------
-- 6. PROCEDIMIENTOS ALMACENADOS (RPC) Y REGLAS DE NEGOCIO
-- -----------------------------------------------------------------------------

-- RPC: Unirse a Quiniela por Código
CREATE OR REPLACE FUNCTION public.join_quiniela(codigo_ingresado VARCHAR)
RETURNS JSON AS $$
DECLARE
    v_quiniela RECORD;
    v_actuales INT;
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'No autenticado');
    END IF;

    -- Buscar quiniela por código
    SELECT * INTO v_quiniela FROM public.quinielas WHERE codigo_acceso = UPPER(codigo_ingresado);
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Código de quiniela no válido');
    END IF;

    -- Comprobar si ya está unido
    IF EXISTS (SELECT 1 FROM public.quiniela_usuarios WHERE quiniela_id = v_quiniela.id AND usuario_id = v_user_id) THEN
        RETURN json_build_object('success', true, 'quiniela_id', v_quiniela.id, 'message', 'Ya eres miembro');
    END IF;

    -- Verificar límite de participantes
    SELECT COUNT(*) INTO v_actuales FROM public.quiniela_usuarios WHERE quiniela_id = v_quiniela.id;
    IF v_actuales >= v_quiniela.limite_usuarios THEN
        RETURN json_build_object('success', false, 'error', 'La quiniela ha alcanzado el límite de participantes');
    END IF;

    -- Insertar participante
    INSERT INTO public.quiniela_usuarios (quiniela_id, usuario_id, puntos_totales)
    VALUES (v_quiniela.id, v_user_id, 0);

    RETURN json_build_object('success', true, 'quiniela_id', v_quiniela.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- RPC: Cálculo Automático de Puntos según Regla RN01
-- RN01: Resultado exacto = 5 pts | Ganador/Empate = 3 pts | Diferencia de goles = +1 pt extra
CREATE OR REPLACE FUNCTION public.calcular_puntos_partido()
RETURNS TRIGGER AS $$
DECLARE
    r RECORD;
    v_puntos INT;
    v_real_local INT := NEW.goles_local;
    v_real_vis INT := NEW.goles_visitante;
    v_dif_real INT := v_real_local - v_real_vis;
BEGIN
    -- Solo procesar cuando pasa a FINALIZADO (estado_id = 3) y tiene goles cargados
    IF NEW.estado_id = 3 AND NEW.goles_local IS NOT NULL AND NEW.goles_visitante IS NOT NULL THEN
        FOR r IN 
            SELECT id, usuario_id, quiniela_id, pred_goles_local, pred_goles_visitante
            FROM public.pronosticos
            WHERE partido_id = NEW.id
        LOOP
            v_puntos := 0;

            -- 1. Acierto de marcador exacto (5 pts)
            IF r.pred_goles_local = v_real_local AND r.pred_goles_visitante = v_real_vis THEN
                v_puntos := 5;
            ELSE
                -- 2. Acierto de ganador o empate (3 pts)
                IF (r.pred_goles_local > r.pred_goles_visitante AND v_real_local > v_real_vis) OR
                   (r.pred_goles_local < r.pred_goles_visitante AND v_real_local < v_real_vis) OR
                   (r.pred_goles_local = r.pred_goles_visitante AND v_real_local = v_real_vis) THEN
                    v_puntos := 3;

                    -- 3. Diferencia de goles idéntica (1 pt extra) en partidos no empatados
                    IF (r.pred_goles_local - r.pred_goles_visitante) = v_dif_real THEN
                        v_puntos := v_puntos + 1;
                    END IF;
                END IF;
            END IF;

            -- Actualizar puntos en el pronóstico
            UPDATE public.pronosticos
            SET puntos_obtenidos = v_puntos,
                actualizado_en = timezone('utc'::text, now())
            WHERE id = r.id;

            -- Recalcular el acumulado total del usuario en esa quiniela
            UPDATE public.quiniela_usuarios qu
            SET puntos_totales = (
                SELECT COALESCE(SUM(puntos_obtenidos), 0)
                FROM public.pronosticos p
                WHERE p.usuario_id = r.usuario_id AND p.quiniela_id = r.quiniela_id
            )
            WHERE qu.quiniela_id = r.quiniela_id AND qu.usuario_id = r.usuario_id;

        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_calculo_puntos_partido
    AFTER UPDATE OF estado_id, goles_local, goles_visitante ON public.partidos
    FOR EACH ROW EXECUTE FUNCTION public.calcular_puntos_partido();

-- -----------------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY (RLS)
-- -----------------------------------------------------------------------------

-- Habilitar RLS en tablas expuestas
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.torneos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados_partido ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quinielas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiniela_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pronosticos ENABLE ROW LEVEL SECURITY;

-- Políticas: Lectura de catálogos y torneos (Pública para usuarios autenticados)
CREATE POLICY "Lectura publica torneos" ON public.torneos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Lectura publica equipos" ON public.equipos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Lectura publica estados" ON public.estados_partido FOR SELECT TO authenticated USING (true);
CREATE POLICY "Lectura publica partidos" ON public.partidos FOR SELECT TO authenticated USING (true);

-- Políticas: Perfiles
CREATE POLICY "Lectura perfiles" ON public.perfiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Modificacion perfil propio" ON public.perfiles FOR UPDATE TO authenticated 
    USING (auth.uid() = id) 
    WITH CHECK (auth.uid() = id);

-- Políticas: Quinielas
CREATE POLICY "Lectura quinielas" ON public.quinielas FOR SELECT TO authenticated USING (true);
CREATE POLICY "Creacion quinielas" ON public.quinielas FOR INSERT TO authenticated 
    WITH CHECK (auth.uid() = creador_id);

-- Políticas: Participantes de Quiniela
CREATE POLICY "Lectura miembros quiniela" ON public.quiniela_usuarios FOR SELECT TO authenticated USING (true);

-- Políticas: Pronósticos (Bloqueo en partidos que ya no son FUTURO [estado_id = 1])
CREATE POLICY "Lectura pronosticos" ON public.pronosticos FOR SELECT TO authenticated USING (
    -- Un usuario normal solo ve sus pronósticos; un usuario PRO puede ver todos los pronósticos si el partido finalizó
    usuario_id = auth.uid() 
    OR (
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND es_pro = TRUE)
        AND EXISTS (SELECT 1 FROM public.partidos WHERE id = pronosticos.partido_id AND estado_id = 3)
    )
);

CREATE POLICY "Insertar pronosticos en partidos futuros" ON public.pronosticos FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = usuario_id
        AND EXISTS (SELECT 1 FROM public.partidos WHERE id = partido_id AND estado_id = 1)
    );

CREATE POLICY "Modificar pronosticos en partidos futuros" ON public.pronosticos FOR UPDATE TO authenticated
    USING (
        auth.uid() = usuario_id
        AND EXISTS (SELECT 1 FROM public.partidos WHERE id = pronosticos.partido_id AND estado_id = 1)
    )
    WITH CHECK (
        auth.uid() = usuario_id
        AND EXISTS (SELECT 1 FROM public.partidos WHERE id = pronosticos.partido_id AND estado_id = 1)
    );