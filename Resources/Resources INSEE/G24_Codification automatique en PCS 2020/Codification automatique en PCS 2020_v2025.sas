
							/******************************************************************/
							/* Programme de codification automatique des libellés en PCS2020 */
							/******************************************************************/

											



/********************************************************************/
/* 	Données issues de la collecte nécessaires à la codification 	*/
/********************************************************************/

/* 

Conformément aux indications données sur nomenclature-pcs.fr (où sont précisées les variables annexes et les questions à partir 
desquelles elles sont définies), les données requises (dans la table initiale COLLECTE) pour la codification de la PCS 2020 
comprennent :

- une variable de libellé issue de la liste : LIBPROF ; les libellés collectés en clair, quand aucun libellé de la liste n'a été 
sélectionné, peuvent être intégrés à cette variable, mais ils ne seront qu'assez rarement présents dans la liste des libellés que 
comprend la matrice de codification et devront donc probablement faire l'objet d'une codification en reprise (manuelle ou 
par imputation). 

- les quatre variables annexes issues de la collecte : STATUT, PUB, CPF et TAILLE dont les modalités sont...  

STATUT = 
1 (salariat, modalités 2 [Salarié(e) de la fonction publique (État, territoriale ou hospitalière)], 3 [Salarié(e) d’une entreprise 
(y compris d’une association ou de la Sécurité sociale)] ou 4 [Salarié(e) d’un particulier] de la question STATUT_PUBLIC_PRIVE) ; 
2 (indépendance, modalités 1 [À votre compte (y compris gérant de société ou chef d’entreprise salarié)] ou manquante de la 
question STATUT_PUBLIC_PRIVE) ; 
3 (situation d'aide familial, modalité 5 [Vous travaill(i)ez, sans être rémunéré(e), avec un membre de votre famille] de la 
question STATUT_PUBLIC_PRIVE) ;
* (vide ou non réponse à la question STATUT_PUBLIC_PRIVE).

PUB = 
1 (salariat du privé ; modalités 3 [Salarié(e) d’une entreprise (y compris d’une association ou de la Sécurité sociale)] ou 4 
[Salarié(e) d’un particulier] de la question STATUT_PUBLIC_PRIVE) ; 
2 (salariat du public, modalité 2 [Salarié(e) de la fonction publique (État, territoriale ou hospitalière)] de la question 
STATUT_PUBLIC_PRIVE) ;
* (vide, non réponse ou modalité 1 [À votre compte (y compris gérant de société ou chef d’entreprise salarié)] de la question 
STATUT_PUBLIC_PRIVE].

CPF =
1 (cadre d'entreprise ; modalité 6 si PUB = 1 [Ingénieur(e), cadre d’entreprise] de la question POSITION_PUBLIC_PRIVE) ;
2 (technicien ; modalités 5 si PUB = 1 et 3 si PUB = 2 [Technicien(ne)] de la question POSITION_PUBLIC_PRIVE) ;
3 (agent de maitrise ; modalité 4 si PUB = 1 [Agent de maîtrise (y compris administrative ou commerciale)] de la question 
POSITION_PUBLIC_PRIVE) ;
4 (employé ; modalité 3 si PUB = 1 [Employé(e) de bureau, de commerce, de services] de la question POSITION_PUBLIC_PRIVE) ;
5 (ouvrier qualifié ; modalité 2 si PUB = 1 et 2 si PUB = 2 [Ouvrier (ouvrière) qualifié(e), technicien(ne) d’atelier] de la 
question POSITION_PUBLIC_PRIVE) ;
6 (ouvrier peu qualifié ; modalité 1 si PUB = 1 et 1 si PUB = 2 [Manœuvre, ouvrier (ouvrière) spécialisé(e)] de la question 
POSITION_PUBLIC_PRIVE) ;
7 (agent de catégorie A ; modalité 6 si PUB = 2 [Agent de catégorie A de la fonction publique] de la question 
POSITION_PUBLIC_PRIVE) ;
8 (agent de catégorie B ; modalité 5 si PUB = 2 [Agent de catégorie B de la fonction publique] de la question 
POSITION_PUBLIC_PRIVE) ;
9 (agent de catégorie C ; modalité 4 si PUB = 2 [Agent de catégorie C de la fonction publique] de la question 
POSITION_PUBLIC_PRIVE) ;
* (vide, non réponse ou modalité 7 si PUB = 1 ou 7 si PUB = 2 [Dans une autre situation] de la question POSITION_PUBLIC_PRIVE).

TAILLE = 
0 (de 1 à 10 personnes dans l'entreprise, modalités 1 [Une seule personne : vous travaillez seul(e) / vous travailliez seul(e)]
et 2 [Entre 2 et 10 personnes] de la question TAILLE_ENTREPRISE) ; 
1 (de 11 à 49 personnes dans l'entreprise, modalité 3 [Entre 11 et 49 personnes] de la question TAILLE_ENTREPRISE) ; 
2 (50 personnes et plus dans l'entreprise, modalité 4 [50 personnes ou plus] de la question TAILLE_ENTREPRISE) ;
* (vide ou non réponse à la question TAILLE_ENTREPRISE).

Ces libellés et variables peuvent correspondre à la sitation professionnelle principale de la personne enquêtée, à une activité
secondaire (si elle en exerce une) ou à une situation antérieure (notamment lorsqu'elle n'est pas en emploi à la date d'enquête), 
à la situation professionnelle d'un membre du ménage (conjoint ou enfant par exemple) ou d'un parent. 

Uniquement pour l'obtention d'une variable de PCS sur l'ensemble de la population et non seulement les actifs. 
- la variable de statut d'activité, ACTIVITE, qui distingue l'emploi (ACTIVITE = "1"), le chômage (ACTIVITE = "2") et l'inactivité 
(ACTIVITE = "3" ou de "3" à "9", selon que la variable de statut d'activité disponible dans la source correspond à l'activité BIT 
(ACTIVITE_BIT) ou à l'activité spontanéee (ACTIVITE_SPONTANEE).

Et bien sûr, un identifiant individuel IDENTIFIANT, pour permettre l'appariement des tables avec les variables créées.

*/



