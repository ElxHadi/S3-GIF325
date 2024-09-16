--
-- PostgreSQL database cluster dump
--

-- Started on 2024-09-16 02:03:03 EDT

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;

--
-- User Configurations
--








--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)
-- Dumped by pg_dump version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)

-- Started on 2024-09-16 02:03:03 EDT

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

-- Completed on 2024-09-16 02:03:03 EDT

--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)
-- Dumped by pg_dump version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)

-- Started on 2024-09-16 02:03:03 EDT

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16404)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(50),
    email character varying(50)
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16403)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 3436 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 3283 (class 2604 OID 16407)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3430 (class 0 OID 16404)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email) FROM stdin;
1	test	test@test.com
2	test2	test2@test2.com
\.


--
-- TOC entry 3437 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- TOC entry 3285 (class 2606 OID 16409)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


-- Completed on 2024-09-16 02:03:03 EDT

--
-- PostgreSQL database dump complete
--

--
-- Database "reservation_db" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)
-- Dumped by pg_dump version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)

-- Started on 2024-09-16 02:03:03 EDT

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
-- TOC entry 3553 (class 1262 OID 17192)
-- Name: reservation_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE reservation_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE reservation_db OWNER TO postgres;

\connect reservation_db

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
-- TOC entry 234 (class 1255 OID 17458)
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
-- TOC entry 241 (class 1255 OID 17459)
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
-- TOC entry 243 (class 1255 OID 17460)
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
-- TOC entry 244 (class 1255 OID 17461)
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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 227 (class 1259 OID 17378)
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
-- TOC entry 226 (class 1259 OID 17372)
-- Name: caracteristique; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caracteristique (
    id_caracteristique integer NOT NULL,
    nom_caracteristique character varying(255)
);


ALTER TABLE public.caracteristique OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 17371)
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
-- TOC entry 3554 (class 0 OID 0)
-- Dependencies: 225
-- Name: caracteristique_id_caracteristique_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.caracteristique_id_caracteristique_seq OWNED BY public.caracteristique.id_caracteristique;


--
-- TOC entry 216 (class 1259 OID 17201)
-- Name: categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorie (
    id_categorie integer NOT NULL,
    nom_categorie character varying(255)
);


ALTER TABLE public.categorie OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 17200)
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
-- TOC entry 3555 (class 0 OID 0)
-- Dependencies: 215
-- Name: categorie_id_categorie_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categorie_id_categorie_seq OWNED BY public.categorie.id_categorie;


--
-- TOC entry 224 (class 1259 OID 17359)
-- Name: cubicule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cubicule (
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    numero_cubicule smallint NOT NULL
);


ALTER TABLE public.cubicule OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 17208)
-- Name: departement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departement (
    id_departement integer NOT NULL,
    nom_departement character varying(255)
);


ALTER TABLE public.departement OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 17207)
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
-- TOC entry 3556 (class 0 OID 0)
-- Dependencies: 217
-- Name: departement_id_departement_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departement_id_departement_seq OWNED BY public.departement.id_departement;


--
-- TOC entry 221 (class 1259 OID 17221)
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
-- TOC entry 222 (class 1259 OID 17231)
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
-- TOC entry 223 (class 1259 OID 17304)
-- Name: posseder; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posseder (
    cip character varying(8) NOT NULL,
    id_statut integer NOT NULL
);


ALTER TABLE public.posseder OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 17406)
-- Name: reserver; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserver (
    cip character varying(8) NOT NULL,
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    date_debut timestamp without time zone NOT NULL,
    date_fin timestamp without time zone NOT NULL,
    description character varying(255)
);


ALTER TABLE public.reserver OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 17215)
-- Name: statut; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statut (
    id_statut integer NOT NULL,
    nom_statut character varying(255)
);


ALTER TABLE public.statut OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 17424)
-- Name: statut_categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statut_categorie (
    id_categorie integer NOT NULL,
    id_statut integer NOT NULL
);


ALTER TABLE public.statut_categorie OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 17214)
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
-- TOC entry 3557 (class 0 OID 0)
-- Dependencies: 219
-- Name: statut_id_statut_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.statut_id_statut_seq OWNED BY public.statut.id_statut;


--
-- TOC entry 3333 (class 2604 OID 17375)
-- Name: caracteristique id_caracteristique; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caracteristique ALTER COLUMN id_caracteristique SET DEFAULT nextval('public.caracteristique_id_caracteristique_seq'::regclass);


