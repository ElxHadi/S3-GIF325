-- Table for CARACTERISTIQUE
CREATE TABLE CARACTERISTIQUE (
  id_caracteristique SERIAL PRIMARY KEY,
  nom_caracteristique VARCHAR(255)
);

-- Table for CATEGORIE
CREATE TABLE CATEGORIE (
  id_categorie SERIAL PRIMARY KEY,
  nom_categorie VARCHAR(255)
);

-- Table for DEPARTEMENT
CREATE TABLE DEPARTEMENT (
  id_departement SERIAL PRIMARY KEY,
  nom_departement VARCHAR(255)
);

-- Table for STATUT
CREATE TABLE STATUT (
  id_statut SERIAL PRIMARY KEY,
  nom_statut VARCHAR(255)
);

-- Table for LOCAL
CREATE TABLE LOCAL (
  pavillon VARCHAR(2) NOT NULL,
  numero VARCHAR(4) NOT NULL,
  capacite SMALLINT, -- Assuming capacite is a numeric value
  id_categorie SMALLINT NOT NULL,
  PRIMARY KEY (pavillon, numero),
  FOREIGN KEY (id_categorie) REFERENCES CATEGORIE (id_categorie)
);

-- Table for MEMBRE
CREATE TABLE MEMBRE (
  cip VARCHAR(8) NOT NULL,
  nom VARCHAR(255) NOT NULL,
  prenom VARCHAR(255),
  email VARCHAR(255) UNIQUE NOT NULL,
  id_departement SMALLINT NOT NULL,
  PRIMARY KEY (cip),
  FOREIGN KEY (id_departement) REFERENCES DEPARTEMENT (id_departement)
);

CREATE TABLE RESERVER (
  cip VARCHAR(8) PRIMARY KEY,
  pavillon VARCHAR(2) PRIMARY KEY,
  numero VARCHAR(4) PRIMARY KEY,
  date_debut TIMESTAMP PRIMARY KEY, -- Assuming date and time are required
  date_fin TIMESTAMP PRIMARY KEY, -- Assuming date and time are required
  description VARCHAR(255), -- Assuming description may be longer text
  FOREIGN KEY (cip) REFERENCES MEMBRE (cip),
  FOREIGN KEY (pavillon, numero) REFERENCES LOCAL (pavillon, numero)
);
-- Table for CUBICULE
CREATE TABLE CUBICULE (
  numero_cubicule SERIAL PRIMARY KEY,
  pavillon VARCHAR(2) NOT NULL,
  numero VARCHAR(4) NOT NULL,
  FOREIGN KEY (pavillon, numero) REFERENCES LOCAL (pavillon, numero)
);

-- Table for ATTRIBUER
CREATE TABLE ATTRIBUER (
  pavillon VARCHAR(2) NOT NULL,
  numero VARCHAR(4) NOT NULL,
  id_caracteristique SMALLINT NOT NULL,
  effectif SMALLINT, -- Assuming effectif is a numeric value
  PRIMARY KEY (pavillon, numero, id_caracteristique),
  FOREIGN KEY (id_caracteristique) REFERENCES CARACTERISTIQUE (id_caracteristique),
  FOREIGN KEY (pavillon, numero) REFERENCES LOCAL (pavillon, numero)
);

-- Table for POSSEDER
CREATE TABLE POSSEDER (
  cip VARCHAR(8) NOT NULL,
  id_statut INTEGER NOT NULL, -- Changed to INTEGER
  PRIMARY KEY (cip, id_statut),
  FOREIGN KEY (id_statut) REFERENCES STATUT (id_statut),
  FOREIGN KEY (cip) REFERENCES MEMBRE (cip)
);

