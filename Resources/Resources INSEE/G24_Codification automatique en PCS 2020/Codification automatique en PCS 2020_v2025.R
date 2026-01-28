##########################################################################################
############ Programme de codification automatique des libellé en PCS 2020###############
##########################################################################################


############
# Librairies
############
library(stringr)
library(dplyr)
library(readr)
library(haven)
library(data.table)

##########################################################################################
# Données issues de la collecte nécessaires à la codification
##########################################################################################

#Conformément aux indications données sur nomenclature-pcs.fr (où sont précisées les variables annexes et les questions à partir 
#desquelles elles sont définies), les données requises (dans la table initiale COLLECTE) pour la codification de la PCS 2020 
#comprennent :

#  - une variable de libellé issue de la liste : LIBPROF ; les libellés collectés en clair, quand aucun libellé de la liste n'a été 
#sélectionné peuvent être intégrées à cette variable, mais ils ne seront qu'assez rarement présents dans la liste des libellés que 
#comprend la matrice de codification et devront donc probablement faire l'objet d'une codification en reprise (manuelle ou par imputation). 

#- les quatre variables annexes issues de la collecte : STATUT, PUB, CPF et TAILLE dont les modalités sont: 

#STATUT = 
#  1 (salariat, modalités 2 [Salarié(e) de la fonction publique (Etat, territoriale ou hospitalière)], 3 [Salarié(e) d'une entreprise 
#    (y compris d'une association ou de la Sécurité sociale)] ou 4 [Salarié(e) d'un particulier] de la question STATUT_PUBLIC_PRIVE) ; 
#  2 (indépendance, modalités 1 [à votre compte (y compris gérant de société ou chef d'entreprise salarié)] ou manquante de la 
#   question STATUT_PUBLIC_PRIVE) ; 
#  3 (situation d'aide familial, modalité 5 [Vous travaill(i)ez, sans être rémunéré(e), avec un membre de votre famille] de la 
#   question STATUT_PUBLIC_PRIVE) ;
#  * (vide ou non réponse à la question STATUT_PUBLIC_PRIVE).

#PUB = 
#  1 (salariat du privé ; modalités 3 [Salarié(e) d'une entreprise (y compris d'une association ou de la Sécurité sociale)] ou 4 
#   [Salarié(e) d'un particulier] de la question STATUT_PUBLIC_PRIVE) ; 
#  2 (salariat du public, modalité 2 [Salarié(e) de la fonction publique (Etat, territoriale ou hospitalière)] de la question 
#   STATUT_PUBLIC_PRIVE) ;
#  * (vide, non réponse ou modalité 1 [à votre compte (y compris gérant de société ou chef d'entreprise salarié)] de la question 
#   STATUT_PUBLIC_PRIVE].

#CPF =
#   1 (cadre d'entreprise ; modalité 6 si PUB = 1 [Ingénieur(e), cadre d'entreprise] de la question POSITION_PUBLIC_PRIVE) ;
#   2 (technicien ; modalités 5 si PUB = 1 et 3 si PUB = 2 [Technicien(ne)] de la question POSITION_PUBLIC_PRIVE) ;
#   3 (agent de maitrise ; modalité 4 si PUB = 1 [Agent de maîtrise (y compris administrative ou commerciale)] de la question 
#   POSITION_PUBLIC_PRIVE) ;
#   4 (employé ; modalité 3 si PUB = 1 [Employé(e) de bureau, de commerce, de services] de la question POSITION_PUBLIC_PRIVE) ;
#   5 (ouvrier qualifié ; modalité 2 si PUB = 1 et 2 si PUB = 2 [Ouvrier (ouvrière) qualifié(e), technicien(ne) d'atelier] de la 
#   question POSITION_PUBLIC_PRIVE) ;
#   6 (ouvrier peu qualifié ; modalité 1 si PUB = 1 et 1 si PUB = 2 [Manoeuvre, ouvrier (ouvrière) spécialisé(e)] de la question 
#   POSITION_PUBLIC_PRIVE) ;
#   7 (agent de catégorie A ; modalité 6 si PUB = 2 [Agent de catégorie A de la fonction publique] de la question 
#   POSITION_PUBLIC_PRIVE) ;
#   8 (agent de catégorie B ; modalité 5 si PUB = 2 [Agent de catégorie B de la fonction publique] de la question 
#   POSITION_PUBLIC_PRIVE) ;
#   9 (agent de catégorie C ; modalité 4 si PUB = 2 [Agent de catégorie C de la fonction publique] de la question 
#   POSITION_PUBLIC_PRIVE) ;
#   * (vide, non réponse ou modalité 7 si PUB = 1 ou 7 si PUB = 2 [Dans une autre situation] de la question POSITION_PUBLIC_PRIVE).

