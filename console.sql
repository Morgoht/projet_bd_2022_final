DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;
---------------------- CREATE TABLE -----------------------------
CREATE TABLE projet.etudiants(
id_etudiant SERIAL          PRIMARY KEY NOT NULL ,
nom varchar(20)             NOT NULL ,
prenom varchar(20)          NOT NULL ,
email varchar(60)           UNIQUE NOT NULL     CHECK (email LIKE '%@student.vinci.be'),
mot_de_passe varchar(60)    NULL
);


CREATE TABLE projet.cours(
id_cours SERIAL             PRIMARY KEY NOT NULL,
nom varchar(20)             NOT NULL,
code_cours varchar(10)      NOT NULL CHECK ( code_cours SIMILAR TO 'BINV[0-9][0-9][0-9][0-9]'),
bloc char                   NOT NULL CHECK ( bloc IN ('1','2','3') ),
nbr_credit INTEGER NOT NULL
);
CREATE TABLE projet.projets(
id_projet varchar(10) PRIMARY KEY NOT NULL,
id_cours INTEGER NOT NULL REFERENCES projet.cours(id_cours),
nom varchar(30) NOT NULL,
date_debut date NOT NULL CHECK ( date_debut >= date(now())-1 ), --format de date default => aaaa-mm-jj--
date_fin date NOT NULL CHECK (date_fin> projets.date_debut)
);

CREATE  TABLE projet.groupes(
id_groupe SERIAL PRIMARY KEY NOT NULL,
num_groupe SERIAL UNIQUE NOT NULL,
id_projet  VARCHAR NOT NULL REFERENCES projet.projets(id_projet),
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
    id_etudiant INTEGER NOT NULL REFERENCES projet.etudiants(id_etudiant));
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
CREATE OR REPLACE  FUNCTION projet.ajouter_etudiant(new_nom varchar(20), new_prenom varchar(20), new_adresse_mail varchar(60), new_mot_de_passe varchar(50))
RETURNS INTEGER AS $$
    DECLARE
        id INTEGER;
    BEGIN
        INSERT INTO projet.etudiants VALUES (DEFAULT, new_nom, new_prenom, new_adresse_mail, new_mot_de_passe);
        SELECT e.id_etudiant FROM projet.etudiants e WHERE e.email = new_adresse_mail INTO id;
    RETURN id;
END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.inscription_cours(code_cours_exist varchar, email_etudiant_exist varchar)
RETURNS VOID AS $$
    DECLARE
        id_cours_exist INTEGER;
        id_etudiant_exist INTEGER;
    BEGIN
        SELECT c.id_cours FROM projet.cours c WHERE c.code_cours = code_cours_exist INTO id_cours_exist;
        SELECT e.id_etudiant FROM projet.etudiants e WHERE e.email = email_etudiant_exist INTO id_etudiant_exist;
        IF (SELECT COUNT(p.id_projet) FROM projet.projets p WHERE p.id_cours = id_cours_exist) > 0
            THEN RAISE 'projet déja existant dans ce cours';
        END IF;
        INSERT INTO projet.inscriptions_cours VALUES (id_cours_exist,id_etudiant_exist);
    END;
    $$LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION projet.ajouter_projet_cours(new_id_projet varchar,code_cours_exist varchar , new_nom varchar(20), new_date_debut DATE,
                                                        new_date_fin DATE) RETURNS VOID AS $$
    DECLARE
        id_cours_exist INTEGER;
    BEGIN
        SELECT c.id_cours FROM projet.cours c WHERE c.code_cours = code_cours_exist INTO id_cours_exist;
        INSERT INTO projet.projets VALUES (new_id_projet,id_cours_exist, new_nom, new_date_debut, new_date_fin);
    END;
