package main;

import app.ApplicationEtudiant;
import java.util.Scanner;

public class MainEtudiant {
  static Scanner sc = new Scanner(System.in);
  static ApplicationEtudiant app = new ApplicationEtudiant();
  public static void main(String[] args) {
    if(!app.authentification()){
      System.out.println("Login ou mot de passe incorrect");
      app.quitter();
    }
    System.out.println("----Authetification reussi-----");
    boolean boucle = true;
    while(boucle){
      System.out.println(app.menu());
      int choix = sc.nextInt();
      switch (choix){
        case 0 :
          app.quitter();
          break;
        case 1 :
          app.afficherCours();
          break;
        case 2 :
          app.ajouterEtudiantGroupe();
          break;
        case 3 :
          app.retirerGroupe();
          break;
        case 4 :
          app.afficherProjet();
          break;
        case 5 :
          app.afficherProjetSansGroupe();
          break;
        case 6 :
          app.afficherGroupeIncomplet();
          break;
      }
    }
  }
}
