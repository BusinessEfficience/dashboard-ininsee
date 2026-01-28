                    ###################################################################
                    #    Programme de codification automatique des libellés en PCS
                    ###################################################################

# -*- coding: utf-8 -*-

########################
#Librairies et fonctions
########################
import pandas as pd
import numpy as np
import csv
import re
from copy import deepcopy

def lreplace(pattern, sub, string):
    """
    Replaces 'pattern' in 'string' with 'sub' if 'pattern' starts 'string'.
    """
    return re.sub('^%s' % pattern, sub, string)

def rreplace(pattern, sub, string):
    """
    Replaces 'pattern' in 'string' with 'sub' if 'pattern' ends 'string'.
    """
    return re.sub('%s$' % pattern, sub, string)

##############################################################
# Données issues de la collecte nécessaires à la codification
##############################################################

#Conformément aux indications données sur nomenclature-pcs.fr (où sont précisées les variables annexes et les questions à partir 
#desquelles elles sont définies), les données requises (dans la table initiale COLLECTE) pour la codification de la PCS 2020 
#comprennent :
#  - une variable de libellé issue de la liste : LIBPROF ; les libellés collectés en clair, quand aucun libellé de la liste n'a 
#    été sélectionné peuvent être intégrées à cette variable, mais ils ne seront qu'assez rarement présents dans la liste des libellés
#    que comprend la matrice de codification et devront donc probablement faire l'objet d'une codification en reprise (manuelle ou par imputation). 
#  - les quatre variables annexes issues de la collecte : STATUT, PUB, CPF et TAILLE dont les modalités sont: 

#STATUT = 
#  1 (salariat, modalités 2 [Salarié(e) de la fonction publique (Etat, territoriale ou hospitalière)], 3 [Salarié(e) d'une entreprise 
#    (y compris d'une association ou de la Sécurité sociale)] ou 4 [Salarié(e) d'un particulier] de la question STATUT_PUBLIC_PRIVE) ; 
#  2 (indépendance, modalités 1 [à votre compte (y compris gérant de société ou chef d'entreprise salarié)] ou manquante de la 
#    question STATUT_PUBLIC_PRIVE) ; 
#  3 (situation d'aide familial, modalité 5 [Vous travaill(i)ez, sans être rémunéré(e), avec un membre de votre famille] de la 
#    question STATUT_PUBLIC_PRIVE) ;
#  * (vide ou non réponse à la question STATUT_PUBLIC_PRIVE).

#PUB = 
#  1 (salariat du privé ; modalités 3 [Salarié(e) d'une entreprise (y compris d'une association ou de la Sécurité sociale)] ou 4 
#    [Salarié(e) d'un particulier] de la question STATUT_PUBLIC_PRIVE) ; 
#  2 (salariat du public, modalité 2 [Salarié(e) de la fonction publique (Etat, territoriale ou hospitalière)] de la question 
#    STATUT_PUBLIC_PRIVE) ;
#  * (vide, non réponse ou modalité 1 [à votre compte (y compris gérant de société ou chef d'entreprise salarié)] de la question 
#    STATUT_PUBLIC_PRIVE].

