DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

CREATE TABLE projet.etudiants(
id_etudiant SERIAL PRIMARY KEY NOT NULL ,
nom varchar(20) NOT NULL ,
prenom varchar(20) NOT NULL ,
email varchar(40) UNIQUE NOT NULL CHECK (email LIKE '%@student.vinci.be'),
mot_de_passe varchar(40) NULL
);


CREATE TABLE projet.cours(
id_cours SERIAL PRIMARY KEY NOT NULL,
nom varchar(20) NOT NULL,
code_cours varchar(10) NOT NULL CHECK ( code_cours SIMILAR TO 'BINV[0-9][0-9][0-9][0-9]'),
bloc char NOT NULL CHECK ( bloc IN ('1','2','3') ),
nbr_credit INTEGER NOT NULL
);
CREATE TABLE projet.projets(
id_projet SERIAL PRIMARY KEY NOT NULL,
id_cours INTEGER NOT NULL REFERENCES projet.cours(id_cours),
nom varchar(30) NOT NULL,
date_debut date NOT NULL CHECK ( date_debut >= timenow() ), --format de date default => aaaa-mm-jj--
date_fin date NOT NULL CHECK (date_fin> projets.date_debut) ,
nbr_groupe INTEGER NOT NULL,
nbr_places_groupe INTEGER NOT NULL
);

CREATE TABLE projet.groupes(
id_groupe SERIAL PRIMARY KEY NOT NULL,
num_projet  INTEGER NOT NULL REFERENCES projet.projets(id_projet),
etat varchar NOT NULL CHECK ( etat in ('temporaire', 'définitif', 'definitif') ),
nbr_membre INTEGER NULL
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

CREATE OR REPLACE FUNCTION projet.ajouter_cours (new_nom varchar(20),new_code_cours varchar(20), new_credit INTEGER, new_bloc char) RETURNS INTEGER AS $$
    DECLARE
        id INTEGER;
    BEGIN
        INSERT INTO projet.cours VALUES (DEFAULT, new_nom, new_bloc, new_code_cours, new_credit );
        SELECT c.id_cours FROM projet.cours c WHERE c.code_cours = code_cours INTO id;
    RETURN id;
    END;
    $$ LANGUAGE plpgsql;







--------------------- Appel de procédure --------------------
SELECT projet.ajouter_cours('test','BINV111',2,'1');
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
--------------------- REQUÊTES -------------------
