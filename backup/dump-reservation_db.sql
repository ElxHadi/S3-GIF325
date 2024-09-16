PGDMP      9                |           reservation_db #   16.4 (Ubuntu 16.4-0ubuntu0.24.04.2) #   16.4 (Ubuntu 16.4-0ubuntu0.24.04.2) Y    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
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
       public          postgres    false    5    216            �           0    0    categorie_id_categorie_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.categorie_id_categorie_seq OWNED BY public.categorie.id_categorie;
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
       public          postgres    false    5    218            �           0    0    departement_id_departement_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.departement_id_departement_seq OWNED BY public.departement.id_departement;
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
       public         heap    postgres    false    5            �            1259    17477    reserver    TABLE     S  CREATE TABLE public.reserver (
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
       public          postgres    false    5    230            �           0    0    reserver_id_reservation_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.reserver_id_reservation_seq OWNED BY public.reserver.id_reservation;
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
       public          postgres    false    5    220            �           0    0    statut_id_statut_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.statut_id_statut_seq OWNED BY public.statut.id_statut;
          public          postgres    false    219                       2604    17375 "   caracteristique id_caracteristique    DEFAULT     �   ALTER TABLE ONLY public.caracteristique ALTER COLUMN id_caracteristique SET DEFAULT nextval('public.caracteristique_id_caracteristique_seq'::regclass);
 Q   ALTER TABLE public.caracteristique ALTER COLUMN id_caracteristique DROP DEFAULT;
       public          postgres    false    226    225    226                       2604    17204    categorie id_categorie    DEFAULT     �   ALTER TABLE ONLY public.categorie ALTER COLUMN id_categorie SET DEFAULT nextval('public.categorie_id_categorie_seq'::regclass);
 E   ALTER TABLE public.categorie ALTER COLUMN id_categorie DROP DEFAULT;
       public          postgres    false    215    216    216                       2604    17211    departement id_departement    DEFAULT     �   ALTER TABLE ONLY public.departement ALTER COLUMN id_departement SET DEFAULT nextval('public.departement_id_departement_seq'::regclass);
 I   ALTER TABLE public.departement ALTER COLUMN id_departement DROP DEFAULT;
       public          postgres    false    218    217    218                       2604    17480    reserver id_reservation    DEFAULT     �   ALTER TABLE ONLY public.reserver ALTER COLUMN id_reservation SET DEFAULT nextval('public.reserver_id_reservation_seq'::regclass);
 F   ALTER TABLE public.reserver ALTER COLUMN id_reservation DROP DEFAULT;
       public          postgres    false    229    230    230                       2604    17218    statut id_statut    DEFAULT     t   ALTER TABLE ONLY public.statut ALTER COLUMN id_statut SET DEFAULT nextval('public.statut_id_statut_seq'::regclass);
 ?   ALTER TABLE public.statut ALTER COLUMN id_statut DROP DEFAULT;
       public          postgres    false    220    219    220            �          0    17378 	   attribuer 
   TABLE DATA           S   COPY public.attribuer (pavillon, numero, id_caracteristique, effectif) FROM stdin;
    public          postgres    false    227   �v       �          0    17372    caracteristique 
   TABLE DATA           R   COPY public.caracteristique (id_caracteristique, nom_caracteristique) FROM stdin;
    public          postgres    false    226   (w       �          0    17201 	   categorie 
   TABLE DATA           @   COPY public.categorie (id_categorie, nom_categorie) FROM stdin;
    public          postgres    false    216   y       �          0    17359    cubicule 
   TABLE DATA           E   COPY public.cubicule (pavillon, numero, numero_cubicule) FROM stdin;
    public          postgres    false    224   bz       �          0    17208    departement 
   TABLE DATA           F   COPY public.departement (id_departement, nom_departement) FROM stdin;
    public          postgres    false    218   �z       �          0    17221    local 
   TABLE DATA           I   COPY public.local (pavillon, numero, capacite, id_categorie) FROM stdin;
    public          postgres    false    221   {       �          0    17231    membre 
   TABLE DATA           I   COPY public.membre (cip, nom, prenom, email, id_departement) FROM stdin;
    public          postgres    false    222   ]{       �          0    17304    posseder 
   TABLE DATA           2   COPY public.posseder (cip, id_statut) FROM stdin;
    public          postgres    false    223   |       �          0    17477    reserver 
   TABLE DATA           l   COPY public.reserver (id_reservation, cip, pavillon, numero, date_debut, date_fin, description) FROM stdin;
    public          postgres    false    230   Z|       �          0    17215    statut 
   TABLE DATA           7   COPY public.statut (id_statut, nom_statut) FROM stdin;
    public          postgres    false    220   �|       �          0    17424    statut_categorie 
   TABLE DATA           C   COPY public.statut_categorie (id_categorie, id_statut) FROM stdin;
    public          postgres    false    228   $}       �           0    0 &   caracteristique_id_caracteristique_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('public.caracteristique_id_caracteristique_seq', 38, true);
          public          postgres    false    225            �           0    0    categorie_id_categorie_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.categorie_id_categorie_seq', 21, true);
          public          postgres    false    215            �           0    0    departement_id_departement_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.departement_id_departement_seq', 4, true);
          public          postgres    false    217            �           0    0    reserver_id_reservation_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.reserver_id_reservation_seq', 3, true);
          public          postgres    false    229            �           0    0    statut_id_statut_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.statut_id_statut_seq', 4, true);
          public          postgres    false    219            *           2606    17382    attribuer attribuer_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pkey PRIMARY KEY (pavillon, numero, id_caracteristique);
 B   ALTER TABLE ONLY public.attribuer DROP CONSTRAINT attribuer_pkey;
       public            postgres    false    227    227    227            &           2606    17377 $   caracteristique caracteristique_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_pkey PRIMARY KEY (id_caracteristique);
 N   ALTER TABLE ONLY public.caracteristique DROP CONSTRAINT caracteristique_pkey;
       public            postgres    false    226            (           2606    17398 &   caracteristique caracteristique_unique 
   CONSTRAINT     p   ALTER TABLE ONLY public.caracteristique
    ADD CONSTRAINT caracteristique_unique UNIQUE (nom_caracteristique);
 P   ALTER TABLE ONLY public.caracteristique DROP CONSTRAINT caracteristique_unique;
       public            postgres    false    226            	           2606    17206    categorie categorie_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_pkey PRIMARY KEY (id_categorie);
 B   ALTER TABLE ONLY public.categorie DROP CONSTRAINT categorie_pkey;
       public            postgres    false    216                       2606    17400    categorie categorie_unique 
   CONSTRAINT     ^   ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT categorie_unique UNIQUE (nom_categorie);
 D   ALTER TABLE ONLY public.categorie DROP CONSTRAINT categorie_unique;
       public            postgres    false    216            #           2606    17363    cubicule cubicule_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pkey PRIMARY KEY (pavillon, numero, numero_cubicule);
 @   ALTER TABLE ONLY public.cubicule DROP CONSTRAINT cubicule_pkey;
       public            postgres    false    224    224    224                       2606    17213    departement departement_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_pkey PRIMARY KEY (id_departement);
 F   ALTER TABLE ONLY public.departement DROP CONSTRAINT departement_pkey;
       public            postgres    false    218                       2606    17396    departement departement_unique 
   CONSTRAINT     d   ALTER TABLE ONLY public.departement
    ADD CONSTRAINT departement_unique UNIQUE (nom_departement);
 H   ALTER TABLE ONLY public.departement DROP CONSTRAINT departement_unique;
       public            postgres    false    218                       2606    17225    local local_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_pkey PRIMARY KEY (pavillon, numero);
 :   ALTER TABLE ONLY public.local DROP CONSTRAINT local_pkey;
       public            postgres    false    221    221                       2606    17239    membre membre_email_key 
   CONSTRAINT     S   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_email_key UNIQUE (email);
 A   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_email_key;
       public            postgres    false    222                       2606    17237    membre membre_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_pkey PRIMARY KEY (cip);
 <   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_pkey;
       public            postgres    false    222                       2606    17423    membre membre_unique 
   CONSTRAINT     P   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_unique UNIQUE (email);
 >   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_unique;
       public            postgres    false    222            !           2606    17308    posseder posseder_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_pkey PRIMARY KEY (cip, id_statut);
 @   ALTER TABLE ONLY public.posseder DROP CONSTRAINT posseder_pkey;
       public            postgres    false    223    223            0           2606    17482    reserver reserver_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pkey PRIMARY KEY (id_reservation);
 @   ALTER TABLE ONLY public.reserver DROP CONSTRAINT reserver_pkey;
       public            postgres    false    230            .           2606    17428 &   statut_categorie statut_categorie_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_pkey PRIMARY KEY (id_categorie, id_statut);
 P   ALTER TABLE ONLY public.statut_categorie DROP CONSTRAINT statut_categorie_pkey;
       public            postgres    false    228    228                       2606    17220    statut statut_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.statut
    ADD CONSTRAINT statut_pkey PRIMARY KEY (id_statut);
 <   ALTER TABLE ONLY public.statut DROP CONSTRAINT statut_pkey;
       public            postgres    false    220            +           1259    17472     idx_attribuer_id_caracteristique    INDEX     d   CREATE INDEX idx_attribuer_id_caracteristique ON public.attribuer USING btree (id_caracteristique);
 4   DROP INDEX public.idx_attribuer_id_caracteristique;
       public            postgres    false    227            ,           1259    17471    idx_attribuer_pavillon_numero    INDEX     _   CREATE INDEX idx_attribuer_pavillon_numero ON public.attribuer USING btree (pavillon, numero);
 1   DROP INDEX public.idx_attribuer_pavillon_numero;
       public            postgres    false    227    227            $           1259    17470    idx_cubicule_pavillon_numero    INDEX     ]   CREATE INDEX idx_cubicule_pavillon_numero ON public.cubicule USING btree (pavillon, numero);
 0   DROP INDEX public.idx_cubicule_pavillon_numero;
       public            postgres    false    224    224                       1259    17463    idx_local_id_categorie    INDEX     P   CREATE INDEX idx_local_id_categorie ON public.local USING btree (id_categorie);
 *   DROP INDEX public.idx_local_id_categorie;
       public            postgres    false    221                       1259    17464    idx_local_pavillon_numero    INDEX     W   CREATE INDEX idx_local_pavillon_numero ON public.local USING btree (pavillon, numero);
 -   DROP INDEX public.idx_local_pavillon_numero;
       public            postgres    false    221    221                       1259    17466    idx_membre_cip    INDEX     @   CREATE INDEX idx_membre_cip ON public.membre USING btree (cip);
 "   DROP INDEX public.idx_membre_cip;
       public            postgres    false    222                       1259    17465    idx_membre_id_departement    INDEX     V   CREATE INDEX idx_membre_id_departement ON public.membre USING btree (id_departement);
 -   DROP INDEX public.idx_membre_id_departement;
       public            postgres    false    222                       1259    17473    idx_posseder_cip    INDEX     D   CREATE INDEX idx_posseder_cip ON public.posseder USING btree (cip);
 $   DROP INDEX public.idx_posseder_cip;
       public            postgres    false    223                       1259    17474    idx_posseder_id_statut    INDEX     P   CREATE INDEX idx_posseder_id_statut ON public.posseder USING btree (id_statut);
 *   DROP INDEX public.idx_posseder_id_statut;
       public            postgres    false    223            <           2620    17493    reserver trg_handle_reservation    TRIGGER     �   CREATE TRIGGER trg_handle_reservation BEFORE INSERT OR UPDATE ON public.reserver FOR EACH ROW EXECUTE FUNCTION public.handle_reservation();
 8   DROP TRIGGER trg_handle_reservation ON public.reserver;
       public          postgres    false    245    230            6           2606    17383 +   attribuer attribuer_id_caracteristique_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_id_caracteristique_fkey FOREIGN KEY (id_caracteristique) REFERENCES public.caracteristique(id_caracteristique);
 U   ALTER TABLE ONLY public.attribuer DROP CONSTRAINT attribuer_id_caracteristique_fkey;
       public          postgres    false    3366    227    226            7           2606    17388 (   attribuer attribuer_pavillon_numero_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.attribuer
    ADD CONSTRAINT attribuer_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);
 R   ALTER TABLE ONLY public.attribuer DROP CONSTRAINT attribuer_pavillon_numero_fkey;
       public          postgres    false    221    3349    227    227    221            5           2606    17364 &   cubicule cubicule_pavillon_numero_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cubicule
    ADD CONSTRAINT cubicule_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);
 P   ALTER TABLE ONLY public.cubicule DROP CONSTRAINT cubicule_pavillon_numero_fkey;
       public          postgres    false    3349    221    224    224    221            1           2606    17226    local local_id_categorie_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.local
    ADD CONSTRAINT local_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);
 G   ALTER TABLE ONLY public.local DROP CONSTRAINT local_id_categorie_fkey;
       public          postgres    false    216    221    3337            2           2606    17240 !   membre membre_id_departement_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.membre
    ADD CONSTRAINT membre_id_departement_fkey FOREIGN KEY (id_departement) REFERENCES public.departement(id_departement);
 K   ALTER TABLE ONLY public.membre DROP CONSTRAINT membre_id_departement_fkey;
       public          postgres    false    222    3341    218            3           2606    17314    posseder posseder_cip_fkey    FK CONSTRAINT     w   ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);
 D   ALTER TABLE ONLY public.posseder DROP CONSTRAINT posseder_cip_fkey;
       public          postgres    false    222    3355    223            4           2606    17309     posseder posseder_id_statut_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.posseder
    ADD CONSTRAINT posseder_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);
 J   ALTER TABLE ONLY public.posseder DROP CONSTRAINT posseder_id_statut_fkey;
       public          postgres    false    220    223    3345            :           2606    17483    reserver reserver_cip_fkey    FK CONSTRAINT     w   ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_cip_fkey FOREIGN KEY (cip) REFERENCES public.membre(cip);
 D   ALTER TABLE ONLY public.reserver DROP CONSTRAINT reserver_cip_fkey;
       public          postgres    false    230    222    3355            ;           2606    17488 &   reserver reserver_pavillon_numero_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reserver
    ADD CONSTRAINT reserver_pavillon_numero_fkey FOREIGN KEY (pavillon, numero) REFERENCES public.local(pavillon, numero);
 P   ALTER TABLE ONLY public.reserver DROP CONSTRAINT reserver_pavillon_numero_fkey;
       public          postgres    false    221    230    230    3349    221            8           2606    17429 3   statut_categorie statut_categorie_id_categorie_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_categorie_fkey FOREIGN KEY (id_categorie) REFERENCES public.categorie(id_categorie);
 ]   ALTER TABLE ONLY public.statut_categorie DROP CONSTRAINT statut_categorie_id_categorie_fkey;
       public          postgres    false    228    216    3337            9           2606    17434 0   statut_categorie statut_categorie_id_statut_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.statut_categorie
    ADD CONSTRAINT statut_categorie_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES public.statut(id_statut);
 Z   ALTER TABLE ONLY public.statut_categorie DROP CONSTRAINT statut_categorie_id_statut_fkey;
       public          postgres    false    228    3345    220            �   #   x�s1�4664�4�4��rs,88��b���� Q_�      �   �  x�uSIn1<���Ѿ��֣!�q�8";�\ZT[b�e�E���_���7���hq0�|�Y����Tl��'�(��'�08L�fw�2Ń~�/:q�%�oAG
