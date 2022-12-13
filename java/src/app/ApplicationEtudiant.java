package app;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;


public class ApplicationEtudiant {

    private String url = "jdbc:postgresql://localhost:5432/projetbd_final";
    private Connection conn=null;
    private PreparedStatement afficherCours, ajouterEtudiantGroupe, retirerGroupe, afficherProjet, get_id,
                              afficherProjetSansGroupe, afficherGroupeIncomplet, Get_id_groupe, checkLogin;
    private String loginUser;
    public Scanner scanner = new Scanner(System.in);
    private String user = "postgres";
    private String motDePasse = "JoRxM3ZXEP";
    private int idEtudiant;




    //private String url = "jdbc:postgresql://172.24.2.6:5432/dbalexandretouat";
    //private String user = "alexandretouat";
    //private String motDePasse = "TOBALQZ4Y";






    public ApplicationEtudiant(){
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn = DriverManager.getConnection(url, user, motDePasse);
        } catch (SQLException e) {
            e.printStackTrace();
            System.out.println("Impossible de joindre le server!");
            System.exit(1);
        }
        try {
            afficherCours = conn.prepareStatement("SELECT * FROM projet.afficher_cours WHERE id_etudiant = ?;");
            ajouterEtudiantGroupe = conn.prepareStatement("SELECT projet.ajouter_etudiant_groupe(?,?,?)");
            retirerGroupe = conn.prepareStatement("SELECT projet.retirer_groupe(?,?)");
            afficherProjet = conn.prepareStatement("SELECT * FROM projet.afficher_projets WHERE id_etudiant = ?;");
            afficherProjetSansGroupe = conn.prepareStatement("SELECT * FROM projet.afficher_projets_sans_groupe WHERE id_etudiant = ?;");
            afficherGroupeIncomplet = conn.prepareStatement("SELECT * FROM projet.afficher_projets WHERE id_projet = ?;");
            Get_id_groupe = conn.prepareStatement("SELECT * FROM projet.get_id_groupe WHERE numerogroupe = ?");
            checkLogin = conn.prepareStatement("SELECT projet.check_login(?)");
            get_id = conn.prepareStatement("SELECT projet.get_id(?)");
        }catch (SQLException throwables) {
            throwables.printStackTrace();
        }
    }
    public boolean authentification() {
        String login;
        String mdpInput;
        String mdp="";

        try{
            System.out.println("Se connecter");
            System.out.println("Entre l'email de l'utilisateur");
            login = scanner.nextLine();
            System.out.println("Entrez le mot de passse");
            mdpInput = scanner.nextLine();
            loginUser = login;
            checkLogin.setString(1,login);
            ResultSet etudiantMdp = checkLogin.executeQuery();
            while(etudiantMdp.next()) {
                mdp = etudiantMdp.getString(1);
            }

            if(BCrypt.checkpw(mdpInput,mdp)) {
                get_id.setString(1, login);
                ResultSet rs = get_id.executeQuery();
                while (rs.next()){
                    idEtudiant = rs.getInt(1);
                }
                return true;

            }

        }catch(SQLException e){
            System.out.println(e.getMessage());
        }
        return false;
    }
    public void quitter() {
        try {
            conn.close();
            System.out.println("Au revoir et merci d'avoir utilise l'application.");
            System.exit(0);
        } catch (SQLException e) {
            System.out.println("Erreur lors de la fermeture de la connection a�la DB.");
            System.out.println(e.getMessage());
        }
    }
    public String menu() {
        return "1 : visualiser les cours.\n"
            +"2 : Se rajouter dans un groupe.\n"
            +"3 : Se retirer d'un groupe.\n"
            +"4 : Visualiser les projets disponible.\n"
            +"5 : Visualiser les projets sans groupe.\n"
            +"6 : Visualiser les compositions de groupes icompllets d'un projet. \n"
            + "0 : quitter l'app.";
    }

    public void afficherCours() {
        try{
            System.out.println("Mes cours : \n");
            afficherCours.setInt(1, idEtudiant);
            try (ResultSet rs=afficherCours.executeQuery()) {
                while(rs.next()) {
                    System.out.println( " | Code du cours : " + rs.getString(1) +
                            " | Nom : " + rs.getString(2) + " | Projets : " +  rs.getString(3));
                }
            }
        }catch (SQLException se) {
            System.out.println("Erreur lors de la recherche ou de l'affichage des ressources!");
            se.printStackTrace();
        }
    }

    public void ajouterEtudiantGroupe() {
        scanner.nextLine();
        try{
            System.out.println("Entrez l'id du projet : ");
            String id = scanner.nextLine();
            System.out.println("Entrez le numero du groupe : ");
            int numero = scanner.nextInt();

            ajouterEtudiantGroupe.setString(1, id);
            ajouterEtudiantGroupe.setInt(2, numero);
            ajouterEtudiantGroupe.setInt(3, idEtudiant);
            ajouterEtudiantGroupe.executeQuery();
            System.out.println("Le rajout de l'étudiant a bien été fait");
        }catch (SQLException se) {
            System.out.println("Erreur lors du rajouter de l'étudiant à un groupe");
            se.printStackTrace();
        }
    }

    public void retirerGroupe() {
        scanner.nextLine();
        try{
            System.out.println("Entrez l'id du projet : ");
            String id_projet = scanner.nextLine();
            retirerGroupe.setString(1, id_projet);
            retirerGroupe.setInt(2, idEtudiant);
            retirerGroupe.executeQuery();
            System.out.println("L'étudiant a bien été retirer du groupe.");
        }catch (SQLException se) {
            System.out.println("Erreur lors du retirement de l'étudiant du groupe!");
            se.printStackTrace();
        }
    }

    public void afficherProjet() {
        try{
            System.out.println("La liste de vos projet : \n");
            afficherProjet.setInt(1, idEtudiant);
            try (ResultSet rs=afficherProjet.executeQuery()) {
                while(rs.next()) {
                    System.out.println( " ID du projet : " + rs.getString(1) +
                            " | Nom : " + rs.getString(2) + " | Id du cours : " +  rs.getInt(3)
                            + " | Groupe numéro : " +  rs.getInt(4));
                }
            }
        }catch (SQLException se) {
            System.out.println("Erreur lors de l'affichage !");
            se.printStackTrace();
            System.exit(1);
        }
    }

    public void afficherProjetSansGroupe() {
        try{
            System.out.println("La liste des projets : \n");
            afficherProjetSansGroupe.setInt(1, idEtudiant);
            try (ResultSet rs=afficherProjetSansGroupe.executeQuery()) {
                while(rs.next()) {
                    System.out.println( " ID du projet : " + rs.getString(1) +
                            " | Nom : " + rs.getString(2) + " | Id du cours : " +  rs.getInt(3)
                            + " | Date début : " +  rs.getDate(4) + " | Date fin : " +  rs.getDate(4));
                }
            }
        }catch (SQLException se) {
            System.out.println("Erreur lors de la recherche ou de l'affichage des ressources!");
            se.printStackTrace();
        }
    }


    public void afficherGroupeIncomplet() {
        try{
            System.out.println("Entrez l'id du projet : ");
            String id_projet = scanner.nextLine();
            System.out.println("La liste des groupes incomplet : \n");
            afficherGroupeIncomplet.setString(1, id_projet);
            try (ResultSet rs=afficherGroupeIncomplet.executeQuery()) {
                while(rs.next()) {
                    System.out.println( "  Numéro groupe : " + rs.getInt(1) +
                            " | Nom : " + rs.getString(2) + " | Prénom : " +  rs.getString(3)
                            + " | Nombre de places : " +  rs.getInt(4));
                }
            }
        }catch (SQLException se) {
            System.out.println("Erreur lors de la recherche ou de l'affichage des ressources!");
            se.printStackTrace();
        }
    }

    public void close() {
        try {
            this.conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

}
