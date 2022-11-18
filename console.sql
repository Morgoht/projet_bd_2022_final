DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;
---------------------- CREATE TABLE -----------------------------
CREATE TABLE projet.etudiants(
id_etudiant SERIAL          PRIMARY KEY NOT NULL ,
nom varchar(20)             NOT NULL ,
prenom varchar(20)          NOT NULL ,
email varchar(40)           UNIQUE NOT NULL     CHECK (email LIKE '%@student.vinci.be'),
mot_de_passe varchar(40)    NULL
);


CREATE TABLE projet.cours(
id_cours SERIAL             PRIMARY KEY NOT NULL,
nom varchar(20)             NOT NULL,
code_cours varchar(10)      NOT NULL CHECK ( code_cours SIMILAR TO 'BINV[0-9][0-9][0-9][0-9]'),
bloc char                   NOT NULL CHECK ( bloc IN ('1','2','3') ),
nbr_credit INTEGER NOT NULL
);
CREATE TABLE projet.projets(
id_projet SERIAL PRIMARY KEY NOT NULL,
id_cours INTEGER NOT NULL REFERENCES projet.cours(id_cours),
nom varchar(30) NOT NULL,
date_debut date NOT NULL CHECK ( date_debut >= date(now())-1 ), --format de date default => aaaa-mm-jj--
date_fin date NOT NULL CHECK (date_fin> projets.date_debut) ,
nbr_groupe INTEGER NOT NULL,
nbr_places_groupe INTEGER NOT NULL
);

CREATE  TABLE projet.groupes(
id_groupe SERIAL PRIMARY KEY NOT NULL,
num_groupe SERIAL UNIQUE NOT NULL,
num_projet  INTEGER NOT NULL REFERENCES projet.projets(id_projet),
etat varchar(10) DEFAULT 'temporaire' NOT NULL CHECK ( etat in ('temporaire', 'définitif', 'definitif') ),
nbr_membre INTEGER NULL,
UNIQUE (num_projet, num_groupe)
);
CREATE TABLE projet.inscriptions_groupe(
id_groupe INTEGER NOT NULL REFERENCES projet.groupes(id_groupe),
id_etudiant INTEGER NOT NULL REFERENCES projet.etudiants(id_etudiant),
PRIMARY KEY (id_groupe, id_etudiant)
);
CREATE TABLE projet.inscriptions_cours(
    id_cours INTEGER NOT NULL REFERENCES projet.cours(id_cours),
    id_etudiant INTEGER NOT NULL REFERENCES projet.etudiants(id_etudiant)
);
---------------------   INSERTS   ---------------------
------ insert etudiant -----
INSERT INTO projet.etudiants VALUES (DEFAULT, 'Andrade', 'Amaury', 'amaury.andrade@student.vinci.be', NULL  );
INSERT INTO projet.etudiants VALUES (DEFAULT, 'Touat', 'Alexandre', 'alexandre.touat@student.vinci.be', NULL  );
INSERT INTO projet.etudiants VALUES (DEFAULT, 'Martino', 'Raphael', 'raphael.martino@student.vinci.be', NULL  );
INSERT INTO projet.etudiants VALUES (DEFAULT, 'Lacroix', 'Sasha', 'sasha.lacroix@student.vinci.be', NULL  );
INSERT INTO projet.etudiants VALUES (DEFAULT, 'Delphine', 'Biroute', 'delphine.biroute@student.vinci.be', NULL  );

------ insert cours -----
INSERT INTO projet.cours VALUES (DEFAULT, 'web1', 'BINV1101', '1', 6);
INSERT INTO projet.cours VALUES (DEFAULT, 'algo1', 'BINV1201', '1',4 );
INSERT INTO projet.cours VALUES (DEFAULT, 'web2', 'BINV2011', '2', 6);
INSERT INTO projet.cours VALUES (DEFAULT, 'pae', 'BINV2305', '2', 10);
------ insert


CREATE OR REPLACE FUNCTION projet.ajouter_cours (new_nom varchar(20),new_code_cours varchar(20), new_bloc char, new_credit INTEGER) RETURNS INTEGER AS $$
    DECLARE
        id INTEGER;
    BEGIN
        INSERT INTO projet.cours VALUES (DEFAULT, new_nom, new_code_cours, new_bloc, new_credit );
        SELECT c.id_cours FROM projet.cours c WHERE c.code_cours = code_cours INTO id;
    RETURN id;
    END;
    $$ LANGUAGE plpgsql;
-----
CREATE OR REPLACE  FUNCTION projet.ajouter_etudiant(new_nom varchar(20), new_prenom varchar(20), new_adresse_mail varchar(50))
RETURNS INTEGER AS $$
    DECLARE
        id INTEGER;
    BEGIN
        INSERT INTO projet.etudiants VALUES (DEFAULT, new_nom, new_prenom, new_adresse_mail, NULL);
        SELECT e.id_etudiant FROM projet.etudiants e WHERE e.email = new_adresse_mail INTO id;
    RETURN id;
END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.inscription_cours(new_id_cours INTEGER, new_id_etudiant INTEGER)
RETURNS VOID AS $$

    BEGIN
        INSERT INTO projet.inscriptions_cours VALUES (new_id_cours,new_id_etudiant);
    END;
    $$LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION projet.ajouter_projet_cours(id_cours_exist INTEGER, new_nom varchar(20), new_date_debut DATE,
                                                        new_date_fin DATE, new_nbr_groupe INTEGER, new_nbr_place_groupe INTEGER ) RETURNS VOID AS $$
BEGIN
    INSERT INTO projet.projets VALUES (DEFAULT,id_cours_exist, new_nom, new_date_debut, new_date_fin, new_nbr_groupe, new_nbr_place_groupe );
END;
$$LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.ajouter_groupe_projet(id_projet_exist INTEGER, new_nbr_groupe INTEGER, new_nbr_membre INTEGER ) RETURNS VOID AS $$
    DECLARE
        i INTEGER := new_nbr_groupe;
        record RECORD;
    BEGIN
        WHILE i>0 LOOP
            INSERT INTO projet.groupes VALUES (DEFAULT,DEFAULT, id_projet_exist,DEFAULT,new_nbr_membre );
            i:= i-1;
        END LOOP;

    END;
    $$LANGUAGE plpgsql;






--------------------- Appel de procédure --------------------
SELECT projet.ajouter_cours('test','BINV1112','1',1);
SELECT projet.ajouter_etudiant('Test','Arnaud', 'test.arnaud@student.vinci.be');
SELECT projet.inscription_cours(1,1);
SELECT projet.ajouter_projet_cours(1,'test projet de cours 1', date(now()),'2022-12-25',7,3);
SELECT projet.ajouter_groupe_projet(1,4,3);

--------------------- REQUÊTES -------------------
SELECT c.id_cours FROM projet.cours c;
SELECT c.* FROM projet.cours c;
SELECT e.id_etudiant FROM projet.etudiants e;
SELECT c.id_cours, c.nom FROM projet.cours c;
SELECT * FROM projet.projets;
SELECT * FROM projet.groupes;