#TAILLE = 
#  0 (de 1 à 10 personnes dans l'entreprise, modalités 1 [Une seule personne : vous travaillez seul(e) / vous travailliez seul(e)]
#   et 2 [Entre 2 et 10 personnes] de la question TAILLE_ENTREPRISE) ; 
#  1 (de 11 à 49 personnes dans l'entreprise, modalité 3 [Entre 11 et 49 personnes] de la question TAILLE_ENTREPRISE) ; 
#  2 (50 personnes et plus dans l'entreprise, modalité 4 [50 personnes ou plus] de la question TAILLE_ENTREPRISE) ;
#  * (vide ou non réponse à la question TAILLE_ENTREPRISE).

#Ces libellés et variables peuvent correspondre à la sitation professionnelle principale de la personne enquêtée, à une activité
#secondaire (si elle en exerce une) ou une situation antérieure (notamment lorsqu'elle n'est pas en emploi à la date d'enquête), 
#à la situation professionnelle d'un membre du ménage (conjoint ou enfant par exemple) ou d'un parent. 

#Uniquement pour l'obtention d'une variable de PCS sur l'ensemble de la population et non seulement les actifs. 
#- la variable de statut d'activité, ACTIVITE, qui distingue l'emploi (ACTIVITE = "1"), le chômage (ACTIVITE = "2") et l'inactivité 
#(ACTIVITE = "3" ou de "3" à "9", selon que la variable de statut d'activité disponible dans la source correspond à l'activité BIT 
# (ACTIVITE_BIT) ou à l'activité spontanée (ACTIVITE_SPONTANEE).

#Et bien sûr, un identifiant individuel IDENTIFIANT, pour permettre l'appariement des tables avec les variables créées.


###############################################################################
# Déclaration de chemins d'accès
###############################################################################

#Dossier où se trouve la base de données COLLECTE avec les libellés et variables annexes issues de la 
#collecte et où sera créée la base de données CODIFICATION avec les libellés et la variable VARANX pour la codification automatique
#ainsi que les résultats de la codification automatique CODAGE.
cheminBases = "........"

#Chemin où se trouve la matrice de codification
cheminMatriceCodif = "........"

###############################################################################
# Base de données COLLECTE
###############################################################################

COLLECTE <- read_sas(paste0(cheminBases,"nom_base_collecte.sas7bdat"))


