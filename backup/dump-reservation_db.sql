PGDMP       1                |           reservation_db #   16.4 (Ubuntu 16.4-0ubuntu0.24.04.2) #   16.4 (Ubuntu 16.4-0ubuntu0.24.04.2) q    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    17192    reservation_db    DATABASE     z   CREATE DATABASE reservation_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';
    DROP DATABASE reservation_db;
                postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                pg_database_owner    false            �           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                   pg_database_owner    false    5            �            1255    17458 r   check_availability(character varying, character varying, timestamp without time zone, timestamp without time zone)    FUNCTION     �  CREATE FUNCTION public.check_availability(local_pavillon character varying, local_numero character varying, desired_date_debut timestamp without time zone, desired_date_fin timestamp without time zone) RETURNS boolean
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
 �   DROP FUNCTION public.check_availability(local_pavillon character varying, local_numero character varying, desired_date_debut timestamp without time zone, desired_date_fin timestamp without time zone);
       public          postgres    false    5            �            1255    17459 E   check_dates(timestamp without time zone, timestamp without time zone)    FUNCTION     �  CREATE FUNCTION public.check_dates(reservation_start timestamp without time zone, reservation_end timestamp without time zone) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if the end date is after the start date and if the duration is less than 24 hours
    RETURN reservation_end > reservation_start AND (reservation_end - reservation_start) < INTERVAL '24 hours';