/*****************************/
/* Déclaration de librairies */
/*****************************/

libname SOURCE " "; /* librairie où se trouve la base de données COLLECTE avec les libellés et variables annexes issues de la 
collecte et où sera créée la base de données CODIFICATION avec les libellés et la variable VARANX pour la codification automatique */
%let cheminmatrice = ; /* chemin où se trouve la matrice de codification */



/************************************************************************************/
/* Macro de transcodage des variables annexes (passage des QUESTIONS aux VARIABLES) */
/************************************************************************************/

%macro transcodage (COLLECTE, CODIFICATION, STATUT_PUBLIC_PRIVE, POSITION_PUBLIC_PRIVE, TAILLE_ENTREPRISE, STATUT, PUB, CPF, TAILLE );

data &CODIFICATION. ; 
set SOURCE.&COLLECTE. ;

/*Variable STATUT*/
if &STATUT_PUBLIC_PRIVE in ('2','3','4') then &STATUT='1';
else if &STATUT_PUBLIC_PRIVE ='1' then &STATUT='2';
else if &STATUT_PUBLIC_PRIVE ='5' then &STATUT='3';
else &STATUT='*';

/*Variable PUB*/
if &STATUT_PUBLIC_PRIVE in ('3','4') then &PUB='1';
else if &STATUT_PUBLIC_PRIVE ='2' then &PUB='2';
else &PUB='*';