--
-- TOC entry 3330 (class 2604 OID 17204)
-- Name: categorie id_categorie; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie ALTER COLUMN id_categorie SET DEFAULT nextval('public.categorie_id_categorie_seq'::regclass);


--
-- TOC entry 3331 (class 2604 OID 17211)
-- Name: departement id_departement; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departement ALTER COLUMN id_departement SET DEFAULT nextval('public.departement_id_departement_seq'::regclass);


--
-- TOC entry 3332 (class 2604 OID 17218)
-- Name: statut id_statut; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut ALTER COLUMN id_statut SET DEFAULT nextval('public.statut_id_statut_seq'::regclass);


--
-- TOC entry 3545 (class 0 OID 17378)
-- Dependencies: 227
-- Data for Name: attribuer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attribuer (pavillon, numero, id_caracteristique, effectif) FROM stdin;
D7	3317	2	78
D7	3318	10	2
\.


--
-- TOC entry 3544 (class 0 OID 17372)
-- Dependencies: 226
-- Data for Name: caracteristique; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caracteristique (id_caracteristique, nom_caracteristique) FROM stdin;
1	Connexion à Internet
2	Tables fixes en U
3	Chaises mobiles
4	Monoplaces
5	Tables mobiles
6	Chaises fixes
7	Tables hautes
8	Chaises hautes
9	Tables fixes
10	Écran
11	Rétroprojecteur
12	Gradins
13	Fenêtres
14	Piano
15	Autres instruments
16	Système de son
17	Salle réservée (spéciale)
18	Ordinateurs PC
19	Ordinateurs SUN pour génie électrique
20	Ordinateurs (oscillomètre et multimètre)
21	Ordinateurs modélisation des structures
22	Équipement pour microélectronique
23	Équipement pour génie électrique
24	Équipement pour mécatronique
25	Équipement pour la caractérisation
26	Équipement pour la thermodynamique
27	Équipement pour génie civil
28	Équipement métrologie
29	Équipement de machinerie
30	Équipement de géologie
31	Télévision
32	VHS
33	Hauts parleurs
34	Micro
35	Magnétophone à cassette
36	Amplificateur audio
37	Local barré
38	Prise réseau
\.


--
-- TOC entry 3534 (class 0 OID 17201)
-- Dependencies: 216
-- Data for Name: categorie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorie (id_categorie, nom_categorie) FROM stdin;
1	Salle de classe générale
2	Salle de classe spécialisée
3	Salle de séminaire
4	Cubicules
5	Laboratoire informatique
6	Laboratoire d’enseignement spécialisé
7	Atelier
8	Salle à dessin
9	Atelier (civil)
10	Salle de musique
11	Atelier sur 2 étages, conjoint avec autre local
12	Salle de conférence
13	Salle de réunion
14	Salle d’entrevue et de tests
15	Salle de lecture ou de consultation
16	Auditorium
17	Salle de concert
18	Salle d’audience
19	Salon du personnel
20	Studio d’enregistrement
21	Hall d’entrée
\.


--
-- TOC entry 3542 (class 0 OID 17359)
-- Dependencies: 224
-- Data for Name: cubicule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cubicule (pavillon, numero, numero_cubicule) FROM stdin;
C1	4023	1
C1	4023	2
C1	4023	3
\.


--
-- TOC entry 3536 (class 0 OID 17208)
-- Dependencies: 218
-- Data for Name: departement; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departement (id_departement, nom_departement) FROM stdin;
1	Génie électrique et Génie informatique
2	Génie mécanique
3	Génie chimique et biotechnologie
4	Génie civil et du bâtiment
\.


--
-- TOC entry 3539 (class 0 OID 17221)
-- Dependencies: 221
-- Data for Name: local; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.local (pavillon, numero, capacite, id_categorie) FROM stdin;
D7	3318	70	12
C2	1356	55	3
C1	4023	13	4
D8	1001	7	7
C1	4005	5	21
D7	3317	15	1
\.


--
-- TOC entry 3540 (class 0 OID 17231)
-- Dependencies: 222
-- Data for Name: membre; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.membre (cip, nom, prenom, email, id_departement) FROM stdin;
benm2043	Bendjeddou	Mohamed	benm2043@usherbrooke.ca	1
msha2019	Bendjeddou	Masha	msha2019@usherbrooke.ca	1
tarks781	Johnny	Washington	tarks781@usherbrooke.ca	4
lpedz807	Rosie	Hamilton	lpedz807@usherbrooke.ca	2
virgx325	Lee	Aguilar	virgx325@usherbrooke.ca	3
\.