$$LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION projet.ajouter_groupe_projet(id_projet_exist varchar, new_nbr_groupe INTEGER, new_nbr_membre INTEGER ) RETURNS VOID AS $$
    DECLARE
        i INTEGER := new_nbr_groupe;

        place_groupe INTEGER;
        etudiant_inscrit INTEGER;
    BEGIN
        SELECT SUM(g.nbr_membre) FROM projet.groupes g WHERE g.id_projet = id_projet_exist INTO place_groupe;
        IF(place_groupe IS NULL) THEN place_groupe:= 0; END IF;
        SELECT count(i.id_etudiant)
        FROM projet.etudiants e, projet.cours c , projet.projets p, projet.inscriptions_cours i
        WHERE p.id_projet = id_projet_exist AND p.id_cours = c.id_cours AND i.id_cours = c.id_cours AND
              e.id_etudiant = i.id_etudiant INTO etudiant_inscrit;

        if(etudiant_inscrit < ((new_nbr_groupe * new_nbr_membre) + place_groupe ))
        THEN RAISE EXCEPTION 'pas assez d inscriptions';
        END IF;
        WHILE i>0 LOOP
            INSERT INTO projet.groupes VALUES (DEFAULT,DEFAULT, id_projet_exist,DEFAULT,new_nbr_membre );
            i:= i-1;
        END LOOP;
    END
    $$LANGUAGE plpgsql;
(SELECT SUM(g.nbr_membre) FROM projet.groupes g WHERE g.id_projet = 'projSD');
SELECT count(i.id_etudiant)
        FROM projet.etudiants e, projet.cours c , projet.projets p, projet.inscriptions_cours i
        WHERE p.id_projet = 'projSD' AND
              p.id_cours = c.id_cours AND i.id_cours = c.id_cours AND
              e.id_etudiant = i.id_etudiant;


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

CREATE OR REPLACE FUNCTION projet.valider_tous_les_groupes(id_projet_exist INTEGER) RETURNS VOID AS $$

    BEGIN
        IF (SELECT DISTINCT g.id_groupe FROM projet.groupes g, projet.inscriptions_groupe i
            WHERE i.id_groupe = g.id_groupe AND g.nbr_membre != (SELECT count(i.id_etudiant) FROM projet.inscriptions_groupe i WHERE i.id_groupe = g.id_groupe )
            group by g.id_groupe) > 0
        THEN
            RAISE EXCEPTION 'groupe incomplet';
        ELSE
            UPDATE projet.groupes SET etat = 'définitif' WHERE id_projet = id_projet_exist;
        END IF;
    END ;

    $$ LANGUAGE plpgsql;


-------------------VUE------------------------

CREATE OR REPLACE VIEW projet.vue_cours AS
    SELECT c.id_cours, c.nom, COALESCE( string_agg(p.id_projet::varchar, ', '),'pas encore de projet') AS "projet en cours"
    FROM projet.cours c LEFT OUTER JOIN projet.projets p ON c.id_cours = p.id_cours
    group by c.id_cours, c.nom;

CREATE OR REPLACE VIEW projet.vue_projets AS
SELECT DISTINCT  p.id_projet, p.nom, p.id_cours,  COUNT(g.id_groupe) AS "nombre de groupe",
                count(g.etat) filter ( where g.etat = 'définitif' ) AS "groupe complet"
FROM projet.cours c LEFT OUTER JOIN projet.projets p ON c.id_cours = p.id_cours LEFT OUTER JOIN projet.groupes g ON p.id_projet = g.id_projet
    LEFT OUTER JOIN projet.inscriptions_groupe i ON g.id_groupe = i.id_groupe
WHERE p.id_projet IS NOT NULL
group by p.id_cours, p.id_projet, p.nom, p.id_cours, i.id_etudiant, g.etat;