/*Variable CPF*/
if &POSITION_PUBLIC_PRIVE ='6' and &PUB='1' then &CPF='1';
else if (&POSITION_PUBLIC_PRIVE ='5' and &PUB='1') or (&POSITION_PUBLIC_PRIVE ='3' and &PUB='2') then &CPF='2';
else if &POSITION_PUBLIC_PRIVE ='4' and &PUB='1' then &CPF='3';
else if &POSITION_PUBLIC_PRIVE ='3' and &PUB='1' then &CPF='4';
else if (&POSITION_PUBLIC_PRIVE ='2' and &PUB='1') or (&POSITION_PUBLIC_PRIVE ='2' and &PUB='2') then &CPF='5';
else if (&POSITION_PUBLIC_PRIVE ='1' and &PUB='1') or  (&POSITION_PUBLIC_PRIVE ='1' and &PUB='2') then &CPF='6';
else if &POSITION_PUBLIC_PRIVE ='6' and &PUB='2' then &CPF='7';
else if &POSITION_PUBLIC_PRIVE ='5' and &PUB='2' then &CPF='8';
else if &POSITION_PUBLIC_PRIVE ='4' and &PUB='2' then &CPF='9';
else &CPF='*';

/*Variable TAILLE*/
if &TAILLE_ENTREPRISE in ('1','2') then &TAILLE='0';
else if &TAILLE_ENTREPRISE ='3' then &TAILLE='1';
else if &TAILLE_ENTREPRISE ='4' then &TAILLE='2';
else &TAILLE='*';

%mend trancodage;

/* appel de la macro */
%transcodage(COLLECTE, CODIFICATION, STATUT_PUBLIC_PRIVE, POSITION_PUBLIC_PRIVE, TAILLE_ENTREPRISE, STATUT, PUB, CPF, TAILLE); 


/******************************************************************************/
/* Macro de création de la variable annexe VARANX unique nécessaire au codage */
/******************************************************************************/

/* définition de la macro qui utilise les variables annexes de la table COLLECTE pour crééer une variable unique VARANX dans 
la table CODIFICATION, qui sera utilisée pour le codage. */
%macro varanx(CODIFICATION, STATUT, PUB, CPF, TAILLE);

data &CODIFICATION. ; 
set &CODIFICATION. ;
length VARANX $ 20; 

/* Champ où le libellé de profession est non vide. */
if LIBPROF not in (' ') then CHAMP_CODIFICATION='1';
else CHAMP_CODIFICATION = '0'; 

/*Création de la variable VARANX qui est la synthèse des 4 variables annexes (STATUT, PUB, CPF et TAILLE)*/ 
if &CPF='1' then VARANX='priv_cad';
if &CPF='2' then VARANX='priv_tec'; 
if &CPF='3' then VARANX='priv_am';
if &CPF='4' then VARANX='priv_emp'; 
if &CPF='5' then VARANX='priv_oq'; 
if &CPF='6' then VARANX='priv_opq'; 
if &CPF='7' then VARANX='pub_catA'; 
if &CPF='8' then VARANX='pub_catB'; 
if &CPF='9' then VARANX='pub_catC'; 

if &STATUT='3' then VARANX='aid_fam';

if &STATUT ='2' and &TAILLE ='*' then VARANX='inde_nr';
if &STATUT in ('2','*') and &TAILLE ='0' then VARANX='inde_0_9';
if &STATUT in ('2','*') and &TAILLE ='1' then VARANX='inde_10_49';
if &STATUT in ('2','*') and &TAILLE ='2' then VARANX='inde_sup49';

if &CPF='*' and &STATUT='1' and &PUB='2' then VARANX='pub_nr';
if &CPF='*' and &STATUT='1' and &PUB in ('1','*') then VARANX='priv_nr';

/*Aucune variable annexe n'est renseignée => sans variable annexe (ssvaran)*/
if &CPF='*' and &STATUT='*' and &TAILLE='*' and &PUB='*' then VARANX='ssvaran';

/* Situation de rattrapage, le cas ne se retrouve dans aucune règle de l'index => cas incohérent (inco)*/
if VARANX= ' '  then VARANX='cas_inco';

run; 

%mend varanx;