--
-- TOC entry 3541 (class 0 OID 17304)
-- Dependencies: 223
-- Data for Name: posseder; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posseder (cip, id_statut) FROM stdin;
msha2019	4
tarks781	3
lpedz807	1
virgx325	2
virgx325	3
benm2043	1
\.


--
-- TOC entry 3546 (class 0 OID 17406)
-- Dependencies: 228
-- Data for Name: reserver; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reserver (cip, pavillon, numero, date_debut, date_fin, description) FROM stdin;
msha2019	C1	4005	2024-10-16 08:30:00	2024-10-16 11:45:00	I love cats !
\.


--
-- TOC entry 3538 (class 0 OID 17215)
-- Dependencies: 220
-- Data for Name: statut; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.statut (id_statut, nom_statut) FROM stdin;
1	Étudiant
2	Enseignant
3	Personnel de soutien
4	Administrateur
\.


--
-- TOC entry 3547 (class 0 OID 17424)
-- Dependencies: 229
-- Data for Name: statut_categorie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.statut_categorie (id_categorie, id_statut) FROM stdin;
1	1
2	1
3	1
4	1
5	1
6	1
7	1
8	1
10	1
11	1
15	1
1	2
2	2
3	2
5	2
6	2
9	2
12	2
13	2
16	2
17	2
20	2
4	3
5	3
8	3
13	3
14	3
19	3
21	3
13	4
14	4
18	4
19	4
20	4
21	4
\.


--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 225
-- Name: caracteristique_id_caracteristique_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caracteristique_id_caracteristique_seq', 38, true);


--
-- TOC entry 3559 (class 0 OID 0)
-- Dependencies: 215
-- Name: categorie_id_categorie_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categorie_id_categorie_seq', 21, true);


--
-- TOC entry 3560 (class 0 OID 0)
-- Dependencies: 217
-- Name: departement_id_departement_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departement_id_departement_seq', 4, true);


--
-- TOC entry 3561 (class 0 OID 0)
-- Dependencies: 219
-- Name: statut_id_statut_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.statut_id_statut_seq', 4, true);


--
-- TOC entry 3368 (class 2606 OID 17382)
-- Name: attribuer attribuer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pkey PRIMARY KEY (pavillon, numero, id_caracteristique);


--
-- TOC entry 3364 (class 2606 OID 17377)
-- Name: caracteristique caracteristique_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_pkey PRIMARY KEY (id_caracteristique);


--
-- TOC entry 3366 (class 2606 OID 17398)
-- Name: caracteristique caracteristique_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_unique UNIQUE (nom_caracteristique);


--
-- TOC entry 3335 (class 2606 OID 17206)
-- Name: categorie categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_pkey PRIMARY KEY (id_categorie);


--
-- TOC entry 3337 (class 2606 OID 17400)
-- Name: categorie categorie_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_unique UNIQUE (nom_categorie);


--
-- TOC entry 3361 (class 2606 OID 17363)
-- Name: cubicule cubicule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pkey PRIMARY KEY (pavillon, numero, numero_cubicule);


--
-- TOC entry 3339 (class 2606 OID 17213)
-- Name: departement departement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_pkey PRIMARY KEY (id_departement);


--
-- TOC entry 3341 (class 2606 OID 17396)
-- Name: departement departement_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_unique UNIQUE (nom_departement);


--
-- TOC entry 3347 (class 2606 OID 17225)
-- Name: local local_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_pkey PRIMARY KEY (pavillon, numero);


--
-- TOC entry 3351 (class 2606 OID 17239)
-- Name: membre membre_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_email_key UNIQUE (email);


--
-- TOC entry 3353 (class 2606 OID 17237)
-- Name: membre membre_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_pkey PRIMARY KEY (cip);


--
-- TOC entry 3355 (class 2606 OID 17423)
-- Name: membre membre_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_unique UNIQUE (email);


--
-- TOC entry 3359 (class 2606 OID 17308)
-- Name: posseder posseder_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_pkey PRIMARY KEY (cip, id_statut);


--
-- TOC entry 3375 (class 2606 OID 17410)
-- Name: reserver reserver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pkey PRIMARY KEY (cip, pavillon, numero, date_debut, date_fin);