#CPF =
#  1 (cadre d'entreprise ; modalité 6 si PUB = 1 [Ingénieur(e), cadre d'entreprise] de la question POSITION_PUBLIC_PRIVE) ;
#  2 (technicien ; modalités 5 si PUB = 1 et 3 si PUB = 2 [Technicien(ne)] de la question POSITION_PUBLIC_PRIVE) ;
#  3 (agent de maitrise ; modalité 4 si PUB = 1 [Agent de maîtrise (y compris administrative ou commerciale)] de la question 
#    POSITION_PUBLIC_PRIVE) ;
#  4 (employé ; modalité 3 si PUB = 1 [Employé(e) de bureau, de commerce, de services] de la question POSITION_PUBLIC_PRIVE) ;
#  5 (ouvrier qualifié ; modalité 2 si PUB = 1 et 2 si PUB = 2 [Ouvrier (ouvrière) qualifié(e), technicien(ne) d'atelier] de la 
#    question POSITION_PUBLIC_PRIVE) ;
#  6 (ouvrier peu qualifié ; modalité 1 si PUB = 1 et 1 si PUB = 2 [Manoeuvre, ouvrier (ouvrière) spécialisé(e)] de la question 
#    POSITION_PUBLIC_PRIVE) ;
#  7 (agent de catégorie A ; modalité 6 si PUB = 2 [Agent de catégorie A de la fonction publique] de la question 
#    POSITION_PUBLIC_PRIVE) ;
#  8 (agent de catégorie B ; modalité 5 si PUB = 2 [Agent de catégorie B de la fonction publique] de la question 
#    POSITION_PUBLIC_PRIVE) ;
#  9 (agent de catégorie C ; modalité 4 si PUB = 2 [Agent de catégorie C de la fonction publique] de la question 
#    POSITION_PUBLIC_PRIVE) ;
#  * (vide, non réponse ou modalité 7 si PUB = 1 ou 7 si PUB = 2 [Dans une autre situation] de la question POSITION_PUBLIC_PRIVE).

#TAILLE = 
#  0 (de 1 à 10 personnes dans l'entreprise, modalités 1 [Une seule personne : vous travaillez seul(e) / vous travailliez seul(e)]
#    et 2 [Entre 2 et 10 personnes] de la question TAILLE_ENTREPRISE) ; 
#  1 (de 11 à 49 personnes dans l'entreprise, modalité 3 [Entre 11 et 49 personnes] de la question TAILLE_ENTREPRISE) ; 
#  2 (50 personnes et plus dans l'entreprise, modalité 4 [50 personnes ou plus] de la question TAILLE_ENTREPRISE) ;
#  * (vide ou non réponse à la question TAILLE_ENTREPRISE).

#Ces libellés et variables peuvent correspondre à la sitation professionnelle principale de la personne enquêtée, à une activité
#secondaire (si elle en exerce une) ou une situation antérieure (notamment lorsqu'elle n'est pas en emploi à la date d'enquête), 
#à la situation professionnelle d'un membre du ménage (conjoint ou enfant par exemple) ou d'un parent. 

#Uniquement pour l'obtention d'une variable de PCS sur l'ensemble de la population et non seulement les actifs. 
# - la variable de statut d'activité, ACTIVITE, qui distingue l'emploi (ACTIVITE = "1"), le chômage (ACTIVITE = "2") et 
#   l'inactivité (ACTIVITE = "3" ou de "3" à "9"), selon que la variable de statut d'activité disponible dans la source correspond 
#   à l'activité BIT (ACTIVITE_BIT) ou à l'activité spontanée (ACTIVITE_SPONTANEE).

#Et bien sûr, un identifiant individuel IDENTIFIANT, pour permettre l'appariement des tables avec les variables créées.


#################################
# Déclaration de chemins d'accès
#################################

#Dossier où se trouve la base de données COLLECTE avec les libellés et variables annexes issues de la collecte
#et où sera créée la base de données CODIFICATION avec les libellés et la variable VARANX pour la codification automatique
#ainsi que les résultats de la codification automatique CODAGE.
cheminBases = "........"

#Chemin où se trouve la matrice de codification
cheminMatriceCodif = "........"


###########################
# Base de données COLLECTE
###########################

COLLECTE = pd.read_sas(cheminBases+'nom_base_collecte.sas7bdat', encoding='ISO-8859-1')
COLLECTE.fillna('',inplace=True)


#########################################################################
# Transcodage des variables annexes (passage des QUESTIONS aux VARIABLES) 
#########################################################################
CODIFICATION = deepcopy(COLLECTE)

#Variable STATUT
CODIFICATION["STATUT"] = ""
for ind in CODIFICATION.index:
    if CODIFICATION['STATUT_PUBLIC_PRIVE'][ind] in ("2","3","4"):
        CODIFICATION['STATUT'][ind]="1"
    elif CODIFICATION['STATUT_PUBLIC_PRIVE'][ind] == "1":
        CODIFICATION['STATUT'][ind]="2"
    elif CODIFICATION['STATUT_PUBLIC_PRIVE'][ind] == "5":
        CODIFICATION['STATUT'][ind]="3"
    else:
        CODIFICATION['STATUT'][ind]="*"
       
