-- First, create the independent tables
CREATE TABLE DEPARTEMENT (
    id_departement SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom_departement VARCHAR(50) NOT NULL
);


CREATE TABLE STATUT (
    id_statut SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom_statut VARCHAR(50) NOT NULL
);

CREATE TABLE CARACTERISTIQUE (
    code_caractéristique SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom_caractéristique VARCHAR(50) NOT NULL
);

-- Create MEMBRE table as it references DEPARTEMENT
CREATE TABLE MEMBRE (
    cip VARCHAR(4) NOT NULL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prénom VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    id_departement SMALLINT,
    FOREIGN KEY (id_departement) REFERENCES DEPARTEMENT(id_departement)
);

-- Create LOCAL before ATTRIBUER due to foreign key dependencies
CREATE TABLE LOCAL (
    pavillon VARCHAR(2) NOT NULL,
    numero SMALLINT NOT NULL,
    catégorie VARCHAR(50),
    capacité SMALLINT,
    pavillon_2 VARCHAR(2),
    numero_2 SMALLINT,
    PRIMARY KEY (pavillon, numero),
    FOREIGN KEY (pavillon_2, numero_2) REFERENCES LOCAL(pavillon, numero) -- Recursive foreign key
);

-- Now create ATTRIBUER as LOCAL and CARACTÉRISTIQUE exist
CREATE TABLE ATTRIBUER (
    pavillon VARCHAR(2) NOT NULL,
    numero SMALLINT NOT NULL,
    code_caractéristique SMALLINT NOT NULL,
    effectif SMALLINT,
    PRIMARY KEY (pavillon, numero, code_caractéristique),
    FOREIGN KEY (pavillon, numero) REFERENCES LOCAL(pavillon, numero),
    FOREIGN KEY (code_caractéristique) REFERENCES CARACTÉRISTIQUE(code_caractéristique)
);

-- Create RÉSERVATION before CONSULTER, since it will be referenced by CONSULTER
CREATE TABLE RÉSERVATION (
    id_réservation INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_début DATE NOT NULL,
    date_fin DATE NOT NULL,
    description VARCHAR(255),
    cip_1 VARCHAR(4),
    date_modification DATE,
    cip_2 VARCHAR(4),
    date_suppression DATE,
    pavillon VARCHAR(2),
    numero SMALLINT,
    cip_3 VARCHAR(4),
    date_effectuation DATE,
    FOREIGN KEY (cip_1) REFERENCES MEMBRE(cip),
    FOREIGN KEY (cip_2) REFERENCES MEMBRE(cip),
    FOREIGN KEY (cip_3) REFERENCES MEMBRE(cip),
    FOREIGN KEY (pavillon, numero) REFERENCES LOCAL(pavillon, numero)
);

-- Now create CONSULTER as RÉSERVATION and MEMBRE exist
CREATE TABLE CONSULTER (
    cip VARCHAR(4) NOT NULL,
    id_réservation INT NOT NULL,
    date_consultation DATE NOT NULL,
    PRIMARY KEY (cip, id_réservation),
    FOREIGN KEY (cip) REFERENCES MEMBRE(cip),
    FOREIGN KEY (id_réservation) REFERENCES RÉSERVATION(id_réservation)
);

-- Create POSSEDER since MEMBRE and STATUT exist
CREATE TABLE POSSEDER (
    cip VARCHAR(4) NOT NULL,
    id_statut SMALLINT NOT NULL,
    PRIMARY KEY (cip, id_statut),
    FOREIGN KEY (cip) REFERENCES MEMBRE(cip),
    FOREIGN KEY (id_statut) REFERENCES STATUT(id_statut)
);

