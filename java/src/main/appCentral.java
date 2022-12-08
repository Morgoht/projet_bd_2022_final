package main;

import app.AppCentrale;
import java.util.Scanner;

public class appCentral {
  static Scanner sc = new Scanner(System.in);

  static AppCentrale app = new AppCentrale();

  public static void main(String[] args) {
    boolean boucle = true;
    while(boucle){
      System.out.println(app.menu());
      int choix = sc.nextInt();
      switch(choix){
        case 0 :
          boucle = false;
          app.quitter();
          break;
        case 1 :
          app.ajouterCours();
          break;
        case 2 :
          app.ajouterEtudiant();
          break;
        case 3 :
          app.inscrireEtudiant();
          break;
        case 4 :
          app.creerProjet();
          break;
        case 5 :
          app.creerGroupe();
          break;
        case 6 :
          app.visualiserCours();
          break;
        case 7 :
          app.visualiserProjets();
          break;
        case 8 :
          app.visualiserGroupes();
          break;
        case 9 :
          app.validerGroupe();
          break;
        case 10 :
          app.validerTousGroupe();
          break;
      }
    }

  }

}
