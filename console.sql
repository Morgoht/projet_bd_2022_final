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
nbr_groupe INTEGER NOT NULL

);

CREATE TABLE projet.groupes(
id_groupe SERIAL PRIMARY KEY NOT NULL,
numero_groupe INTEGER NOT NULL UNIQUE,
id_projet  INTEGER NOT NULL REFERENCES projet.projets(id_projet),
etat varchar NOT NULL CHECK ( etat in ('temporaire', 'définitif', 'definitif') ),
nbr_membre INTEGER NULL,
nbr_place_groupe INTEGER NOT NULL

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
        INSERT INTO projet.inscriptions_cours VALUES (new_id_cours, new_id_etudiant);
        SELECT ic.id_etudiant, ic.id_cours FROM projet.inscriptions_cours ic
        WHERE ic.id_cours = new_id_cours AND ic.id_etudiant = new_id_etudiant;


    END;
    $$LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION projet.ajouter_projet_cours(id_cours INTEGER, nom varchar(20), date_debut DATE,
                                                        date_fin DATE, nbr_groupe INTEGER, nbr_place_groupe INTEGER ) RETURNS VOID AS $$
BEGIN
    INSERT INTO projet.projets VALUES (DEFAULT,id_cours, nom,date_debut, date_fin, nbr_groupe, nbr_place_groupe);
END;
$$LANGUAGE plpgsql;

CREATE VIEW projet.afficher_cours AS --application etudiant 
SELECT c.code_cours, c.nom, p.id_projet
FROM cours c, projets p, etudiants e, inscription_cours ic

WHERE (ic.id_cours = c.id_cours AND ic.id_etudiant = e.id_etudiant);

--AND c.id_cours NOT IN (SELECT p.id_cours FROM projets p)

CREATE OR REPLACE FUNCTION projet.ajouter_etudiant_groupe(new_id_projet, new_numero_groupe, new_id_etudiant) RETURN VOID AS $$ --application etudiant
DECLARE
    _id_groupe INTEGER := 0;
    _nbr_membre INTEGER := 1;
BEGIN
    IF new_numero_groupe NOT IN (SELECT g.numero_groupe
                                 FROM groupes g
                                 WHERE g.nbr_place_groupe != g.nbr_membre)
    THEN RAISE data_exception;
    END IF;
    IF (SELECT p.id_cours 
        FROM projets p 
        WHERE p.id_projet = new_id_projet)
        NOT IN (SELECT ic.id_cours
                FROM inscriptions_cours ic
                WHERE ic.id_etudiant = new_id_etudiant)
    THEN RAISE data_exception;
    END IF;
    SELECT id_groupe
            FROM groupes
            WHERE numero_groupe = new_numero_groupe
            INTO _id_groupe;

    INSERT INTO projet.inscriptions_groupe
    VALUES (_id_groupe, new_id_etudiant);

    UPDATE groupe SET nbr_membre = nbr_membre + _nbr_membre 
    WHERE id_groupe = _id_groupe;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.retirer_groupe(new_id_projet, new_id_etudiant) RETURN VOID AS $$ --application etudiant
DECLARE 
    _id_groupe INTEGER := 0;
    _nbr_membre_moins := 1;
BEGIN 
    IF  NOT EXIST ( SELECT g.id_groupe
        FROM groupes g, inscriptions_groupe ic
        WHERE ic.id_etudiant = new_id_etudiant 
        AND ic.id_groupe = g.id_groupe 
        AND g.id_projet = new_id_projet)
    THEN 
        RAISE data_exception;
    END IF;
    SELECT g.id_groupe
        FROM groupes g, inscriptions_groupe ic
        WHERE ic.id_etudiant = new_id_etudiant 
        AND ic.id_groupe = g.id_groupe 
        AND g.id_projet = new_id_projet
        INTO _id_groupe;
    IF EXIST(SELECT *
             FROM groupes 
             WHERE id_groupe = _id_groupe
             AND etat = 'définitif' OR etat = 'definitif' )
    THEN 
        RAISE 'Ce groupe est déjà validé';
    END IF;
    
    DELETE FROM inscriptions_groupe WHERE id_groupe = _id_groupe AND id_etudiant= new_id_etudiant;
    UPDATE groupes SET nbr_membre = nbr_membre - _nbr_membre_moins;
END 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.afficher_projets(new_id_etudiant) RETURNS TABLE --application etudiant 
AS
RETURN
    SELECT p.id_projet, p.nom, c.id_cours, g.numero_groupe

    FROM projets p, cours c, groupe g, inscriptions_groupe ig, inscriptions_cours ic

    WHERE ic.id_cours = c.id_cours AND ic.id_etudiant = new_id_etudiant AND p.id_cours = c.id_cours;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION projet.afficher_projets_sans_groupe(new_id_etudiant) RETURNS TABLE --application etudiant 
AS
RETURN
    SELECT p.id_projet, p.nom, c.id_cours, p.date_debut, p.date_fin

    FROM projets p, cours c, groupe g, inscriptions_groupe ig, inscriptions_cours ic

    WHERE ic.id_cours = c.id_cours AND ic.id_etudiant = new_id_etudiant AND p.id_cours = c.id_cours
    AND new_id_etudiant NOT IN (SELECT ig.id_etudiant 
                                FROM inscriptions_groupe ig, groupes g WHERE ig.id_groupe = g.id_groupe AND g.id_projet = p.id_projet)
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.afficher_groupes_incomplet(new_id_projet) RETURNS TABLE --application etudiant 
AS
RETURN
    SELECT g.numero_groupe, e.nom, e.prenom, g.nbr_place_groupe 
    FROM groupe g, etudiants e, inscriptions_groupe ig
    WHERE ig.id_etudiant = e.id_etudiant AND ig.id_groupe = g.id_groupe AND g.id_projet = new_id_projet AND g.nbr_place_groupe > 0;
END
$$ LANGUAGE plpgsql;



--------------------- Appel de procédure ---------------------
SELECT projet.ajouter_cours('test','BINV1112','1',1);
SELECT projet.ajouter_etudiant('Test','Arnaud', 'test.arnaud@student.vinci.be');
SELECT projet.inscription_cours(1,1);
SELECT projet.ajouter_projet_cours(1,'test projet de cours 1', '2022-11-16','2022-12-25',7,3);
--------------------- REQUÊTES -------------------
SELECT c.id_cours FROM projet.cours c WHERE c.code_cours = code_cours;
SELECT c.* FROM projet.cours c;
SELECT e.id_etudiant FROM projet.etudiants e;
SELECT c.id_cours, c.nom FROM projet.cours c;
SELECT * FROM projet.projets;