CREATE OR REPLACE  VIEW projet.vue_groupe_projet AS
    SELECT  p.id_projet,  g.num_groupe as Numéro, e.nom, e.prenom,
    CASE WHEN g.etat = 'définitif' THEN 'Vrai' ELSE 'False' END "Validé",
    CASE WHEN count(i.id_etudiant) = g.nbr_membre THEN 'True' ELSE 'False' END "Complet"
    FROM projet.projets p, projet.groupes g, projet.etudiants e, projet.inscriptions_groupe i, projet.inscriptions_groupe i2
    WHERE p.id_projet = g.id_projet AND g.id_groupe = i.id_groupe
        AND i.id_etudiant = e.id_etudiant AND i.id_groupe = i2.id_groupe
    GROUP BY p.id_projet, g.num_groupe, e.nom, e.prenom, g.etat, g.nbr_membre
    ORDER BY g.num_groupe;

----------------------------------------APP ETUDIANTE ---------------------------------
CREATE VIEW projet.afficher_cours AS
    SELECT c.code_cours, c.nom, p.id_projet, e.id_etudiant
    FROM projet.projets p, projet.cours c,
         projet.inscriptions_cours ic, projet.etudiants e
    WHERE ic.id_cours = c.id_cours AND ic.id_etudiant = e.id_etudiant AND p.id_cours = c.id_cours;

CREATE OR REPLACE FUNCTION projet.ajouter_etudiant_groupe(new_id_projet varchar, new_numero_groupe  INTEGER, new_id_etudiant INTEGER) RETURNS VOID AS $$
DECLARE
    _id_groupe INTEGER := 0;
    _nbr_membre INTEGER := 1;
    _nbr_inscrit INTEGER;

BEGIN
    -- assigner les variables locales
    SELECT count(i.id_etudiant) FROM projet.groupes g, projet.inscriptions_groupe i WHERE g.id_projet = new_id_projet AND g.id_groupe = new_numero_groupe AND i.id_groupe = new_numero_groupe INTO _nbr_inscrit;
    SELECT id_groupe FROM groupes WHERE num_groupe = new_numero_groupe INTO _id_groupe;

    -- vérif si l'etudiant est inscrit d'abord vérifier ça
    IF (SELECT p.id_cours
        FROM projets p
        WHERE p.id_projet = new_id_projet)
        NOT IN (SELECT ic.id_cours
                FROM inscriptions_cours ic
                WHERE ic.id_etudiant = new_id_etudiant)
    THEN RAISE 'm etudiant n est pas inscrit au cours';
    END IF;
    --prends le nombre d'inscirs dans ce groupe
    -- si le groupe est validé ou complet on lève une exception
    IF (_nbr_inscrit = (SELECT g FROM projet.groupes g WHERE g.id_groupe and g.id_projet = new_id_projet))
        THEN RAISE 'Le groupe n a plus de place';
    END IF;



    INSERT INTO projet.inscriptions_groupe
    VALUES (_id_groupe, new_id_etudiant);

    UPDATE groupes SET nbr_membre = nbr_membre + _nbr_membre
    WHERE id_groupe = _id_groupe;
END
$$ LANGUAGE plpgsql;

---

CREATE OR REPLACE FUNCTION projet.retirer_groupe(new_id_projet INTEGER, new_id_etudiant INTEGER) RETURNS VOID AS $$
DECLARE
    _id_groupe INTEGER := 0;
    _nbr_membre_moins INTEGER := 1;
