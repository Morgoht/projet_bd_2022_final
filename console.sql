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
INSERT INTO projet.etudiants VALUES (DEFAULT,'Lacroix','Sasha','Sasha.Lacroix@student.vinci.be', NULL);


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
date_fin date NOT NULL CHECK (date_fin> projets.date_debut)
);

CREATE  TABLE projet.groupes(
id_groupe SERIAL PRIMARY KEY NOT NULL,
num_groupe SERIAL UNIQUE NOT NULL,
id_projet  INTEGER NOT NULL REFERENCES projet.projets(id_projet),
etat varchar(10) DEFAULT 'temporaire' NOT NULL CHECK ( etat in ('temporaire', 'définitif', 'definitif') ),
nbr_membre INTEGER NULL,
UNIQUE (id_projet, num_groupe)
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
------ insert projet ------
INSERT INTO projet.projets VALUES (DEFAULT, 2, 'clockin berlin','2022-11-28', '2022-12-25' );
INSERT INTO projet.projets VALUES (DEFAULT, 3, 'projet web2 jeux','2022-11-28', '2022-12-25' );
INSERT INTO projet.projets VALUES (DEFAULT, 4, 'projet PAE','2022-11-28', '2023-05-12' );

------- insert groupe ----------
INSERT INTO projet.groupes VALUES (DEFAULT, DEFAULT, 1, DEFAULT, 2);
INSERT INTO projet.groupes VALUES (DEFAULT, DEFAULT, 2, DEFAULT, 2);
INSERT INTO projet.groupes VALUES (DEFAULT, DEFAULT, 3, DEFAULT, 2);

/*
INSERT INTO projet.groupes VALUES (DEFAULT, DEFAULT, 2, DEFAULT, 3);
*/
------- insert inscription -------
INSERT INTO projet.inscriptions_groupe VALUES (1,1);
INSERT INTO projet.inscriptions_groupe VALUES (1,2);
INSERT INTO projet.inscriptions_groupe VALUES (2,3);
INSERT INTO projet.inscriptions_groupe VALUES (2,4);
INSERT INTO projet.inscriptions_groupe VALUES (3,5);


----------------------------------------- APP CENTRALE ----------------------------------------------
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
                                                        new_date_fin DATE) RETURNS VOID AS $$
BEGIN
    INSERT INTO projet.projets VALUES (DEFAULT,id_cours_exist, new_nom, new_date_debut, new_date_fin);
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

CREATE OR REPLACE FUNCTION projet.valider_groupe(id_projet_exist INTEGER, numero_groupe_exist INTEGER ) RETURNS VOID AS $$
    DECLARE
        nbr_inscrit INTEGER;
        id_groupe_exist INTEGER;
    BEGIN
        SELECT count(i.id_etudiant) FROM projet.groupes g, projet.inscriptions_groupe i
        WHERE g.id_groupe = numero_groupe_exist AND g.id_groupe = i.id_groupe INTO nbr_inscrit;

        SELECT g.id_groupe FROM projet.groupes g
        WHERE g.num_groupe = numero_groupe_exist AND g.id_projet = id_projet_exist INTO id_groupe_exist;

        IF (SELECT g.nbr_membre FROM projet.groupes g WHERE g.id_groupe = id_groupe_exist ) <> nbr_inscrit
        THEN RAISE EXCEPTION 'pas complet';
        ELSE
            UPDATE projet.groupes
            SET etat = 'définitif'
            WHERE id_groupe = id_groupe_exist ;
        END IF;
    end;


    $$ LANGUAGE plpgsql;


-------------------VUE------------------------

CREATE OR REPLACE VIEW projet.vue_cours AS
    SELECT c.id_cours, c.nom, COALESCE( string_agg(p.id_projet::varchar, ', '),'pas encore de projet')
    FROM projet.cours c LEFT OUTER JOIN projet.projets p ON c.id_cours = p.id_cours
    group by c.id_cours, c.nom;

CREATE OR REPLACE VIEW projet.vue_projets AS
SELECT DISTINCT  p.id_projet, p.nom, p.id_cours,  COUNT(g.id_groupe) AS "nombre de groupe",
                count(g.etat) filter ( where g.etat = 'définitif' ) AS "groupe complet"
FROM projet.cours c LEFT OUTER JOIN projet.projets p ON c.id_cours = p.id_projet LEFT OUTER JOIN projet.groupes g ON p.id_projet = g.id_projet
    LEFT OUTER JOIN projet.inscriptions_groupe i ON g.id_groupe = i.id_groupe
WHERE p.id_projet IS NOT NULL
group by p.id_cours, p.id_projet, p.nom, p.id_cours, i.id_etudiant, g.etat;

CREATE OR REPLACE  VIEW projet.vue_groupe_projet AS
    SELECT  g.num_groupe as Numéro, e.nom, e.prenom, g.etat AS "validé ?",
    CASE WHEN g.etat = 'définitif' THEN 'Vrai' ELSE 'False' END "Validé",
    CASE WHEN count(i.id_etudiant) = g.nbr_membre THEN 'True' ELSE 'False' END "Complet"
    FROM projet.projets p, projet.groupes g, projet.etudiants e, projet.inscriptions_groupe i, projet.inscriptions_groupe i2
    WHERE p.id_projet = g.id_projet AND g.id_groupe = i.id_groupe
        AND i.id_etudiant = e.id_etudiant AND i.id_groupe = i2.id_groupe
    GROUP BY g.num_groupe, e.nom, e.prenom, g.etat, g.nbr_membre;





/*
SELECT * FROM projet.vue_groupe_projet;
SELECT * FROM projet.groupes WHERE id_groupe = 1;
SELECT * FROM projet.groupes g WHERE g.etat = 'définitif';
SELECT DISTINCT * FROM projet.vue_projets;
SELECT * FROM projet.vue_cours;
SELECT * FROM projet.projets;
*/







--------------------- Appel de procédure --------------------
/*
SELECT projet.valider_groupe(1,1);
SELECT projet.ajouter_groupe_projet(2,1,3);
SELECT projet.ajouter_cours('test','BINV1112','1',1);
SELECT projet.ajouter_cours('NeuroPsy','BINV2103','2',4);
SELECT projet.ajouter_etudiant('Test','Arnaud', 'test.arnaud@student.vinci.be');
SELECT projet.inscription_cours(1,1);
SELECT projet.ajouter_projet_cours(1,'test projet de cours 1', date(now()),'2022-12-25');
SELECT projet.ajouter_projet_cours(1,'test projet de cours 2', date(now()),'2022-12-25');
*/
--------------------- REQUÊTES -------------------
/*
SELECT c.id_cours FROM projet.cours c;
SELECT c.* FROM projet.cours c;
SELECT e.id_etudiant FROM projet.etudiants e;
SELECT c.id_cours, c.nom FROM projet.cours c;
SELECT * FROM projet.projets;
*/