#####################################################################################
# Transcodage des variables annexes (passage des QUESTIONS aux VARIABLES) 
#####################################################################################
CODIFICATION <- COLLECTE %>% 
  mutate(
    #Variable STATUT  
    STATUT=case_when(
      STATUT_PUBLIC_PRIVE %in% c("2","3","4") ~ "1",
      STATUT_PUBLIC_PRIVE %in% c("1") ~ "2",
      STATUT_PUBLIC_PRIVE %in% c("5") ~ "3",
      TRUE ~ "*"),
    
    #Variable PUB  
    PUB=case_when(
      STATUT_PUBLIC_PRIVE %in% c("3","4") ~ "1",
      STATUT_PUBLIC_PRIVE %in% c("2") ~ "2",
      TRUE ~ "*"),
    
    #Variable CPF  
    CPF=case_when(
      POSITION_PUBLIC_PRIVE == '6' & PUB == "1" ~ "1",
      POSITION_PUBLIC_PRIVE == "5" & PUB == "1" ~ "2",
      POSITION_PUBLIC_PRIVE == "3" & PUB == "2" ~ "2",
      POSITION_PUBLIC_PRIVE == "4" & PUB == "1" ~ "3",
      POSITION_PUBLIC_PRIVE == "3" & PUB == "1" ~ "4",
      POSITION_PUBLIC_PRIVE == "2" & PUB == "1" ~ "5",
      POSITION_PUBLIC_PRIVE == "2" & PUB == "2" ~ "5",
      POSITION_PUBLIC_PRIVE == "1" & PUB == "1" ~ "6",
      POSITION_PUBLIC_PRIVE == "1" & PUB == "2" ~ "6",
      POSITION_PUBLIC_PRIVE == "6" & PUB == "2" ~ "7",
      POSITION_PUBLIC_PRIVE == "5" & PUB == "2" ~ "8",
      POSITION_PUBLIC_PRIVE == "4" & PUB == "2" ~ "9",
      TRUE ~ "*"),
    
    #Variable TAILLE  
    TAILLE=case_when(
      TAILLE_ENTREPRISE %in% c("1", "2") ~ "0",
      TAILLE_ENTREPRISE %in% c("3") ~ "1",
      TAILLE_ENTREPRISE %in% c("4") ~ "2",
      TRUE ~ "*"),
    
    #####################################################################################
    # Création de la variable annexe VARANX unique nécessaire au codage
    #####################################################################################
    
    #Variable champ pour identifier lorsque le libellé de profession est non vide
    CHAMP_CODIFICATION = case_when(
      LIBPROF !=""  ~ "1",
      TRUE ~ "0"),
    
    #Création de la variable VARANX qui est la synthèse des 4 variables annexes (STATUT, PUB, CPF et TAILLE)
    VARANX = case_when(
      CPF == "1" ~ "priv_cad",
      CPF == "2" ~ "priv_tec",
      CPF == "3" ~ "priv_am",
      CPF == "4" ~ "priv_emp",
      CPF == "5" ~ "priv_oq",
      CPF == "6" ~ "priv_opq",
      CPF == "7" ~ "pub_catA",
      CPF == "8" ~ "pub_catB",
      CPF == "9" ~ "pub_catC",
      
      STATUT == "3" ~ "aid_fam",
      
      STATUT == "2" & TAILLE == "*" ~ "inde_nr",
      STATUT %in% c("2", "*") & TAILLE == "0" ~ "inde_0_9",
      STATUT %in% c("2", "*") & TAILLE == "1" ~ "inde_10_49",
      STATUT %in% c("2", "*") & TAILLE == "2" ~ "inde_sup49",
      
      CPF == "*" & STATUT == "1" & PUB == "2" ~ "pub_nr",
      CPF == "*" & STATUT == "1" & PUB %in% c("1", "*") ~ "priv_nr",
      
      #Aucune variable annexe n'est renseignée => sans variable annexe (ssvaran)
      CPF == "*" & STATUT == "*" & TAILLE == "*" & PUB == "*" ~ "ssvaran",
      
      #Situation de rattrapage, le cas ne se retrouve dans aucune règle de l'index => cas incohérent (inco)
      TRUE ~ 'cas_inco'))


#####################################################################################
# Import de la matrice de codification pour la PCS2020 au format CSV 
#####################################################################################

#la matrice peut être téléchargée sur le site nomenclature-pcs.fr ou insee.fr
matrice <- read.csv(paste0(cheminMatriceCodif,"Nom_matrice_codification_PCS2020_collecteAAAA.csv",sep=""),sep=",", fileEncoding="utf8")
matriceDT <- as.data.table(matrice)


#####################################################################################
# Codification Automatique
#####################################################################################

########################################
# Fonction de normalisation des libellés
########################################
  

