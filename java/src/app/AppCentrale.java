package app;

import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

/**
 * suivie du cours de Seance 8 sur la partie java
 * attribut = pStatement des requêtes + connexion db (user, mdp, db)
 *
 */
public class AppCentrale {
  PreparedStatement psAjouterCours, psAjouterEtudiant, psInscrireEtudiant, psCreerProjet, psCreerGroupe, psVisualiserCours, psVisualiserProjets,
  psVisualiserGroupes, psValiderGroupe, psValiderTousGroupe;
  private Scanner sc = new Scanner(System.in);
  private Connection conn = null;
  private String url = "jdbc:postgresql://localhost:5432/postgres";
  private String user = "postgres";
  private String password = "Scorpion666";

  public AppCentrale(){
    try {
      Class.forName("org.postgresql.Driver");
    } catch (ClassNotFoundException e) {
      System.out.println("Driver PostgreSQL manquant !");
      System.exit(1);
    }
    try {
      conn= DriverManager.getConnection (url,user, password);
    } catch (SQLException e) {
      e.printStackTrace();
      System.out.println("Impossible de joindre le server !");
      System.exit(1);
    }
    try{
      psAjouterCours = conn.prepareStatement("SELECT projet.ajouter_cours(?,?,?,?)");
      psAjouterEtudiant = conn.prepareStatement("SELECT projet.ajouter_etudiant(?,?,?,?)");
      psInscrireEtudiant = conn.prepareStatement("SELECT projet.inscription_cours(?,?)");
      psCreerProjet = conn.prepareStatement("SELECT projet.ajouter_projet_cours(?,?,?,?,?)");
      psCreerGroupe = conn.prepareStatement("SELECT projet.ajouter_groupe_projet(?,?,?)");
      psValiderGroupe = conn.prepareStatement("SELECT projet.valider_groupe(?,?)");
      psValiderTousGroupe = conn.prepareStatement("SELECT projet.valider_tous_les_groupes(?)");
      psVisualiserCours = conn.prepareStatement("SELECT DISTINCT * FROM projet.vue_cours") ;
      psVisualiserGroupes = conn.prepareStatement("SELECT  numéro, nom, prenom, \"Validé\", \"Complet\" FROM projet.vue_groupe_projet WHERE id_projet =(?)");
      psVisualiserProjets = conn.prepareStatement("SELECT * FROM projet.vue_projets ");
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  public String menu() {
    return "1 : Ajouter un cours.\n"
        + "2 : Ajouter un étudiant.\n"
        + "3 : inscrire un etudiant.\n"
        + "4 : créer un projet.\n"
        + "5 : Créer un groupe.\n"
        + "6 : Visualiser les cours.\n"
        + "7 : Visualiser les projets.\n"
        + "8 : Visualiser les groupes. \n"
        + "9 : Valider un groupe. \n"
        + "10 : Valider tous les groupes. \n"
        + "0 : Quitter l'application.";

  }
  /**
   * les méthode = les procédure et les vues.
   */
  public void quitter(){
    try{
      conn.close();
      System.out.println("Au revoir Revenez quand vous voulez ! ");
    } catch (SQLException e) {
      System.out.println("erreur lors de la fermeture de la connexion");
      System.out.println(e.getMessage());
      e.printStackTrace();
    }
  }
  public void ajouterCours(){
    //psAjouterCours = conn.prepareStatement("SELECT projet.ajouter_cours(?,?,?,?);"
    String nom, codeCours, bloc;
    int credit;
    try{
      System.out.println("Ajouter un Cours");
      System.out.println("Quel est le code de l'ue (BINV???) Format en MAJUSCULE !");
      codeCours = sc.nextLine();
      System.out.println("Quel est le nom du cours ");
      nom = sc.nextLine();
      System.out.println("Quel est le bloc du cours");
      bloc= sc.nextLine();
      System.out.println("quel est le nombre de crédit du cours");
      credit = Integer.parseInt(sc.nextLine());

      int coursChar4 = Character.getNumericValue(codeCours.charAt(4));
      if(coursChar4 != Integer.parseInt(bloc)){
        System.out.println("l'ajout n'a pas pu se faire, le code du cours ne correspond pas au bloc");
      } else {
        psAjouterCours.setString(1, nom);
        psAjouterCours.setString(2, codeCours);
        psAjouterCours.setString(3, bloc);
        psAjouterCours.setInt(4, credit );
        psAjouterCours.execute();
      }
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  public void ajouterEtudiant (){
      String nom, prenom, email, mdp;
    try {
      System.out.println("Entrez le nom");
      nom = sc.nextLine();
      System.out.println("Entrez le prénom");
      prenom = sc.nextLine();
      System.out.println("Entrez l'adresse email");
      email = sc.nextLine();
      System.out.println("Entrez le mot de passe");
      mdp = BCrypt.hashpw(sc.nextLine(), BCrypt.gensalt());

      psAjouterEtudiant.setString(1, nom);
      psAjouterEtudiant.setString(2, prenom);
      psAjouterEtudiant.setString(3, email);
      psAjouterEtudiant.setString(4, mdp);
      psAjouterEtudiant.execute();
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  public void inscrireEtudiant(){
    try{
      String emailEtudiant, idCours;
      System.out.println("Entrez le code du cours");
      idCours = sc.nextLine();
      System.out.println("Entrez l'email de l'étudiant ");
      emailEtudiant = sc.nextLine();

      psInscrireEtudiant.setString(1,idCours);
      psInscrireEtudiant.setString(2,emailEtudiant);
      psInscrireEtudiant.execute();
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  public void creerProjet(){
    String idProjet, codeCours, nom, dateDebut, dateFin;

    try{
      System.out.println("Entrez l'id du projet");
      idProjet = sc.nextLine();
      System.out.println("Entrez le code du cours");
      codeCours = sc.nextLine();
      System.out.println("Entrez le nom du projet");
      nom = sc.nextLine();
      System.out.println("Entrez la date de debut du projet (aaaa-mm-jj)");
      dateDebut = sc.nextLine();
      System.out.println("Entrez la date de fin du projet (aaaa-mm-jj");
      dateFin = sc.nextLine();

      psCreerProjet.setString(1,idProjet);
      psCreerProjet.setString(2,codeCours);
      psCreerProjet.setString(3,nom);
      psCreerProjet.setDate(4, Date.valueOf(dateDebut));
      psCreerProjet.setDate(5,Date.valueOf(dateFin));
      psCreerProjet.execute();
    } catch (SQLException e) {
      e.printStackTrace();
    }

  }
  public void creerGroupe(){
    int nbrGroupe, nbrMembre;
    String idProjet;
    try{
      System.out.println("Entrez l'id du projet");
      idProjet = sc.nextLine();
      System.out.println("Entrez le nombre de groupe");
      nbrGroupe = Integer.parseInt(sc.nextLine());
      System.out.println("Entrez le nombre de personne par groupe");
      nbrMembre = Integer.parseInt(sc.nextLine());
      psCreerGroupe.setString(1,idProjet);
      psCreerGroupe.setInt(2,nbrGroupe);
      psCreerGroupe.setInt(3,nbrMembre);
      psCreerGroupe.execute();
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  public void validerGroupe(){
    int idProjet, idGroupe;
    try{
      System.out.println("Entrez l'id du projet");
      idProjet = Integer.parseInt(sc.nextLine());
      System.out.println("Entrez l'id du groupe");
      idGroupe = Integer.parseInt(sc.nextLine());
      psValiderGroupe.setInt(1, idProjet);
      psValiderGroupe.setInt(1, idGroupe);
      psValiderGroupe.execute();
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  public void validerTousGroupe(){
    String idProjet;
    try{
      System.out.println("Entrez l'id du projet");
      idProjet = sc.nextLine();
      psValiderTousGroupe.setString(1, idProjet);
      psValiderTousGroupe.execute();
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  public void visualiserCours(){
    String texte = "";
    try{
      System.out.println("Voici les cours ");
      ResultSet cours = psVisualiserCours.executeQuery();
      while(cours.next()){
        texte += "id cours: " + cours.getString("id_cours") + " nom: " + cours.getString("nom") +
            " projet en cours: " + cours.getString("projet en cours");
        texte += "\n";
      }
        System.out.println(texte);
    } catch (SQLException e) {
      System.out.println("Erreur lors de la visualisation des cours");
      System.out.println(e.getMessage());
      e.printStackTrace();
    }
  }
  public void visualiserProjets(){
    String texte = "";
    try{
      System.out.println("Voici les projets en cours : ");
      ResultSet projets = psVisualiserProjets.executeQuery();
      while(projets.next()){
        texte += "id projet: " + projets.getString("id_projet") + " Nom: "
            + projets.getString("nom") +  " id cours : " + projets.getString("id_cours") +
            " nombre de groupe: " + projets.getString("nombre de groupe") + " groupe complet: " +
            projets.getString("groupe complet");
        texte += "\n";
      }
        System.out.println(texte);
    } catch (SQLException e) {
      System.out.println("Erreur lors de la visualisation des projets");
      System.out.println(e.getMessage());
      e.printStackTrace();
    }
  }
  public void visualiserGroupes(){
    String texte = "";
    String projet;
    try{
      System.out.println("Entrez l'id du projet");
      projet = sc.nextLine();
      System.out.println("Voici les Groupes de projet "+ projet);
      psVisualiserGroupes.setString(1,projet);
      ResultSet groupes = psVisualiserGroupes.executeQuery();
      while(groupes.next()){
        texte += "numéro : " + groupes.getString("numéro") + " nom: " + groupes.getString("nom") +
            " prénom: " + groupes.getString("prenom") + " Groupe validé: " + groupes.getString("Validé") +
            " Complet: " + groupes.getString("Complet");
        texte += "\n";
      }
        System.out.println(texte);
    } catch (SQLException e) {
      System.out.println("Erreur lors de la visualisation des groupes du projet");
      e.printStackTrace();
    }
  }

}