BEGIN
    IF  NOT EXISTS(SELECT g.id_groupe
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
    IF EXISTS(SELECT *
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

---

CREATE VIEW projet.afficher_projets AS
    SELECT p.id_projet, p.nom, c.id_cours, g.num_groupe, e.id_etudiant

    FROM projet.projets p, projet.cours c, projet.groupes g, projet.inscriptions_groupe ig,
         projet.inscriptions_cours ic, projet.etudiants e

    WHERE ic.id_cours = c.id_cours AND ic.id_etudiant = e.id_etudiant AND p.id_cours = c.id_cours;

SELECT id_projet, nom, id_cours, num_groupe
FROM projet.afficher_projets
WHERE id_etudiant = 1;

---

CREATE VIEW projet.afficher_projets_sans_groupe AS
    SELECT p.id_projet, p.nom, c.id_cours, p.date_debut, p.date_fin, e.id_etudiant

    FROM projet.projets p, projet.cours c, projet.groupes g, projet.inscriptions_groupe ig,
         projet.inscriptions_cours ic, projet.etudiants e

    WHERE ic.id_cours = c.id_cours AND ic.id_etudiant = e.id_etudiant AND p.id_cours = c.id_cours
    AND e.id_etudiant NOT IN (SELECT ig.id_etudiant
                                FROM projet.inscriptions_groupe ig, projet.groupes g
                                WHERE ig.id_groupe = g.id_groupe AND g.id_projet = p.id_projet);

SELECT id_projet, nom, id_cours, date_debut, date_fin
FROM projet.afficher_projets_sans_groupe
WHERE id_etudiant = 1;


CREATE VIEW projet.afficher_groupes_incomplets AS
    SELECT g.num_groupe, e.nom, e.prenom, count(ig.id_etudiant) as "inscrit"
    FROM projet.groupes g, projet.etudiants e, projet.inscriptions_groupe ig
    WHERE ig.id_etudiant = e.id_etudiant AND ig.id_groupe = g.id_groupe
    GROUP BY g.num_groupe, e.nom, e.prenom;


CREATE OR REPLACE  FUNCTION projet.get_id(email_etudiant_exist VARCHAR) RETURNS TABLE(id INTEGER) AS $$
    BEGIN
    RETURN QUERY SELECT  e.id_etudiant FROM projet.etudiants e WHERE e.email = email_etudiant_exist;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE  FUNCTION projet.check_login(email_etudiant_exist VARCHAR) RETURNS TABLE(mdp VARCHAR) AS $$
    BEGIN
    RETURN QUERY SELECT  e.mot_de_passe FROM projet.etudiants e WHERE e.email = email_etudiant_exist;
END;
$$ LANGUAGE plpgsql;

SELECT projet.get_id('cd@student.vinci.be');
SELECT projet.check_login('ic@student.vinci.be');
------------------- INSERT DEMO -----------------------
CREATE OR REPLACE FUNCTION projet.demo_projet_init() RETURNS VOID AS $$
    BEGIN
                ------------Cours----------
        INSERT INTO projet.cours VALUES (DEFAULT, 'BD2', 'BINV2040', '2', 6);
        INSERT INTO projet.cours VALUES (DEFAULT, 'APOO', 'BINV1020', '1', 6);                ------------Etudiants---------            ------------Etudiants---------
        INSERT INTO projet.etudiants VALUES(DEFAULT,'Damas','Christophe', 'cd@student.vinci.be');
        INSERT INTO projet.etudiants VALUES(DEFAULT,'Fenneeuw','Stéphanie', 'sf@student.vinci.be');
        INSERT INTO projet.etudiants VALUES(DEFAULT,'Damas','Christophe', 'cd@student.vinci.be');
                -----------Inscriptions cours ------------
        INSERT INTO projet.inscriptions_cours VALUES (1,1);
        INSERT INTO projet.inscriptions_cours VALUES (1,2);
                ------------Projet cours ------------
        INSERT INTO projet.projets VALUES ('projSQL', 1,'projet SQL','2023-09-10','2023-12-15');
        INSERT INTO projet.projets VALUES ('dsd', 1,'DSD','2023-09-30','2023-12-1');
                -----------Groupe projet ------------
        INSERT INTO projet.groupes VALUES (DEFAULT, DEFAULT, 'projSQL', DEFAULT, 2);
    end;
    $$ LANGUAGE plpgsql;

SELECT projet.demo_projet_init();


--Grants
/*
GRANT CONNECT ON DATABASE postgres TO alexandretouat;
GRANT USAGE ON SCHEMA projet TO alexandretouat ;

GRANT SELECT ON projet.etudiants,projet.cours, projet.projets,projet.groupes, projet.inscriptions_groupe, projet.inscriptions_cours TO alexandretouat;
GRANT INSERT ON projet.inscriptions_groupe TO alexandretouat;
GRANT DELETE ON projet.inscriptions_groupe TO alexandretouat;

 */