END;
$$;
 ~   DROP FUNCTION public.check_dates(reservation_start timestamp without time zone, reservation_end timestamp without time zone);
       public          postgres    false    5            �            1255    17460 I   check_permission(character varying, character varying, character varying)    FUNCTION       CREATE FUNCTION public.check_permission(user_cip character varying, local_pavillon character varying, local_numero character varying) RETURNS boolean
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
 �   DROP FUNCTION public.check_permission(user_cip character varying, local_pavillon character varying, local_numero character varying);
       public          postgres    false    5            �            1255    25695 M   generate_time_slots(timestamp without time zone, timestamp without time zone)    FUNCTION     D  CREATE FUNCTION public.generate_time_slots(date_debut timestamp without time zone, date_fin timestamp without time zone) RETURNS TABLE(time_slot timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT generate_series(date_debut, date_fin, '15 minutes'::interval) AS time_slot;
END;
$$;
 x   DROP FUNCTION public.generate_time_slots(date_debut timestamp without time zone, date_fin timestamp without time zone);
       public          postgres    false    5            �            1255    25700    get_local_data(integer)    FUNCTION     9  CREATE FUNCTION public.get_local_data(id_categorie integer) RETURNS TABLE(pavillon character varying, numero character varying)
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
 ;   DROP FUNCTION public.get_local_data(id_categorie integer);
       public          postgres    false    5            �            1255    25703 N   get_reservation_data(timestamp without time zone, timestamp without time zone)    FUNCTION     >  CREATE FUNCTION public.get_reservation_data(start_timestamp timestamp without time zone, end_timestamp timestamp without time zone) RETURNS TABLE(pavillon character varying, numero character varying, date_debut timestamp without time zone, date_fin timestamp without time zone, description character varying)
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
 �   DROP FUNCTION public.get_reservation_data(start_timestamp timestamp without time zone, end_timestamp timestamp without time zone);
       public          postgres    false    5            �            1255    17461    handle_reservation()    FUNCTION     �  CREATE FUNCTION public.handle_reservation() RETURNS trigger
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
 +   DROP FUNCTION public.handle_reservation();
       public          postgres    false    5            �            1255    25765    log_delete_reserver()    FUNCTION     ?  CREATE FUNCTION public.log_delete_reserver() RETURNS trigger
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
 ,   DROP FUNCTION public.log_delete_reserver();
       public          postgres    false    5            �            1255    25763    log_insert_reserver()    FUNCTION     ?  CREATE FUNCTION public.log_insert_reserver() RETURNS trigger
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
 ,   DROP FUNCTION public.log_insert_reserver();
       public          postgres    false    5            �            1255    25764    log_update_reserver()    FUNCTION     @  CREATE FUNCTION public.log_update_reserver() RETURNS trigger
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
 ,   DROP FUNCTION public.log_update_reserver();
       public          postgres    false    5            �            1255    25710 J   tableau(timestamp without time zone, timestamp without time zone, integer)    FUNCTION     �  CREATE FUNCTION public.tableau(q_date_debut timestamp without time zone, q_date_fin timestamp without time zone, q_id_categorie integer) RETURNS TABLE(pavillon character varying, numero character varying, time_slot timestamp without time zone, description character varying)
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
 �   DROP FUNCTION public.tableau(q_date_debut timestamp without time zone, q_date_fin timestamp without time zone, q_id_categorie integer);
       public          postgres    false    5            �            1259    17378 	   attribuer    TABLE     �   CREATE TABLE public.attribuer (
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    id_caracteristique smallint NOT NULL,
    effectif smallint
);
    DROP TABLE public.attribuer;
       public         heap    postgres    false    5            �            1259    17372    caracteristique    TABLE     �   CREATE TABLE public.caracteristique (
    id_caracteristique integer NOT NULL,
    nom_caracteristique character varying(255)
);
 #   DROP TABLE public.caracteristique;
       public         heap    postgres    false    5            �            1259    17371 &   caracteristique_id_caracteristique_seq    SEQUENCE     �   CREATE SEQUENCE public.caracteristique_id_caracteristique_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public.caracteristique_id_caracteristique_seq;
       public          postgres    false    226    5            �           0    0 &   caracteristique_id_caracteristique_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.caracteristique_id_caracteristique_seq OWNED BY public.caracteristique.id_caracteristique;
          public          postgres    false    225            �            1259    17201 	   categorie    TABLE     o   CREATE TABLE public.categorie (
    id_categorie integer NOT NULL,
    nom_categorie character varying(255)
);
    DROP TABLE public.categorie;
       public         heap    postgres    false    5            �            1259    17200    categorie_id_categorie_seq    SEQUENCE     �   CREATE SEQUENCE public.categorie_id_categorie_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.categorie_id_categorie_seq;
       public          postgres    false    216    5                        0    0    categorie_id_categorie_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.categorie_id_categorie_seq OWNED BY public.categorie.id_categorie;
          public          postgres    false    215            �            1259    17359    cubicule    TABLE     �   CREATE TABLE public.cubicule (
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    numero_cubicule smallint NOT NULL
);
    DROP TABLE public.cubicule;
       public         heap    postgres    false    5            �            1259    17208    departement    TABLE     u   CREATE TABLE public.departement (
    id_departement integer NOT NULL,
    nom_departement character varying(255)
);
    DROP TABLE public.departement;
       public         heap    postgres    false    5            �            1259    17207    departement_id_departement_seq    SEQUENCE     �   CREATE SEQUENCE public.departement_id_departement_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.departement_id_departement_seq;
       public          postgres    false    5    218                       0    0    departement_id_departement_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.departement_id_departement_seq OWNED BY public.departement.id_departement;
          public          postgres    false    217            �            1259    17221    local    TABLE     �   CREATE TABLE public.local (
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    capacite smallint,
    id_categorie smallint NOT NULL
);
    DROP TABLE public.local;
       public         heap    postgres    false    5            �            1259    17231    membre    TABLE     �   CREATE TABLE public.membre (
    cip character varying(8) NOT NULL,
    nom character varying(255) NOT NULL,
    prenom character varying(255),
    email character varying(255) NOT NULL,
    id_departement smallint NOT NULL
);
    DROP TABLE public.membre;
       public         heap    postgres    false    5            �            1259    17304    posseder    TABLE     h   CREATE TABLE public.posseder (
    cip character varying(8) NOT NULL,
    id_statut integer NOT NULL
);
    DROP TABLE public.posseder;
       public         heap    postgres    false    5            �            1259    25837    reservation_log    TABLE       CREATE TABLE public.reservation_log (
    log_id integer NOT NULL,
    action_type character varying(10),
    id_reservation smallint,
    performed_by character varying(8),
    action_date timestamp without time zone DEFAULT date_trunc('second'::text, now())
);
 #   DROP TABLE public.reservation_log;
       public         heap    postgres    false    5            �            1259    25836    reservation_log_log_id_seq    SEQUENCE     �   CREATE SEQUENCE public.reservation_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.reservation_log_log_id_seq;
       public          postgres    false    232    5                       0    0    reservation_log_log_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.reservation_log_log_id_seq OWNED BY public.reservation_log.log_id;
          public          postgres    false    231            �            1259    17477    reserver    TABLE     S  CREATE TABLE public.reserver (
    id_reservation integer NOT NULL,
    cip character varying(8) NOT NULL,
    pavillon character varying(2) NOT NULL,
    numero character varying(4) NOT NULL,
    date_debut timestamp without time zone NOT NULL,
    date_fin timestamp without time zone NOT NULL,
    description character varying(255)
);
    DROP TABLE public.reserver;
       public         heap    postgres    false    5            �            1259    17476    reserver_id_reservation_seq    SEQUENCE     �   CREATE SEQUENCE public.reserver_id_reservation_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.reserver_id_reservation_seq;
       public          postgres    false    5    230                       0    0    reserver_id_reservation_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.reserver_id_reservation_seq OWNED BY public.reserver.id_reservation;
          public          postgres    false    229            �            1259    17215    statut    TABLE     f   CREATE TABLE public.statut (
    id_statut integer NOT NULL,
    nom_statut character varying(255)
);
    DROP TABLE public.statut;
       public         heap    postgres    false    5            �            1259    17424    statut_categorie    TABLE     l   CREATE TABLE public.statut_categorie (
    id_categorie integer NOT NULL,
    id_statut integer NOT NULL
);
 $   DROP TABLE public.statut_categorie;
       public         heap    postgres    false    5            �            1259    17214    statut_id_statut_seq    SEQUENCE     �   CREATE SEQUENCE public.statut_id_statut_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.statut_id_statut_seq;
       public          postgres    false    5    220                       0    0    statut_id_statut_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.statut_id_statut_seq OWNED BY public.statut.id_statut;
          public          postgres    false    219                       2604    17375 "   caracteristique id_caracteristique    DEFAULT     �   ALTER TABLE ONLY public.caracteristique ALTER COLUMN id_caracteristique SET DEFAULT nextval('public.caracteristique_id_caracteristique_seq'::regclass);
 Q   ALTER TABLE public.caracteristique ALTER COLUMN id_caracteristique DROP DEFAULT;
       public          postgres    false    226    225    226                       2604    17204    categorie id_categorie    DEFAULT     �   ALTER TABLE ONLY public.categorie ALTER COLUMN id_categorie SET DEFAULT nextval('public.categorie_id_categorie_seq'::regclass);
 E   ALTER TABLE public.categorie ALTER COLUMN id_categorie DROP DEFAULT;
       public          postgres    false    216    215    216                       2604    17211    departement id_departement    DEFAULT     �   ALTER TABLE ONLY public.departement ALTER COLUMN id_departement SET DEFAULT nextval('public.departement_id_departement_seq'::regclass);
 I   ALTER TABLE public.departement ALTER COLUMN id_departement DROP DEFAULT;
       public          postgres    false    217    218    218                       2604    25840    reservation_log log_id    DEFAULT     �   ALTER TABLE ONLY public.reservation_log ALTER COLUMN log_id SET DEFAULT nextval('public.reservation_log_log_id_seq'::regclass);
 E   ALTER TABLE public.reservation_log ALTER COLUMN log_id DROP DEFAULT;
       public          postgres    false    232    231    232                       2604    17480    reserver id_reservation    DEFAULT     �   ALTER TABLE ONLY public.reserver ALTER COLUMN id_reservation SET DEFAULT nextval('public.reserver_id_reservation_seq'::regclass);
 F   ALTER TABLE public.reserver ALTER COLUMN id_reservation DROP DEFAULT;
       public          postgres    false    229    230    230                       2604    17218    statut id_statut    DEFAULT     t   ALTER TABLE ONLY public.statut ALTER COLUMN id_statut SET DEFAULT nextval('public.statut_id_statut_seq'::regclass);
 ?   ALTER TABLE public.statut ALTER COLUMN id_statut DROP DEFAULT;
       public          postgres    false    220    219    220            �          0    17378 	   attribuer 
   TABLE DATA           S   COPY public.attribuer (pavillon, numero, id_caracteristique, effectif) FROM stdin;
    public          postgres    false    227   ��       �          0    17372    caracteristique 
   TABLE DATA           R   COPY public.caracteristique (id_caracteristique, nom_caracteristique) FROM stdin;
    public          postgres    false    226   �       �          0    17201 	   categorie 
   TABLE DATA           @   COPY public.categorie (id_categorie, nom_categorie) FROM stdin;
    public          postgres    false    216   W�       �          0    17359    cubicule 
   TABLE DATA           E   COPY public.cubicule (pavillon, numero, numero_cubicule) FROM stdin;
    public          postgres    false    224   �       �          0    17208    departement 
   TABLE DATA           F   COPY public.departement (id_departement, nom_departement) FROM stdin;
    public          postgres    false    218   ��       �          0    17221    local 
   TABLE DATA           I   COPY public.local (pavillon, numero, capacite, id_categorie) FROM stdin;
    public          postgres    false    221   ��       �          0    17231    membre 
   TABLE DATA           I   COPY public.membre (cip, nom, prenom, email, id_departement) FROM stdin;
    public          postgres    false    222   >�       �          0    17304    posseder 
   TABLE DATA           2   COPY public.posseder (cip, id_statut) FROM stdin;
    public          postgres    false    223   l�       �          0    25837    reservation_log 
   TABLE DATA           i   COPY public.reservation_log (log_id, action_type, id_reservation, performed_by, action_date) FROM stdin;
    public          postgres    false    232   �       �          0    17477    reserver 
   TABLE DATA           l   COPY public.reserver (id_reservation, cip, pavillon, numero, date_debut, date_fin, description) FROM stdin;
    public          postgres    false    230   ��       �          0    17215    statut 
   TABLE DATA           7   COPY public.statut (id_statut, nom_statut) FROM stdin;
    public          postgres    false    220   ��       �          0    17424    statut_categorie 
   TABLE DATA           C   COPY public.statut_categorie (id_categorie, id_statut) FROM stdin;
    public          postgres    false    228   (�                  0    0 &   caracteristique_id_caracteristique_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('public.caracteristique_id_caracteristique_seq', 38, true);
          public          postgres    false    225                       0    0    categorie_id_categorie_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.categorie_id_categorie_seq', 21, true);
          public          postgres    false    215                       0    0    departement_id_departement_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.departement_id_departement_seq', 4, true);
          public          postgres    false    217                       0    0    reservation_log_log_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.reservation_log_log_id_seq', 21, true);
          public          postgres    false    231            	           0    0    reserver_id_reservation_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.reserver_id_reservation_seq', 22, true);
          public          postgres    false    229            
           0    0    statut_id_statut_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.statut_id_statut_seq', 4, true);
          public          postgres    false    219            <           2606    17382    attribuer attribuer_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pkey PRIMARY KEY (pavillon, numero, id_caracteristique);
 B   ALTER TABLE ONLY public.attribuer DROP CONSTRAINT attribuer_pkey;
       public            postgres    false    227    227    227            7           2606    17377 $   caracteristique caracteristique_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_pkey PRIMARY KEY (id_caracteristique);
 N   ALTER TABLE ONLY public.caracteristique DROP CONSTRAINT caracteristique_pkey;
       public            postgres    false    226            9           2606    17398 &   caracteristique caracteristique_unique 
   CONSTRAINT     p   ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_unique UNIQUE (nom_caracteristique);
 P   ALTER TABLE ONLY public.caracteristique DROP CONSTRAINT caracteristique_unique;
       public            postgres    false    226                       2606    17206    categorie categorie_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_pkey PRIMARY KEY (id_categorie);
 B   ALTER TABLE ONLY public.categorie DROP CONSTRAINT categorie_pkey;
       public            postgres    false    216                       2606    17400    categorie categorie_unique 
   CONSTRAINT     ^   ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_unique UNIQUE (nom_categorie);
 D   ALTER TABLE ONLY public.categorie DROP CONSTRAINT categorie_unique;
       public            postgres    false    216            4           2606    17363    cubicule cubicule_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pkey PRIMARY KEY (pavillon, numero, numero_cubicule);
 @   ALTER TABLE ONLY public.cubicule DROP CONSTRAINT cubicule_pkey;
       public            postgres    false    224    224    224                       2606    17213    departement departement_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_pkey PRIMARY KEY (id_departement);
 F   ALTER TABLE ONLY public.departement DROP CONSTRAINT departement_pkey;
       public            postgres    false    218                       2606    17396    departement departement_unique 
   CONSTRAINT     d   ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_unique UNIQUE (nom_departement);
 H   ALTER TABLE ONLY public.departement DROP CONSTRAINT departement_unique;
       public            postgres    false    218            &           2606    17225    local local_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_pkey PRIMARY KEY (pavillon, numero);
 :   ALTER TABLE ONLY public.local DROP CONSTRAINT local_pkey;
       public            postgres    false    221    221            *           2606    17239    membre membre_email_key 
   CONSTRAINT     S   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_email_key UNIQUE (email);
 A   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_email_key;
       public            postgres    false    222            ,           2606    17237    membre membre_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_pkey PRIMARY KEY (cip);
 <   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_pkey;
       public            postgres    false    222            .           2606    17423    membre membre_unique 
   CONSTRAINT     P   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_unique UNIQUE (email);
 >   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_unique;
       public            postgres    false    222            2           2606    17308    posseder posseder_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_pkey PRIMARY KEY (cip, id_statut);
 @   ALTER TABLE ONLY public.posseder DROP CONSTRAINT posseder_pkey;
       public            postgres    false    223    223            G           2606    25843 $   reservation_log reservation_log_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.reservation_log
    ADD CONSTRAINT reservation_log_pkey PRIMARY KEY (log_id);
 N   ALTER TABLE ONLY public.reservation_log DROP CONSTRAINT reservation_log_pkey;
       public            postgres    false    232            E           2606    17482    reserver reserver_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pkey PRIMARY KEY (id_reservation);
 @   ALTER TABLE ONLY public.reserver DROP CONSTRAINT reserver_pkey;
       public            postgres    false    230            @           2606    17428 &   statut_categorie statut_categorie_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_pkey PRIMARY KEY (id_categorie, id_statut);
 P   ALTER TABLE ONLY public.statut_categorie DROP CONSTRAINT statut_categorie_pkey;
       public            postgres    false    228    228            "           2606    17220    statut statut_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.statut
    ADD CONSTRAINT statut_pkey PRIMARY KEY (id_statut);
 <   ALTER TABLE ONLY public.statut DROP CONSTRAINT statut_pkey;
       public            postgres    false    220            =           1259    17472     idx_attribuer_id_caracteristique    INDEX     d   CREATE INDEX idx_attribuer_id_caracteristique ON public.attribuer USING btree (id_caracteristique);
 4   DROP INDEX public.idx_attribuer_id_caracteristique;
       public            postgres    false    227            >           1259    17471    idx_attribuer_pavillon_numero    INDEX     _   CREATE INDEX idx_attribuer_pavillon_numero ON public.attribuer USING btree (pavillon, numero);
 1   DROP INDEX public.idx_attribuer_pavillon_numero;
       public            postgres    false    227    227            :           1259    25749    idx_caracteristique_id    INDEX     `   CREATE INDEX idx_caracteristique_id ON public.caracteristique USING btree (id_caracteristique);
 *   DROP INDEX public.idx_caracteristique_id;
       public            postgres    false    226                       1259    25748    idx_categorie_id    INDEX     N   CREATE INDEX idx_categorie_id ON public.categorie USING btree (id_categorie);
 $   DROP INDEX public.idx_categorie_id;
       public            postgres    false    216            5           1259    17470    idx_cubicule_pavillon_numero    INDEX     ]   CREATE INDEX idx_cubicule_pavillon_numero ON public.cubicule USING btree (pavillon, numero);
 0   DROP INDEX public.idx_cubicule_pavillon_numero;
       public            postgres    false    224    224                       1259    25747    idx_departement_id    INDEX     T   CREATE INDEX idx_departement_id ON public.departement USING btree (id_departement);
 &   DROP INDEX public.idx_departement_id;
       public            postgres    false    218            #           1259    17463    idx_local_id_categorie    INDEX     P   CREATE INDEX idx_local_id_categorie ON public.local USING btree (id_categorie);
 *   DROP INDEX public.idx_local_id_categorie;
       public            postgres    false    221            $           1259    25743    idx_local_pavillon_numero    INDEX     W   CREATE INDEX idx_local_pavillon_numero ON public.local USING btree (pavillon, numero);
 -   DROP INDEX public.idx_local_pavillon_numero;
       public            postgres    false    221    221            '           1259    17466    idx_membre_cip    INDEX     @   CREATE INDEX idx_membre_cip ON public.membre USING btree (cip);
 "   DROP INDEX public.idx_membre_cip;
       public            postgres    false    222            (           1259    17465    idx_membre_id_departement    INDEX     V   CREATE INDEX idx_membre_id_departement ON public.membre USING btree (id_departement);
 -   DROP INDEX public.idx_membre_id_departement;
       public            postgres    false    222            /           1259    17473    idx_posseder_cip    INDEX     D   CREATE INDEX idx_posseder_cip ON public.posseder USING btree (cip);
 $   DROP INDEX public.idx_posseder_cip;
       public            postgres    false    223            0           1259    17474    idx_posseder_id_statut    INDEX     P   CREATE INDEX idx_posseder_id_statut ON public.posseder USING btree (id_statut);
 *   DROP INDEX public.idx_posseder_id_statut;
       public            postgres    false    223            A           1259    25744    idx_reserver_cip    INDEX     D   CREATE INDEX idx_reserver_cip ON public.reserver USING btree (cip);
 $   DROP INDEX public.idx_reserver_cip;
       public            postgres    false    230            B           1259    25746    idx_reserver_date_debut_fin    INDEX     `   CREATE INDEX idx_reserver_date_debut_fin ON public.reserver USING btree (date_debut, date_fin);
 /   DROP INDEX public.idx_reserver_date_debut_fin;
       public            postgres    false    230    230            C           1259    25745    idx_reserver_pavillon_numero    INDEX     ]   CREATE INDEX idx_reserver_pavillon_numero ON public.reserver USING btree (pavillon, numero);
 0   DROP INDEX public.idx_reserver_pavillon_numero;
       public            postgres    false    230    230                        1259    25750    idx_statut_id    INDEX     E   CREATE INDEX idx_statut_id ON public.statut USING btree (id_statut);
 !   DROP INDEX public.idx_statut_id;
       public            postgres    false    220            S           2620    25860    reserver trg_handle_reservation    TRIGGER     �   CREATE TRIGGER trg_handle_reservation BEFORE INSERT ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.handle_reservation();
 8   DROP TRIGGER trg_handle_reservation ON public.reserver;
       public          postgres    false    250    230            T           2620    25799     reserver trg_log_delete_reserver    TRIGGER     �   CREATE TRIGGER trg_log_delete_reserver AFTER DELETE ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.log_delete_reserver();
 9   DROP TRIGGER trg_log_delete_reserver ON public.reserver;
       public          postgres    false    230    235            U           2620    25797     reserver trg_log_insert_reserver    TRIGGER     �   CREATE TRIGGER trg_log_insert_reserver AFTER INSERT ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.log_insert_reserver();
 9   DROP TRIGGER trg_log_insert_reserver ON public.reserver;
       public          postgres    false    230    234            V           2620    25798     reserver trg_log_update_reserver    TRIGGER     �   CREATE TRIGGER trg_log_update_reserver AFTER UPDATE ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.log_update_reserver();
 9   DROP TRIGGER trg_log_update_reserver ON public.reserver;
       public          postgres    false    230    233            M           2606    17383 +   attribuer attribuer_id_caracteristique_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_id_caracteristique_fkey FOREIGN KEY (id_caracteristique) REFERENCES public.caracteristique(id_caracteristique);
 U   ALTER TABLE ONLY public.attribuer DROP CONSTRAINT attribuer_id_caracteristique_fkey;
       public          postgres    false    227    226    3383            N           2606    17388 (   attribuer attribuer_pavillon_numero_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);
 R   ALTER TABLE ONLY public.attribuer DROP CONSTRAINT attribuer_pavillon_numero_fkey;
       public          postgres    false    227    227    3366    221    221            L           2606    17364 &   cubicule cubicule_pavillon_numero_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);
 P   ALTER TABLE ONLY public.cubicule DROP CONSTRAINT cubicule_pavillon_numero_fkey;
       public          postgres    false    3366    224    224    221    221            H           2606    17226    local local_id_categorie_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);
 G   ALTER TABLE ONLY public.local DROP CONSTRAINT local_id_categorie_fkey;
       public          postgres    false    221    3351    216            I           2606    17240 !   membre membre_id_departement_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_id_departement_fkey FOREIGN KEY (id_departement) REFERENCES public.departement(id_departement);
 K   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_id_departement_fkey;
       public          postgres    false    3356    218    222            J           2606    17314    posseder posseder_cip_fkey    FK CONSTRAINT     w   ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);
 D   ALTER TABLE ONLY public.posseder DROP CONSTRAINT posseder_cip_fkey;
       public          postgres    false    222    3372    223            K           2606    17309     posseder posseder_id_statut_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);
 J   ALTER TABLE ONLY public.posseder DROP CONSTRAINT posseder_id_statut_fkey;
       public          postgres    false    3362    220    223            Q           2606    17483    reserver reserver_cip_fkey    FK CONSTRAINT     w   ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);
 D   ALTER TABLE ONLY public.reserver DROP CONSTRAINT reserver_cip_fkey;
       public          postgres    false    230    222    3372            R           2606    17488 &   reserver reserver_pavillon_numero_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);
 P   ALTER TABLE ONLY public.reserver DROP CONSTRAINT reserver_pavillon_numero_fkey;
       public          postgres    false    221    221    230    230    3366            O           2606    17429 3   statut_categorie statut_categorie_id_categorie_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);
 ]   ALTER TABLE ONLY public.statut_categorie DROP CONSTRAINT statut_categorie_id_categorie_fkey;
       public          postgres    false    228    3351    216            P           2606    17434 0   statut_categorie statut_categorie_id_statut_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);
 Z   ALTER TABLE ONLY public.statut_categorie DROP CONSTRAINT statut_categorie_id_statut_fkey;
       public          postgres    false    3362    220    228            �      C1	1936	15	8
    C1	4488	22	7
    C1	4474	5	9
    C1	3721	3	6
    C1	2609	12	10
    C2	4809	30	4
    C2	4739	28	5
    C2	4740	7	3
    C2	3553	33	6
    C2	5427	19	9
    C2	3074	11	4
    C1	4392	16	8
    C1	5299	24	2
    C1	3784	10	7
    C1	3616	20	5
    C1	3363	9	4
    C2	4159	17	10
    C2	5961	6	8
    C2	4628	25	3
    C2	1170	32	9
    C2	3341	8	6
    C2	5912	27	7
    C1	5675	13	10
    C1	3403	4	9
    C1	5055	31	8
    C2	1019	35	5
    C2	1959	23	3
    C2	2406	18	6
    C2	1052	14	4
    C1	2787	2	7
    C1	2658	36	5
    C1	4796	38	8
    C2	1587	21	9
    C2	3138	26	2
    C2	5543	29	6
    \.


      �      1	Connexion à Internet
    2	Tables fixes en U
    3	Chaises mobiles
    4	Monoplaces
    5	Tables mobiles
    6	Chaises fixes
    7	Tables hautes
    8	Chaises hautes
    9	Tables fixes
 
   10	Écran
    11	Rétroprojecteur
    12	Gradins
    13	Fenêtres
 	   14	Piano
    15	Autres instruments
    16	Système de son
     17	Salle réservée (spéciale)
    18	Ordinateurs PC
 +   19	Ordinateurs SUN pour génie électrique
 .   20	Ordinateurs (oscillomètre et multimètre)
 ,   21	Ordinateurs modélisation des structures
 '   22	Équipement pour microélectronique
 '   23	Équipement pour génie électrique
 "   24	Équipement pour mécatronique
 (   25	Équipement pour la caractérisation
 '   26	Équipement pour la thermodynamique
 !   27	Équipement pour génie civil
    28	Équipement métrologie
    29	Équipement de machinerie
    30	Équipement de géologie
    31	Télévision
    32	VHS
    33	Hauts parleurs
 	   34	Micro
    35	Magnétophone à cassette
    36	Amplificateur audio
    37	Local barré
    38	Prise réseau
    \.


      �      1	Salle de classe générale
     2	Salle de classe spécialisée
    3	Salle de séminaire
    4	Cubicules
    5	Laboratoire informatique
 ,   6	Laboratoire d’enseignement spécialisé
 
   7	Atelier
    8	Salle à dessin
    9	Atelier (civil)
    10	Salle de musique
 4   11	Atelier sur 2 étages, conjoint avec autre local
    12	Salle de conférence
    13	Salle de réunion
 "   14	Salle d’entrevue et de tests
 '   15	Salle de lecture ou de consultation
    16	Auditorium
    17	Salle de concert
    18	Salle d’audience
    19	Salon du personnel
    20	Studio d’enregistrement
    21	Hall d’entrée
    \.


      �      \.


      �   ,   1	Génie électrique et Génie informatique
    2	Génie mécanique
 $   3	Génie chimique et biotechnologie
    4	Génie civil et du bâtiment
    \.


      �      C1	1936	74	1
    C1	4488	9	4
    C1	4474	22	3
    C1	3721	5	4
    C1	2609	50	5
    C2	4809	11	6
    C2	4739	78	7
    C2	4740	44	8
    C2	3553	32	10
    C2	5427	58	11
    C1	4392	8	4
    C1	5299	57	2
    C1	3784	14	3
    C1	3616	62	5
    C1	3363	42	6
    C2	4159	65	9
    C2	5961	13	12
    C2	4628	50	13
    C2	1170	1	16
    C2	3341	48	17
    C2	5912	21	20
    C1	5675	7	4
    C1	3403	53	5
    C1	5055	67	8
    C2	1019	35	13
    C2	1959	69	14
    C2	2406	55	19
    C2	1052	48	21
    C1	2787	80	13
    C1	2658	64	14
    C1	4796	52	18
    C2	3138	59	20
    C2	5543	64	21
    C2	1587	12	19
    C2	3074	8	15
    \.


      �   6   benm2043	Bendjeddou	Mohamed	benm2043@usherbrooke.ca	1
 4   msha2019	Bendjeddou	Masha	msha2019@usherbrooke.ca	1
 5   tarks781	Johnny	Washington	tarks781@usherbrooke.ca	4
 2   lpedz807	Rosie	Hamilton	lpedz807@usherbrooke.ca	2
 /   virgx325	Lee	Aguilar	virgx325@usherbrooke.ca	3
    \.


      �      msha2019	4
    tarks781	3
    lpedz807	1
    virgx325	2
    virgx325	3
    benm2043	1
    \.


      �   (   1	UPDATE	3	virgx325	2024-09-16 22:04:04
 (   2	UPDATE	3	virgx325	2024-09-16 22:04:24
 )   3	DELETE	16	benm2043	2024-09-16 22:07:27
 )   4	INSERT	17	virgx325	2024-09-16 22:08:55
 )   5	UPDATE	17	virgx325	2024-09-16 22:09:04
 (   6	UPDATE	6	msha2019	2024-09-16 22:15:01
 (   7	UPDATE	1	lpedz807	2024-09-16 22:15:01
 (   8	UPDATE	3	virgx325	2024-09-16 22:15:01
 )   9	UPDATE	17	virgx325	2024-09-16 22:15:01
 )   10	UPDATE	4	lpedz807	2024-09-16 22:25:36
 )   11	UPDATE	4	lpedz807	2024-09-16 22:25:45
 )   12	DELETE	4	lpedz807	2024-09-16 22:27:09
 *   13	INSERT	22	lpedz807	2024-09-16 22:29:16
 *   14	UPDATE	22	lpedz807	2024-09-16 22:32:11
 )   15	UPDATE	1	lpedz807	2024-09-16 22:39:19
 )   16	UPDATE	1	lpedz807	2024-09-16 22:39:48
 )   17	DELETE	1	lpedz807	2024-09-16 22:40:18
 )   18	UPDATE	2	benm2043	2024-09-16 22:40:54
 *   19	UPDATE	22	lpedz807	2024-09-16 22:41:54
 )   20	UPDATE	2	benm2043	2024-09-16 22:42:47
 *   21	UPDATE	22	lpedz807	2024-09-16 22:43:29
    \.


      �   L   5	tarks781	C2	1019	2024-10-18 10:30:00	2024-10-18 13:00:00	Entraide en Math
 R   6	msha2019	C2	5543	2024-10-19 08:00:00	2024-10-19 09:00:00	Travail administrative
 I   3	virgx325	C1	3616	2024-10-20 08:30:00	2024-10-20 11:00:00	Conference IA
 R   17	virgx325	C1	3616	2024-10-21 16:30:00	2024-10-21 17:55:00	Personal buiseness :)
 M   2	benm2043	C1	1936	2024-10-16 08:30:00	2024-10-16 10:00:00	Travail en equipe
 J   22	lpedz807	C1	1936	2024-10-16 11:00:00	2024-10-16 12:00:00	Just chilling
    \.


      �      1	Étudiant
    2	Enseignant
    3	Personnel de soutien
    4	Administrateur
    \.


      �      1	1
    2	1
    3	1
    4	1
    5	1
    6	1
    7	1
    8	1
    10	1
    11	1
    15	1
    1	2
    2	2
    3	2
    5	2
    6	2
    9	2
    12	2
    13	2
    16	2
    17	2
    20	2
    4	3
    5	3
    8	3
    13	3
    14	3
    19	3
    21	3
    13	4
    14	4
    18	4
    19	4
    20	4
    21	4
    \.


     