--
-- TOC entry 3377 (class 2606 OID 17428)
-- Name: statut_categorie statut_categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_pkey PRIMARY KEY (id_categorie, id_statut);


--
-- TOC entry 3343 (class 2606 OID 17220)
-- Name: statut statut_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut
    ADD CONSTRAINT statut_pkey PRIMARY KEY (id_statut);


--
-- TOC entry 3369 (class 1259 OID 17472)
-- Name: idx_attribuer_id_caracteristique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attribuer_id_caracteristique ON public.attribuer USING btree (id_caracteristique);


--
-- TOC entry 3370 (class 1259 OID 17471)
-- Name: idx_attribuer_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attribuer_pavillon_numero ON public.attribuer USING btree (pavillon, numero);


--
-- TOC entry 3362 (class 1259 OID 17470)
-- Name: idx_cubicule_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cubicule_pavillon_numero ON public.cubicule USING btree (pavillon, numero);


--
-- TOC entry 3344 (class 1259 OID 17463)
-- Name: idx_local_id_categorie; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_local_id_categorie ON public.local USING btree (id_categorie);


--
-- TOC entry 3345 (class 1259 OID 17464)
-- Name: idx_local_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_local_pavillon_numero ON public.local USING btree (pavillon, numero);


--
-- TOC entry 3348 (class 1259 OID 17466)
-- Name: idx_membre_cip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_membre_cip ON public.membre USING btree (cip);


--
-- TOC entry 3349 (class 1259 OID 17465)
-- Name: idx_membre_id_departement; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_membre_id_departement ON public.membre USING btree (id_departement);


--
-- TOC entry 3356 (class 1259 OID 17473)
-- Name: idx_posseder_cip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_posseder_cip ON public.posseder USING btree (cip);


--
-- TOC entry 3357 (class 1259 OID 17474)
-- Name: idx_posseder_id_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_posseder_id_statut ON public.posseder USING btree (id_statut);


--
-- TOC entry 3371 (class 1259 OID 17467)
-- Name: idx_reserver_cip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserver_cip ON public.reserver USING btree (cip);


--
-- TOC entry 3372 (class 1259 OID 17469)
-- Name: idx_reserver_date_range; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserver_date_range ON public.reserver USING btree (date_debut, date_fin);


--
-- TOC entry 3373 (class 1259 OID 17468)
-- Name: idx_reserver_pavillon_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserver_pavillon_numero ON public.reserver USING btree (pavillon, numero);


--
-- TOC entry 3389 (class 2620 OID 17462)
-- Name: reserver trg_handle_reservation; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_handle_reservation BEFORE INSERT OR UPDATE ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.handle_reservation();


--
-- TOC entry 3383 (class 2606 OID 17383)
-- Name: attribuer attribuer_id_caracteristique_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_id_caracteristique_fkey FOREIGN KEY (id_caracteristique) REFERENCES public.caracteristique(id_caracteristique);


--
-- TOC entry 3384 (class 2606 OID 17388)
-- Name: attribuer attribuer_pavillon_numero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);


--
-- TOC entry 3382 (class 2606 OID 17364)
-- Name: cubicule cubicule_pavillon_numero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);


--
-- TOC entry 3378 (class 2606 OID 17226)
-- Name: local local_id_categorie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);


--
-- TOC entry 3379 (class 2606 OID 17240)
-- Name: membre membre_id_departement_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_id_departement_fkey FOREIGN KEY (id_departement) REFERENCES public.departement(id_departement);


--
-- TOC entry 3380 (class 2606 OID 17314)
-- Name: posseder posseder_cip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);


--
-- TOC entry 3381 (class 2606 OID 17309)
-- Name: posseder posseder_id_statut_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);


--
-- TOC entry 3385 (class 2606 OID 17411)
-- Name: reserver reserver_cip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);


--
-- TOC entry 3386 (class 2606 OID 17416)
-- Name: reserver reserver_pavillon_numero_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);


--
-- TOC entry 3387 (class 2606 OID 17429)
-- Name: statut_categorie statut_categorie_id_categorie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);


--
-- TOC entry 3388 (class 2606 OID 17434)
-- Name: statut_categorie statut_categorie_id_statut_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);


-- Completed on 2024-09-16 02:03:03 EDT

--
-- PostgreSQL database dump complete
--

-- Completed on 2024-09-16 02:03:03 EDT

--
-- PostgreSQL database cluster dump complete
--