#Variable PUB
CODIFICATION["PUB"] = ""
for ind in CODIFICATION.index:
    if CODIFICATION['STATUT_PUBLIC_PRIVE'][ind] in ("3","4"):
        CODIFICATION['PUB'][ind]="1"
    elif CODIFICATION['STATUT_PUBLIC_PRIVE'][ind] == "2":
        CODIFICATION['PUB'][ind]="2"
    else:
        CODIFICATION['PUB'][ind]="*"

#Variable CPF
CODIFICATION["CPF"] = ""
for ind in CODIFICATION.index:
    if CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="6" and CODIFICATION['PUB'][ind]=="1":
        CODIFICATION['CPF'][ind]="1"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="5" and CODIFICATION['PUB'][ind]=="1":
        CODIFICATION['CPF'][ind]="2"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="3" and CODIFICATION['PUB'][ind]=="2":
        CODIFICATION['CPF'][ind]="2"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="4" and CODIFICATION['PUB'][ind]=="1":
        CODIFICATION['CPF'][ind]="3"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="3" and CODIFICATION['PUB'][ind]=="1":
        CODIFICATION['CPF'][ind]="4"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="2" and CODIFICATION['PUB'][ind]=="1":
        CODIFICATION['CPF'][ind]="5"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="2" and CODIFICATION['PUB'][ind]=="2":
        CODIFICATION['CPF'][ind]="5"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="1" and CODIFICATION['PUB'][ind]=="1":
        CODIFICATION['CPF'][ind]="6"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="1" and CODIFICATION['PUB'][ind]=="2":
        CODIFICATION['CPF'][ind]="6"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="6" and CODIFICATION['PUB'][ind]=="2":
        CODIFICATION['CPF'][ind]="7"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="5" and CODIFICATION['PUB'][ind]=="2":
        CODIFICATION['CPF'][ind]="8"
    elif CODIFICATION['POSITION_PUBLIC_PRIVE'][ind] =="4" and CODIFICATION['PUB'][ind]=="2":
        CODIFICATION['CPF'][ind]="9"
    else:
        CODIFICATION['CPF'][ind]="*"

#Variable TAILLE
CODIFICATION["TAILLE"] = ""
for ind in CODIFICATION.index:
    if CODIFICATION['TAILLE_ENTREPRISE'][ind] in ("1","2"):
        CODIFICATION['TAILLE'][ind]="0"
    elif CODIFICATION['TAILLE_ENTREPRISE'][ind] == "3":
        CODIFICATION['TAILLE'][ind]="1"
    elif CODIFICATION['TAILLE_ENTREPRISE'][ind] == "4":
        CODIFICATION['TAILLE'][ind]="2"
    else:
        CODIFICATION['TAILLE'][ind]="*"   

    
#####################################################################################
# Création de la variable annexe VARANX unique nécessaire au codage
#####################################################################################
    
#Variable champ pour identifier lorsque le libellé de profession est non vide
CODIFICATION["CHAMP_CODIFICATION"] = ""
for ind in CODIFICATION.index:
    if CODIFICATION['LIBPROF'][ind] !="":
        CODIFICATION['CHAMP_CODIFICATION'][ind]="1"
    else:
        CODIFICATION['CHAMP_CODIFICATION'][ind]="0"
    