/* appel de la macro, qui créé la base de données CODIFICATION, qui servira à la codification automatique */
%varanx(CODIFICATION, STATUT, PUB, CPF, TAILLE); 



/**********************************************************************/
/* Import de la matrice de codification pour la PCS2020 au format CSV */
/**********************************************************************/

/* la matrice peut être télécharger sur le site nomenclature-pcs.fr ou insee.fr */
filename matrice "&cheminmatrice.\Nom_Matrice_codification_PCS2020_collecteAAAA.csv" encoding="utf-8";
proc import datafile=matrice
     out=matrice_PCS
     dbms=csv
     replace;
     getnames=yes;
	 guessingrows = max;
run;



/****************************/
/* Codification Automatique */
/****************************/

%macro codif_auto (CODIFICATION, CODAGE); /* les informations à coder sont dans la table CODIFICATION, qui contient le libellé 
LIBPROF, les variables annexes sous la forme de variable unique VARANX et un identifiant individuel IDENTIFIANT. La table créée 
avec le résultat de la codification automatique s'appelle CODAGE. Le champ où la codification pourra être analysée est défini par 
CHAMP_CODIFICATION = 1, qui correspond aux individus où les libellés sont renseignés. */

/* Normalisation des libellés */
data CODIFICATION_NORM;
set &CODIFICATION.;

LIBPROF = translate(lowcase(LIBPROF),"aaceeeeiiouu","àâçéèêëîïôùû");
LIBPROF = upcase(LIBPROF);
LIBPROF = tranwrd(LIBPROF," (","");
LIBPROF = tranwrd(LIBPROF,") ","");
LIBPROF = tranwrd(LIBPROF,"/","");
LIBPROF = tranwrd(LIBPROF, "-", "");
LIBPROF = tranwrd(LIBPROF, "'", "");
LIBPROF = tranwrd(LIBPROF, "’", "");
LIBPROF = tranwrd(LIBPROF, ",", "");
LIBPROF = tranwrd(LIBPROF, ".", "");
LIBPROF = tranwrd(LIBPROF, "Œ", "OE");
LIBPROF = tranwrd(LIBPROF," DE ","");
LIBPROF = tranwrd(LIBPROF," EN ","");
LIBPROF = tranwrd(LIBPROF," DES ","");
LIBPROF = tranwrd(LIBPROF," D ","");
LIBPROF = tranwrd(LIBPROF," L ","");
LIBPROF = tranwrd(LIBPROF," AU ","");
LIBPROF = tranwrd(LIBPROF," DU ","");
LIBPROF = tranwrd(LIBPROF," SUR ","");
LIBPROF = tranwrd(LIBPROF," AUX ","");
LIBPROF = tranwrd(LIBPROF," DANS ","");
LIBPROF = tranwrd(LIBPROF," A ","");
LIBPROF = tranwrd(LIBPROF," UN ","");
LIBPROF = tranwrd(LIBPROF," UNE ","");
LIBPROF = tranwrd(LIBPROF," ET ","");
LIBPROF = tranwrd(LIBPROF," LA ","");
LIBPROF = tranwrd(LIBPROF," LE ","");
LIBPROF = tranwrd(LIBPROF," OU ","");
LIBPROF = tranwrd(LIBPROF," POUR ","");
LIBPROF = tranwrd(LIBPROF," AVEC ","");
LIBPROF = tranwrd(LIBPROF," CHEZ ","");
LIBPROF = tranwrd(LIBPROF," PAR ","");
LIBPROF = tranwrd(LIBPROF," LES ","");
LIBPROF=compress(LIBPROF, 'A0'x,'s');
rename LIBPROF = sgnm;
run;

/* Codage pour les libellés masculins */
proc sort data=matrice_PCS;
by sgnm;
run;

proc transpose
  data=matrice_PCS
  out=table1_trans (
    rename=(col1=code _name_=varanx)
    where=(varanx ne 'sgnm')
  )
;
by sgnm;
var _all_;
run;