�_i���z����)儎_�{>9����W��0��Հ�_*��Už�6��U�xU����Q�kt�O
]֐-48ϫ��ݓ N
٢K���9��bQ�QDO��cP��F�Ң��Mi��������
AW7�ŜW������h|bSZ�Q�֐ɠ3�zУ^���1ޖ�&0	�M҇��U�m���t���gM�t����F���u�]gV����;�oi�|Ϩ�����-ÀP@�҆�M^���������&��Rz���=����M��D{����a P�I��(+vG]�v�c�U���͒K�n��h �n�\�iw��r�na㨸o��a��(�S"�1����Z�7& �5�L�g����).�lA�9d����/}�I      �   5  x�eQ�R�0���p	3��=�
:Z��ˈq�ò��7�h�����PZ��]�l��B@Ӡ����i���>��P�e;��\ z��3���QB�TOeM��V/n��QC���s�>
��
j~>���e��̫U�@�`q���U��G��x�Q��p��ٻY{�II�6C�]�rg|��H��v�+Yӄ�] {�䍶��U�b�4�)2��q��DUv摔Q��������Q,q)!k1�ЬZ��rLT:��S���r��K���MS��DfPkY)�+aK��Ǝ��ճ
�"�7}��_����      �      x�s6�4102�4�r����,c�=... d�J      �   h   x�=��	�0EѵSE*��`n4�� ����.u�1Q��ýUѥ(`��c�;����2���0չ�)�A^k��>�#��]%������pO0fL�³(�%�p�3�      �   E   x�%���0��^1��8R�������]g�T��̌�oaj/a��!�bX�4.���� &�      �   �   x�e���0�织!P0�N�����r���Ǵ`ԧ;���Ӳ�"�Jذ�W�ҏp��,Kh�n5Fš���]
�Q�ȋ��E�d���B릀�W�=�4��u�w��|���X�������aKV�ϑ��xס{�b{fXw�6 �y^�9C�7��Vi      �   E   x��-�H420��4�*I,�.6�0�4��)HM��00�4�*�,J�062�4B0���R�r�L��
b���� İ@      �   ^   x�3�LJ��5201�t1�4664�4202�54�54S0��20 "1K+c�XHQbYbf�BAjQq~^j�gNAjJ���9������!�f��qqq �$�      �   L   x�3�<�YR����W�e��W�����s�����(��*痖d��q�p:��f�e�%���q��qqq h��      �   W   x�%��� �j<L��� �d�9��R�h(
nx`�MK�OI��I���Q^�I��D=����|G^tP�����A<l_;�+">���     