#Création de la variable VARANX qui est la synthèse des 4 variables annexes (STATUT, PUB, CPF et TAILLE)
CODIFICATION["VARANX"] = ""
for ind in CODIFICATION.index:
    if CODIFICATION['CPF'][ind] == "1":
        CODIFICATION['VARANX'][ind]="priv_cad"
    elif CODIFICATION['CPF'][ind] == "2": 
        CODIFICATION['VARANX'][ind]="priv_tec"
    elif CODIFICATION['CPF'][ind] == "3":
        CODIFICATION['VARANX'][ind]="priv_am"
    elif CODIFICATION['CPF'][ind] == "4":
        CODIFICATION['VARANX'][ind]="priv_emp"
    elif CODIFICATION['CPF'][ind] == "5":
        CODIFICATION['VARANX'][ind]="priv_oq"
    elif CODIFICATION['CPF'][ind] == "6":
        CODIFICATION['VARANX'][ind]="priv_opq"
    elif CODIFICATION['CPF'][ind] == "7":
        CODIFICATION['VARANX'][ind]="pub_catA"
    elif CODIFICATION['CPF'][ind] == "8":
        CODIFICATION['VARANX'][ind]="pub_catB"
    elif CODIFICATION['CPF'][ind] == "9":
        CODIFICATION['VARANX'][ind]="pub_catC"  
              
    elif CODIFICATION['STATUT'][ind]=="3":
        CODIFICATION['VARANX'][ind]="aid_fam" 
      
    elif CODIFICATION['STATUT'][ind]=="2" and CODIFICATION['TAILLE'][ind] == "*":
        CODIFICATION['VARANX'][ind]="inde_nr" 
    elif CODIFICATION['STATUT'][ind] in ("2","*") and CODIFICATION['TAILLE'][ind] == "0":
        CODIFICATION['VARANX'][ind]="inde_0_9"
    elif CODIFICATION['STATUT'][ind] in ("2","*") and CODIFICATION['TAILLE'][ind] == "1":
        CODIFICATION['VARANX'][ind]="inde_10_49"
    elif CODIFICATION['STATUT'][ind] in ("2","*") and CODIFICATION['TAILLE'][ind] == "2":
        CODIFICATION['VARANX'][ind]="inde_sup49"   
      
    elif  CODIFICATION['CPF'][ind] == "*" and CODIFICATION['STATUT'][ind] == "1" and CODIFICATION['PUB'][ind] == "2":
        CODIFICATION['VARANX'][ind]="pub_nr"    
    elif  CODIFICATION['CPF'][ind] == "*" and CODIFICATION['STATUT'][ind] == "1" and CODIFICATION['PUB'][ind] in ("1","*"):
        CODIFICATION['VARANX'][ind]="priv_nr"

#Aucune variable annexe n'est renseignée => sans variable annexe (ssvaran)
    elif CODIFICATION['STATUT'][ind] == "*" and CODIFICATION['PUB'][ind] == "*" and CODIFICATION['CPF'][ind] == "*" and CODIFICATION['TAILLE'][ind] == "*":
        CODIFICATION['VARANX'][ind]="ssvaran"
#Situation de rattrapage, le cas ne se retrouve dans aucune règle de l'index => cas incohérent (inco)
    else:
        CODIFICATION['VARANX'][ind]= "cas_inco"


####################################################################
# Import de la matrice de codification pour la PCS2020 au format CSV 
####################################################################

#La matrice peut être téléchargée sur le site nomenclature-pcs.fr ou insee.fr
matrice = pd.read_csv(cheminMatriceCodif+'Nom_matrice_codification_PCS2020_collecteAAAA.csv',sep=",", encoding="utf-8")
matrice.fillna('',inplace=True)


##############################################################
# Codification Automatique
##############################################################


############################
# Normalisation des libellés
############################