data want1;
set CODIFICATION_NORM;
length code $4;
if _n_ = 1
then do;
  declare hash codes (dataset:'table1_trans');
  rc = codes.definekey('sgnm','varanx');
  rc = codes.definedata('code');
  rc = codes.definedone();
end;
rc = codes.find();
drop rc;
run;

/* Codage pour les libellés féminins */
data want2;
set want1;
where code = "";
rename sgnm = sgnf;
run;

proc sort data=matrice_PCS;
by sgnf;
run;

proc transpose
  data=matrice_PCS
  out=table2_trans (
    rename=(col1=code _name_=varanx)
    where=(varanx ne 'sgnf')
  )
;
by sgnf;
var _all_;
run;

data wantfem;
set want2;
length code $4;
if _n_ = 1
then do;
  declare hash codes (dataset:'table2_trans');
  rc = codes.definekey('sgnf','varanx');
  rc = codes.definedata('code');
  rc = codes.definedone();
end;
rc = codes.find();
drop rc;
rename sgnf = sgnm;
run;

/* Concaténation du codage masculin et féminin */
data wantmasc;
set want1;
if code ne "";
run;

data &CODAGE. ;
set wantmasc wantfem;
run;

/* Ajout de la nature du libellé au fichier */

/* Natlib des libellés maculins */
proc sort data=matrice_PCS;
by sgnm;
run;

proc transpose
  data=matrice_PCS
  out=natlibM (
    rename=(col1=code_natlib _name_=natlib)
    where=(natlib = 'natlib')
  )
;
by sgnm;

var _all_;
run;

/* Natlib des libellés féminins */
proc sort data=matrice_PCS;
by sgnf;
run;

proc transpose
  data=matrice_PCS
  out=natlibF (
    rename=(col1=code_natlib _name_=natlib sgnf=sgnm )
    where=(natlib = 'natlib')
  )
;
by sgnf;

var _all_;
run;

/* Concaténation des natures de libellés */
data natlib;
set natlibM natlibF;
if sgnm ne '';
keep sgnm code_natlib ;
run;

/*Ajout de la nature du libellé à la base des libellés codés*/
proc sort data=natlib nodupkey;
by sgnm;
run;

proc sort data = &CODAGE.;
by sgnm;
run;

data &CODAGE.;
merge &CODAGE.(in=a) natlib;
if a;
by sgnm;
run;

/* création de la table SOURCE.CODAGE, avec la variable CODE_PCS2020 */
data SOURCE.&CODAGE. ;
retain IDENTIFIANT sgnm CHAMP_CODIFICATION code_natlib varanx code;
set &CODAGE.;
rename code = CODE_PCS2020;
rename sgnm=LIBPROF;
keep IDENTIFIANT sgnm CHAMP_CODIFICATION code_natlib varanx code;
run;

/* si un libellé n'est pas codé, on le met à '0000'*/
data SOURCE.&CODAGE. ;
set SOURCE.&CODAGE. ;
if CODE_PCS2020 = '' and CHAMP_CODIFICATION ="1" then CODE_PCS2020='0000';
else if code_PCS2020 ne  " " and CHAMP_CODIFICATION ="0" then CODE_PCS2020=''; 
run;

/* statistiques descriptives sur le champ où le libellé est renseigné */
proc format;
value $PCS2020_
'i'='reconnu'
'0'='reconnu'
'?'='reconnu'
'0000'='non reconnu' 
other='reconnu et codé';
run;

proc freq data=SOURCE.&CODAGE. ;
table CODE_PCS2020 /missing;
format CODE_PCS2020 $PCS2020_.;
where CHAMP_CODIFICATION;
run;

%mend codif_auto;

/* appel de la macro, qui créé la base de données SOURCE.CODAGE, avec la variable code_PCS2020, qui contient le résultat de la 
codification automatique, qui peut être estimée sur le champ correspodant aux libellés renseignés (CHAMP_CODIFICATION = 1). */
%codif_auto(CODIFICATION, CODAGE);  


