--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)
-- Dumped by pg_dump version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: check_availability(character varying, character varying, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_availability(local_pavillon character varying, local_numero character varying, desired_date_debut timestamp without time zone, desired_date_fin timestamp without time zone) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    overlap_exists BOOLEAN;
BEGIN
    -- Check if there is any reservation that overlaps with the desired period
    SELECT EXISTS (
        SELECT 1
        FROM RESERVER
        WHERE pavillon = local_pavillon
          AND numero = local_numero
          AND date_debut < desired_date_fin
          AND date_fin > desired_date_debut
    ) INTO overlap_exists;

    RETURN NOT overlap_exists;  -- Return true if no overlap exists
END;
$$;


ALTER FUNCTION public.check_availability(local_pavillon character varying, local_numero character varying, desired_date_debut timestamp without time zone, desired_date_fin timestamp without time zone) OWNER TO postgres;

--
-- Name: check_dates(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_dates(reservation_start timestamp without time zone, reservation_end timestamp without time zone) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if the end date is after the start date and if the duration is less than 24 hours
    RETURN reservation_end > reservation_start AND (reservation_end - reservation_start) < INTERVAL '24 hours';
END;
$$;


ALTER FUNCTION public.check_dates(reservation_start timestamp without time zone, reservation_end timestamp without time zone) OWNER TO postgres;

--
-- Name: check_permission(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_permission(user_cip character varying, local_pavillon character varying, local_numero character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_statut_id SMALLINT;
    local_categorie_id SMALLINT;
BEGIN
    -- Get the status of the user
    SELECT id_statut INTO user_statut_id
    FROM POSSEDER
    WHERE cip = user_cip;

    -- Get the category of the local
    SELECT id_categorie INTO local_categorie_id
    FROM LOCAL
    WHERE pavillon = local_pavillon AND numero = local_numero;

    -- Check if the user has permission for the category of the local
    RETURN EXISTS (
        SELECT 1
        FROM STATUT_CATEGORIE
        WHERE id_statut = user_statut_id
        AND id_categorie = local_categorie_id
    );
END;
$$;


ALTER FUNCTION public.check_permission(user_cip character varying, local_pavillon character varying, local_numero character varying) OWNER TO postgres;

--
-- Name: generate_time_slots(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_time_slots(date_debut timestamp without time zone, date_fin timestamp without time zone) RETURNS TABLE(time_slot timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT generate_series(date_debut, date_fin, '15 minutes'::interval) AS time_slot;
END;
$$;


ALTER FUNCTION public.generate_time_slots(date_debut timestamp without time zone, date_fin timestamp without time zone) OWNER TO postgres;

--
-- Name: get_local_data(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_local_data(id_categorie integer) RETURNS TABLE(pavillon character varying, numero character varying)
    LANGUAGE plpgsql
    AS $$
#variable_conflict use_variable
BEGIN
    RETURN QUERY
    SELECT l.pavillon, l.numero
    FROM local l
    WHERE l.id_categorie = id_categorie;
END;
$$;


ALTER FUNCTION public.get_local_data(id_categorie integer) OWNER TO postgres;

--
-- Name: get_reservation_data(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_reservation_data(start_timestamp timestamp without time zone, end_timestamp timestamp without time zone) RETURNS TABLE(pavillon character varying, numero character varying, date_debut timestamp without time zone, date_fin timestamp without time zone, description character varying)
    LANGUAGE plpgsql
    AS $$
#variable_conflict use_variable
BEGIN
    RETURN QUERY
    SELECT r.pavillon, r.numero, r.date_debut, r.date_fin, r.description
    FROM reserver r
    WHERE r.date_debut < end_timestamp
    AND r.date_fin > start_timestamp;
END;
$$;


ALTER FUNCTION public.get_reservation_data(start_timestamp timestamp without time zone, end_timestamp timestamp without time zone) OWNER TO postgres;

--
-- Name: handle_reservation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_reservation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    is_permissible BOOLEAN;
    is_available BOOLEAN;
    dates_check BOOLEAN;
BEGIN
    -- Check if the user has permission
    is_permissible := public.check_permission(NEW.cip, NEW.pavillon, NEW.numero);
    IF NOT is_permissible THEN
        RAISE EXCEPTION 'Permission denied: The user does not have permission to book this local';
    END IF;

    -- Check if the local is available
    is_available := public.check_availability(NEW.pavillon, NEW.numero, NEW.date_debut, NEW.date_fin);
    IF NOT is_available THEN
        RAISE EXCEPTION 'Local is not available: The local is already booked during the proposed dates.';
    END IF;

    -- Check if the dates are valid
    dates_check := public.check_dates(NEW.date_debut, NEW.date_fin);
    IF NOT dates_check THEN
        RAISE EXCEPTION 'Invalid reservation dates: Reservation must be less than 24 hours.';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_reservation() OWNER TO postgres;

--
-- Name: log_delete_reserver(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_delete_reserver() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO reservation_log (
        action_type, id_reservation, performed_by,action_date
    )
    VALUES (
        'DELETE', OLD.id_reservation, OLD.cip,DATE_TRUNC('second', NOW())
    );
    RETURN OLD;
END;
$$;


ALTER FUNCTION public.log_delete_reserver() OWNER TO postgres;

--
-- Name: log_insert_reserver(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_insert_reserver() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO reservation_log (
        action_type, id_reservation, performed_by, action_date 
    )
    VALUES (
        'INSERT', NEW.id_reservation, NEW.cip, DATE_TRUNC('second', NOW())
	);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_insert_reserver() OWNER TO postgres;

--
-- Name: log_update_reserver(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_update_reserver() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO reservation_log (
        action_type, id_reservation, performed_by,action_date
    )
    VALUES (
        'UPDATE', NEW.id_reservation, NEW.cip, DATE_TRUNC('second', NOW())
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_update_reserver() OWNER TO postgres;

--
-- Name: tableau(timestamp without time zone, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tableau(q_date_debut timestamp without time zone, q_date_fin timestamp without time zone, q_id_categorie integer) RETURNS TABLE(pavillon character varying, numero character varying, time_slot timestamp without time zone, description character varying)
    LANGUAGE plpgsql
    AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    WITH
    time_slots AS (
        SELECT time_slot
        FROM generate_time_slots(q_date_debut, q_date_fin)
    ),
    local_data AS (
        SELECT pavillon, numero
        FROM get_local_data(q_id_categorie)
    ),
    reservation_data AS (
        SELECT pavillon, numero, date_debut, date_fin, description
        FROM get_reservation_data(q_date_debut, q_date_fin)
    )
    SELECT
        l.pavillon,
        l.numero,
        ts.time_slot,
        COALESCE(r.description, NULL) AS description
    FROM time_slots ts
    CROSS JOIN local_data l
    LEFT JOIN reservation_data r
        ON l.pavillon = r.pavillon
        AND l.numero = r.numero
        AND ts.time_slot >= r.date_debut
        AND ts.time_slot < r.date_fin
    ORDER BY l.pavillon, l.numero, ts.time_slot;
END;
$$;


ALTER FUNCTION public.tableau(q_date_debut timestamp without time zone, q_date_fin timestamp without time zone, q_id_categorie integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: attribuer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attribuer (
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    id_caracteristique smallint NOT NULL,
    effectif smallint
);


ALTER TABLE public.attribuer OWNER TO postgres;

--
-- Name: caracteristique; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caracteristique (
    id_caracteristique integer NOT NULL,
    nom_caracteristique character varying(255)
);


ALTER TABLE public.caracteristique OWNER TO postgres;

--
-- Name: caracteristique_id_caracteristique_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.caracteristique_id_caracteristique_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.caracteristique_id_caracteristique_seq OWNER TO postgres;

--
-- Name: caracteristique_id_caracteristique_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.caracteristique_id_caracteristique_seq OWNED BY public.caracteristique.id_caracteristique;


--
-- Name: categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorie (
    id_categorie integer NOT NULL,
    nom_categorie character varying(255)
);


ALTER TABLE public.categorie OWNER TO postgres;

--
-- Name: categorie_id_categorie_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categorie_id_categorie_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categorie_id_categorie_seq OWNER TO postgres;

--
-- Name: categorie_id_categorie_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categorie_id_categorie_seq OWNED BY public.categorie.id_categorie;


--
-- Name: cubicule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cubicule (
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    numero_cubicule smallint NOT NULL
);


ALTER TABLE public.cubicule OWNER TO postgres;

--
-- Name: departement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departement (
    id_departement integer NOT NULL,
    nom_departement character varying(255)
);


ALTER TABLE public.departement OWNER TO postgres;

--
-- Name: departement_id_departement_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.departement_id_departement_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.departement_id_departement_seq OWNER TO postgres;

--
-- Name: departement_id_departement_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departement_id_departement_seq OWNED BY public.departement.id_departement;


--
-- Name: local; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.local (
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    capacite smallint,
    id_categorie smallint NOT NULL
);


ALTER TABLE public.local OWNER TO postgres;

--
-- Name: membre; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.membre (
    cip character varying(8) NOT NULL,
    nom character varying(255) NOT NULL,
    prenom character varying(255),
    email character varying(255) NOT NULL,
    id_departement smallint NOT NULL
);


ALTER TABLE public.membre OWNER TO postgres;

--
-- Name: posseder; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posseder (
    cip character varying(8) NOT NULL,
    id_statut integer NOT NULL
);


ALTER TABLE public.posseder OWNER TO postgres;

--
-- Name: reservation_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservation_log (
    log_id integer NOT NULL,
    action_type character varying(10),
    id_reservation smallint,
    performed_by character varying(8),
    action_date timestamp without time zone DEFAULT date_trunc('second'::text, now())
);


ALTER TABLE public.reservation_log OWNER TO postgres;

--
-- Name: reservation_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reservation_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reservation_log_log_id_seq OWNER TO postgres;

--
-- Name: reservation_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reservation_log_log_id_seq OWNED BY public.reservation_log.log_id;


--
-- Name: reserver; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserver (
    id_reservation integer NOT NULL,
    cip character varying(8) NOT NULL,
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    date_debut timestamp without time zone NOT NULL,
    date_fin timestamp without time zone NOT NULL,
    description character varying(255)
);


ALTER TABLE public.reserver OWNER TO postgres;

--
-- Name: reserver_id_reservation_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reserver_id_reservation_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reserver_id_reservation_seq OWNER TO postgres;

--
-- Name: reserver_id_reservation_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reserver_id_reservation_seq OWNED BY public.reserver.id_reservation;


--
-- Name: statut; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statut (
    id_statut integer NOT NULL,
    nom_statut character varying(255)
);


ALTER TABLE public.statut OWNER TO postgres;

--
-- Name: statut_categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statut_categorie (
    id_categorie integer NOT NULL,
    id_statut integer NOT NULL
);


ALTER TABLE public.statut_categorie OWNER TO postgres;

--
-- Name: statut_id_statut_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.statut_id_statut_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.statut_id_statut_seq OWNER TO postgres;

--
-- Name: statut_id_statut_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.statut_id_statut_seq OWNED BY public.statut.id_statut;


--
-- Name: caracteristique id_caracteristique; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caracteristique ALTER COLUMN id_caracteristique SET DEFAULT nextval('public.caracteristique_id_caracteristique_seq'::regclass);


--
-- Name: categorie id_categorie; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie ALTER COLUMN id_categorie SET DEFAULT nextval('public.categorie_id_categorie_seq'::regclass);


--
-- Name: departement id_departement; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departement ALTER COLUMN id_departement SET DEFAULT nextval('public.departement_id_departement_seq'::regclass);


--
-- Name: reservation_log log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_log ALTER COLUMN log_id SET DEFAULT nextval('public.reservation_log_log_id_seq'::regclass);


--
-- Name: reserver id_reservation; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserver ALTER COLUMN id_reservation SET DEFAULT nextval('public.reserver_id_reservation_seq'::regclass);


--
-- Name: statut id_statut; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut ALTER COLUMN id_statut SET DEFAULT nextval('public.statut_id_statut_seq'::regclass);


--
-- Name: attribuer attribuer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pkey PRIMARY KEY (pavillon, numero, id_caracteristique);


--
-- Name: caracteristique caracteristique_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_pkey PRIMARY KEY (id_caracteristique);


--
-- Name: caracteristique caracteristique_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_unique UNIQUE (nom_caracteristique);


--
-- Name: categorie categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_pkey PRIMARY KEY (id_categorie);


--
-- Name: categorie categorie_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_unique UNIQUE (nom_categorie);


--
-- Name: cubicule cubicule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pkey PRIMARY KEY (pavillon, numero, numero_cubicule);


--
-- Name: departement departement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_pkey PRIMARY KEY (id_departement);


--
-- Name: departement departement_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_unique UNIQUE (nom_departement);


--
-- Name: local local_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_pkey PRIMARY KEY (pavillon, numero);


--
-- Name: membre membre_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_email_key UNIQUE (email);


--
-- Name: membre membre_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_pkey PRIMARY KEY (cip);


--
-- Name: membre membre_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_unique UNIQUE (email);


--
-- Name: posseder posseder_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_pkey PRIMARY KEY (cip, id_statut);


--
-- Name: reservation_log reservation_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_log
    ADD CONSTRAINT reservation_log_pkey PRIMARY KEY (log_id);


--
-- Name: reserver reserver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pkey PRIMARY KEY (id_reservation);


--
-- Name: statut_categorie statut_categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_pkey PRIMARY KEY (id_categorie, id_statut);


--
-- Name: statut statut_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut
    ADD CONSTRAINT statut_pkey PRIMARY KEY (id_statut);


--
-- Name: idx_attribuer_id_caracteristique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attribuer_id_caracteristique ON public.attribuer USING btree (id_caracteristique);


--
-- Name: idx_attribuer_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attribuer_pavillon_numero ON public.attribuer USING btree (pavillon, numero);


--
-- Name: idx_caracteristique_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caracteristique_id ON public.caracteristique USING btree (id_caracteristique);


--
-- Name: idx_categorie_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categorie_id ON public.categorie USING btree (id_categorie);


--
-- Name: idx_cubicule_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cubicule_pavillon_numero ON public.cubicule USING btree (pavillon, numero);


--
-- Name: idx_departement_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_departement_id ON public.departement USING btree (id_departement);


--
-- Name: idx_local_id_categorie; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_local_id_categorie ON public.local USING btree (id_categorie);


--
-- Name: idx_local_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_local_pavillon_numero ON public.local USING btree (pavillon, numero);


--
-- Name: idx_membre_cip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_membre_cip ON public.membre USING btree (cip);


--
-- Name: idx_membre_id_departement; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_membre_id_departement ON public.membre USING btree (id_departement);


--
-- Name: idx_posseder_cip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_posseder_cip ON public.posseder USING btree (cip);


--
-- Name: idx_posseder_id_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_posseder_id_statut ON public.posseder USING btree (id_statut);


--
-- Name: idx_reserver_cip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserver_cip ON public.reserver USING btree (cip);


--
-- Name: idx_reserver_date_debut_fin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserver_date_debut_fin ON public.reserver USING btree (date_debut, date_fin);


--
-- Name: idx_reserver_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserver_pavillon_numero ON public.reserver USING btree (pavillon, numero);


--
-- Name: idx_statut_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_statut_id ON public.statut USING btree (id_statut);


--
-- Name: reserver trg_handle_reservation; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_handle_reservation BEFORE INSERT ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.handle_reservation();


--
-- Name: reserver trg_log_delete_reserver; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_delete_reserver AFTER DELETE ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.log_delete_reserver();


--
-- Name: reserver trg_log_insert_reserver; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_insert_reserver AFTER INSERT ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.log_insert_reserver();


--
-- Name: reserver trg_log_update_reserver; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_update_reserver AFTER UPDATE ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.log_update_reserver();


--
-- Name: attribuer attribuer_id_caracteristique_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_id_caracteristique_fkey FOREIGN KEY (id_caracteristique) REFERENCES public.caracteristique(id_caracteristique);


--
-- Name: attribuer attribuer_pavillon_numero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);


--
-- Name: cubicule cubicule_pavillon_numero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);


--
-- Name: local local_id_categorie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);


--
-- Name: membre membre_id_departement_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_id_departement_fkey FOREIGN KEY (id_departement) REFERENCES public.departement(id_departement);


--
-- Name: posseder posseder_cip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);


--
-- Name: posseder posseder_id_statut_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);


--
-- Name: reserver reserver_cip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);


--
-- Name: reserver reserver_pavillon_numero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);


--
-- Name: statut_categorie statut_categorie_id_categorie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);


--
-- Name: statut_categorie statut_categorie_id_statut_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);


--
-- PostgreSQL database dump complete
--