normalisation<- function(LIBPARAM){
  LIBPROF = str_to_upper(LIBPARAM)
  LIBPROF = chartr("()/-","    ",LIBPROF)
  LIBPROF = chartr(",'’.","    ",LIBPROF)
  LIBPROF <- stringi::stri_trans_general(str = LIBPROF, id = "Latin-ASCII")
  LIBPROF = str_replace_all(LIBPROF," DE "," ")
  LIBPROF = str_replace_all(LIBPROF," EN "," ")
  LIBPROF = str_replace_all(LIBPROF," DES "," ")
  LIBPROF = str_replace_all(LIBPROF," D "," ")
  LIBPROF = str_replace_all(LIBPROF," L "," ")
  LIBPROF = str_replace_all(LIBPROF," AU "," ")
  LIBPROF = str_replace_all(LIBPROF," DU "," ")
  LIBPROF = str_replace_all(LIBPROF," SUR "," ")
  LIBPROF = str_replace_all(LIBPROF," AUX "," ")
  LIBPROF = str_replace_all(LIBPROF," DANS "," ")
  LIBPROF = str_replace_all(LIBPROF," A "," ")
  LIBPROF = str_replace_all(LIBPROF," UN "," ")
  LIBPROF = str_replace_all(LIBPROF," UNE "," ")
  LIBPROF = str_replace_all(LIBPROF," ET "," ")
  LIBPROF = str_replace_all(LIBPROF," LA "," ")
  LIBPROF = str_replace_all(LIBPROF," LE "," ")
  LIBPROF = str_replace_all(LIBPROF," OU "," ")
  LIBPROF = str_replace_all(LIBPROF," POUR "," ")
  LIBPROF = str_replace_all(LIBPROF," AVEC "," ")
  LIBPROF = str_replace_all(LIBPROF," CHEZ "," ")
  LIBPROF = str_replace_all(LIBPROF," PAR "," ")
  LIBPROF = str_replace_all(LIBPROF," LES "," ")
  #pour corriger les libellés qui se terminent par une expression non signifiante tels "INFIRMIERE DE"
  LIBPROF = str_replace_all(LIBPROF," DANS$"," ")
  LIBPROF = str_replace_all(LIBPROF," EN$"," ")
  LIBPROF = str_replace_all(LIBPROF," DE$"," ")
  LIBPROF = str_replace_all(LIBPROF," SUR$"," ")
  LIBPROF = str_replace_all(LIBPROF," AUX$"," ")
  LIBPROF = str_replace_all(LIBPROF," AU$"," ")
  LIBPROF = str_replace_all(LIBPROF," DES$"," ")
  LIBPROF = str_replace_all(LIBPROF," D$"," ")
  LIBPROF = str_replace_all(LIBPROF," L$"," ")
  LIBPROF = str_replace_all(LIBPROF," DU$"," ")
  LIBPROF = str_replace_all(LIBPROF," A$"," ")
  LIBPROF = str_replace_all(LIBPROF," UN$"," ")
  LIBPROF = str_replace_all(LIBPROF," UNE$"," ")
  LIBPROF = str_replace_all(LIBPROF," ET$"," ")
  LIBPROF = str_replace_all(LIBPROF," LA$"," ")
  LIBPROF = str_replace_all(LIBPROF," LE$"," ")
  LIBPROF = str_replace_all(LIBPROF," OU$"," ")
  LIBPROF = str_replace_all(LIBPROF," POUR$"," ")
  LIBPROF = str_replace_all(LIBPROF," AVEC$"," ")
  LIBPROF = str_replace_all(LIBPROF," CHEZ$"," ")
  LIBPROF = str_replace_all(LIBPROF," PAR$"," ")
  LIBPROF = str_replace_all(LIBPROF," LES$"," ")
  LIBPROF = str_replace_all(LIBPROF," ","")
}
CODIFICATION$LIBPROFNONNORM <- CODIFICATION$LIBPROF

CODIFICATION$LIBPROF<-normalisation(CODIFICATION$LIBPROFNONNORM)  


##########################
# Codification automatique
##########################

CODAGE<-CODIFICATION %>% 
  select(IDENTIFIANT, LIBPROF, CHAMP_CODIFICATION, VARANX)

CODAGE$CODE_PCS2020= character(nrow(CODAGE))

for(i in 1:nrow(CODAGE)){
  if(nrow(matriceDT[sgnm==CODAGE$LIBPROF[i],])>0){
  CODAGE$CODE_PCS2020[i]= matriceDT[sgnm==CODAGE$LIBPROF[i],get(CODAGE$VARANX[i])]
  }
  else if(nrow(matriceDT[sgnf==CODAGE$LIBPROF[i],])>0 && CODAGE$CHAMP_CODIFICATION[i]=="1"){
  CODAGE$CODE_PCS2020[i]= matriceDT[sgnf==CODAGE$LIBPROF[i],get(CODAGE$VARANX[i])]
  }
  else if(nrow(matriceDT[sgnf==CODAGE$LIBPROF[i],])==0 && CODAGE$CHAMP_CODIFICATION[i]=="1"){
  CODAGE$CODE_PCS2020[i]= "0000"
  }

}
CODAGE$CODE_PCS2020[is.na(CODAGE$CODE_PCS2020)]  

write.csv2(CODAGE, paste0(cheminBases,"nom_fichier_de_résultats.csv"), row.names=FALSE, fileEncoding = "utf-8")
