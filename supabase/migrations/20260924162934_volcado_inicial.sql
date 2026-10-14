-- 1. Tablas Catálogo y Base
CREATE TABLE public.estados_partido (
    id INT PRIMARY KEY,
    descripcion VARCHAR(20) NOT NULL
);

CREATE TABLE public.equipos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(50) NOT NULL,
    escudo_url VARCHAR(255)
);

CREATE TABLE public.torneos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    formato VARCHAR(50),
    estado_activo BOOLEAN DEFAULT true
);

-- 2. Tabla Perfiles (Vinculada a auth.users de Supabase)
CREATE TABLE public.perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre VARCHAR(100),
    telefono VARCHAR(20),
    es_pro BOOLEAN DEFAULT false
);

-- 3. Tabla Partidos
CREATE TABLE public.partidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    torneo_id UUID REFERENCES public.torneos(id),
    local_id UUID REFERENCES public.equipos(id),
    visitante_id UUID REFERENCES public.equipos(id),
    fecha_hora TIMESTAMP WITH TIME ZONE,
    goles_local INT,
    goles_visitante INT,
    estado_id INT REFERENCES public.estados_partido(id) DEFAULT 1
);

-- 4. Tablas de Quinielas y Pronósticos
CREATE TABLE public.quinielas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    torneo_id UUID REFERENCES public.torneos(id),
    creador_id UUID REFERENCES public.perfiles(id),
    nombre VARCHAR(100) NOT NULL,
    codigo_acceso VARCHAR(10) UNIQUE,
    limite_usuarios INT
);

CREATE TABLE public.quiniela_usuarios (
    quiniela_id UUID REFERENCES public.quinielas(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES public.perfiles(id) ON DELETE CASCADE,
    puntos_totales INT DEFAULT 0,
    PRIMARY KEY (quiniela_id, usuario_id)
);

CREATE TABLE public.pronosticos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES public.perfiles(id) ON DELETE CASCADE,
    partido_id UUID REFERENCES public.partidos(id) ON DELETE CASCADE,
    quiniela_id UUID REFERENCES public.quinielas(id) ON DELETE CASCADE,
    pred_goles_local INT,
    pred_goles_visitante INT,
    puntos_obtenidos INT DEFAULT 0,
    UNIQUE (usuario_id, partido_id, quiniela_id)
);

-- 5. Insertar estados iniciales para que la web funcione
INSERT INTO public.estados_partido (id, descripcion) VALUES
(1, 'FUTURO'),
(2, 'EN JUEGO'),
(3, 'FINALIZADO');

-- 6. Habilitar WebSockets para React
ALTER PUBLICATION supabase_realtime ADD TABLE partidos;

-- 7. Funciones RPC y Triggers de Negocio
CREATE OR REPLACE FUNCTION join_quiniela(codigo_ingresado text)
RETURNS json AS $$
DECLARE
  v_quiniela_id uuid;
  v_limite int;
  v_actual int;
  v_usuario_id uuid;
BEGIN
  v_usuario_id := auth.uid();
  IF v_usuario_id IS NULL THEN RETURN json_build_object('success', false, 'mensaje', 'Usuario no autenticado.'); END IF;
  SELECT id, limite_usuarios INTO v_quiniela_id, v_limite FROM public.quinielas WHERE codigo_acceso = codigo_ingresado;
  IF NOT FOUND THEN RETURN json_build_object('success', false, 'mensaje', 'Código no existe.'); END IF;
  IF EXISTS (SELECT 1 FROM public.quiniela_usuarios WHERE quiniela_id = v_quiniela_id AND usuario_id = v_usuario_id) THEN RETURN json_build_object('success', false, 'mensaje', 'Ya participas.'); END IF;
  SELECT count(*) INTO v_actual FROM public.quiniela_usuarios WHERE quiniela_id = v_quiniela_id;
  IF v_actual >= v_limite THEN RETURN json_build_object('success', false, 'mensaje', 'Quiniela llena.'); END IF;
  INSERT INTO public.quiniela_usuarios (quiniela_id, usuario_id, puntos_totales) VALUES (v_quiniela_id, v_usuario_id, 0);
  RETURN json_build_object('success', true, 'quiniela_id', v_quiniela_id, 'mensaje', '¡Te has unido con éxito!');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION crear_quiniela(p_nombre text, p_torneo_id uuid, p_limite int)
RETURNS json AS $$
DECLARE
  v_codigo_nuevo text;
  v_creador_id uuid;
  v_quiniela_id uuid;
BEGIN
  v_creador_id := auth.uid();
  IF v_creador_id IS NULL THEN RETURN json_build_object('success', false, 'mensaje', 'No autenticado.'); END IF;
  LOOP
    v_codigo_nuevo := upper(substring(md5(random()::text) from 1 for 5));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.quinielas WHERE codigo_acceso = v_codigo_nuevo);
  END LOOP;
  INSERT INTO public.quinielas (torneo_id, creador_id, nombre, codigo_acceso, limite_usuarios) VALUES (p_torneo_id, v_creador_id, p_nombre, v_codigo_nuevo, p_limite) RETURNING id INTO v_quiniela_id;
  INSERT INTO public.quiniela_usuarios (quiniela_id, usuario_id, puntos_totales) VALUES (v_quiniela_id, v_creador_id, 0);
  RETURN json_build_object('success', true, 'codigo_generado', v_codigo_nuevo, 'mensaje', 'Quiniela creada.');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION calcular_puntos_partido()
RETURNS TRIGGER AS $$
DECLARE
  r_pronostico RECORD;
  v_puntos INT;
  v_diff_real INT;
  v_diff_pred INT;
BEGIN
  IF NEW.estado_id = 3 AND OLD.estado_id != 3 AND NEW.goles_local IS NOT NULL AND NEW.goles_visitante IS NOT NULL THEN
    v_diff_real := NEW.goles_local - NEW.goles_visitante;
    FOR r_pronostico IN SELECT * FROM public.pronosticos WHERE partido_id = NEW.id LOOP
      v_puntos := 0;
      v_diff_pred := r_pronostico.pred_goles_local - r_pronostico.pred_goles_visitante;
      IF r_pronostico.pred_goles_local = NEW.goles_local AND r_pronostico.pred_goles_visitante = NEW.goles_visitante THEN
        v_puntos := 5;
      ELSIF sign(v_diff_pred) = sign(v_diff_real) THEN
        v_puntos := 3;
        IF v_diff_pred = v_diff_real THEN v_puntos := v_puntos + 1; END IF;
      END IF;
      IF v_puntos > 0 THEN
        UPDATE public.pronosticos SET puntos_obtenidos = v_puntos WHERE id = r_pronostico.id;
        UPDATE public.quiniela_usuarios SET puntos_totales = puntos_totales + v_puntos WHERE quiniela_id = r_pronostico.quiniela_id AND usuario_id = r_pronostico.usuario_id;
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_cierre_partido ON public.partidos;
CREATE TRIGGER trigger_cierre_partido AFTER UPDATE ON public.partidos FOR EACH ROW EXECUTE FUNCTION calcular_puntos_partido();