def normalisation(BASE, LIBPARAM):
    LIBPROF=LIBPARAM
    for ind in BASE.index: 
        LIBPROF[ind]=LIBPROF[ind].lower()
        LIBPROF[ind]=LIBPROF[ind].replace('à','a')
        LIBPROF[ind]=LIBPROF[ind].replace('â','a')
        LIBPROF[ind]=LIBPROF[ind].replace('é','e')
        LIBPROF[ind]=LIBPROF[ind].replace('è','e')
        LIBPROF[ind]=LIBPROF[ind].replace('ê','e')
        LIBPROF[ind]=LIBPROF[ind].replace('ë','e')
        LIBPROF[ind]=LIBPROF[ind].replace('ï','i')
        LIBPROF[ind]=LIBPROF[ind].replace('î','i')
        LIBPROF[ind]=LIBPROF[ind].replace('û','u')
        LIBPROF[ind]=LIBPROF[ind].replace('ù','u')
        LIBPROF[ind]=LIBPROF[ind].replace('ü','u')
        LIBPROF[ind]=LIBPROF[ind].replace('ô','o')
        LIBPROF[ind]=LIBPROF[ind].replace('ç','c')
        LIBPROF[ind]=LIBPROF[ind].replace('œ','oe')
        LIBPROF[ind]=LIBPROF[ind].replace('\x9c','oe')
        LIBPROF[ind]=LIBPROF[ind].replace("("," ")
        LIBPROF[ind]=LIBPROF[ind].replace(")"," ")
        LIBPROF[ind]=LIBPROF[ind].replace("/"," ")
        LIBPROF[ind]=LIBPROF[ind].replace("-"," ")
        LIBPROF[ind]=LIBPROF[ind].replace(","," ")
        LIBPROF[ind]=LIBPROF[ind].replace("'"," ")
        LIBPROF[ind]=LIBPROF[ind].replace("’"," ")
        LIBPROF[ind]=LIBPROF[ind].replace('\x92'," ")
        LIBPROF[ind]=LIBPROF[ind].replace("."," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" dans "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" en "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" de "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" sur "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" aux "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" au "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" des "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" d "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" l "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" a "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" un "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" une "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" du "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" et "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" la "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" le "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" ou "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" pour "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" avec "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" chez "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" par "," ")
        LIBPROF[ind]=LIBPROF[ind].replace(" les "," ")
        LIBPROF[ind]=rreplace(" dans"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" en"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" de"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" sur"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" aux"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" au"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" des"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" d"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" l"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" a"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" un"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" une"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" du"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" et"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" la"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" le"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" ou"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" pour"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" avec"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" chez"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" par"," ",LIBPROF[ind])
        LIBPROF[ind]=rreplace(" les"," ",LIBPROF[ind])
        LIBPROF[ind]=LIBPROF[ind].replace(" ","")
        LIBPROF[ind]=LIBPROF[ind].replace(chr(160),'')
        LIBPROF[ind]=LIBPROF[ind].replace(chr(32),'').upper()  
    return LIBPROF

CODIFICATION['LIBPROFNONNORM']=""
CODIFICATION['LIBPROFNONNORM'] = deepcopy(CODIFICATION['LIBPROF'])
CODIFICATION['LIBPROF']=""
CODIFICATION['LIBPROF'] = deepcopy(CODIFICATION['LIBPROFNONNORM'])
CODIFICATION['LIBPROF'] = normalisation(CODIFICATION, CODIFICATION['LIBPROF']) 


##########################
# Codification automatique
##########################

CODAGE = deepcopy(CODIFICATION)
CODAGE = CODAGE[["IDENTIFIANT", "LIBPROF", "CHAMP_CODIFICATION","VARANX"]]

CODAGE['CODE_PCS2020']=""

for ind in CODAGE.index:
    if len(matrice[matrice['sgnm']==CODIFICATION['LIBPROF'][ind]]) > 0 :
        CODAGE['CODE_PCS2020'][ind] = list(matrice[matrice['sgnm']==CODIFICATION['LIBPROF'][ind]][CODIFICATION['VARANX'][ind]])[0]  
    elif len(matrice[matrice['sgnf']==CODIFICATION['LIBPROF'][ind]]) > 0 :
        CODAGE['CODE_PCS2020'][ind] = list(matrice[matrice['sgnf']==CODIFICATION['LIBPROF'][ind]][CODIFICATION['VARANX'][ind]])[0]
    else :
        CODAGE['CODE_PCS2020'][ind]='0000'

for ind in CODAGE.index:
    if CODAGE['CHAMP_CODIFICATION'][ind] == "1":
        CODAGE['CODE_PCS2020'][ind]=CODAGE['CODE_PCS2020'][ind]
    else:
        CODAGE['CODE_PCS2020'][ind]=""
    
CODAGE.to_csv(cheminBases+'nom_fichier_de_résultats.csv', encoding= "utf-8")
