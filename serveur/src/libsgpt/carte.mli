(** 

Le  module  Carte  permet de  représenter  les  78  cartes du  jeu  de
tarot. En fait,  nous avons dû en introduire une  79ème, qui est jouée
en même temps  que l'excuse, mais pas remportée  par la même personne.
Nous  l'avons  appelée  "dette  d'excuse",  en  référence  aux  règles
officielles : si la personne  ayant posé l'excuse n'est pas capable de
l'échanger contre une carte basse, elle constitue une forme de dette.

@author Vivien Kraus

 *)

(** 

La couleur.  Nous  avons dû séparer l'excuse, et puisqu'il  y en a une
deuxième,  elle dispose  de sa  propre  couleur. NB:  l'ordre n'a  pas
d'importance dans ce fichier,  sauf pour les fonctions int_of_couleur,
int_of_carte,  leurs  réciproques  carte_of_int  et  carte_of_couleur,
ainsi  que les  cartes à  appeler en  priorité. De  toutes  façons, il
existe  un  ordre  canonique  (qui  n'est  pas  celui-là,  pour  toute
réclamation voir directement  le chef du PE ^^),  mais uniquement pour
les 4 couleurs de base.

 *)
type couleur =
 | Coeur | Pique | Carreau | Trefle | Atout | Excuse

(** 

La valeur d'une carte. Rien à voir avec le fait qu'elle emporte ou non
le pli (voir  : les fonctions de comparaison), ni  le nombre de points
qu'elle remporte  (voir :  {!demipoints}). C'est simplement  le numéro
qu'il y  a sur votre  carte : 1  pour l'as (et  le petit), 11  pour le
valet (et  le 11 d'atout), 12  pour la dame, etc,  21 pour...  devinez
quoi, le 21 d'atout, 1 pour la vraie excuse (celle qui compte comme un
bout), 2 pour la fausse.  Les valeurs commencent donc à 1.

 *)
type valeur = int (*Un entier commençant à 1 !!!!! *)

(**

   Un produit [valeur * couleur]. Il existe un moyen de construire une
   carte comme en français, voir la fonction stupide de et l'opérateur
   infixe {!(%%)}.

 *)
type carte = (valeur * couleur)

(**

Les exceptions suivantes sont  levées par les fonctions de comparaison
de ou vers int.

*)

(**

Grosso modo,  levée si vous essayez  de définir une  valeur valide (<=
21) mais  incompatible avec la  couleur demandée.  Par exemple,  le 20
d'atout existe, mais pas le 20 de pique.

 *)
exception Pas_une_carte

(** 

Levée  si vous tentez  un {!couleur_of_int}  avec une  valeur négative
stricte ou supérieure à 6.

 *)
exception Pas_une_couleur

(**

Levée notamment si vous construisez une carte avec une valeur négative
(au sens LARGE !), ou strictement supérieure à 21.

 *)
exception Pas_une_valeur

(**

Une fonction  de type 'a ->  'b -> ('a, 'b),  complètement stupide. Sa
définition est [let de a b = (a, b)].

*)
val de: valeur -> couleur -> carte

(**

Retourne un nombre représentant la couleur. Il dépend de l'ordre des
couleurs.

*)
val int_of_couleur: couleur -> int

(**

La conversion se fait en enlevant 1, comme ça le compte commence à 0.

*)
val int_of_valeur: valeur -> int (*Un entier commençant à 0 !!! *)

(**

L'ordre  des  cartes  est  l'ordre alphabétique  du  couple  (couleur,
valeur).   Attention   :  rappelez-vous  qu'une  carte   est  de  type
inverse. Les numéros commencent à 0 et finissent exactement à 78 (donc
: 79 cartes).

*)
val int_of_carte: carte -> int

(** 

Les 3  fonctions suivantes impriment  les cartes. Exemples  : "petit",
"vingt-et-un",  "excuse", "dette d'excuse",  "roi de  cœur", "dix-sept
d'atout", "cinq de trèfle"

*)

val string_of_couleur: couleur -> Bytes.t

(**

   On est embêté  pour le 12 :  est-ce que c'est un cavalier  ou le 12
   d'atout ? Pour  cela, on passera en argument un  booléen qui dit si
   la carte  est un atout. Ainsi, [string_of_valeur  12 true] répondra
   douze, et [string_of_valeur 12 false] cavalier.

*)
val string_of_valeur: valeur -> bool -> Bytes.t (* bool : est_atout *)
val string_of_carte: carte -> Bytes.t

(**

   Les  3  fonctions ci-dessous  lisent  des  entiers (construits  par
   exemple  avec   les  fonctions  {!int_of_carte},  {!int_of_valeur},
   {!int_of_couleur}).

*)

val couleur_of_int: int -> couleur
val valeur_of_int: int -> valeur
val carte_of_int: int -> carte

(** 

    Les fonctions  de comparaison ci-dessous  permettent de dire  : si
    cette carte  est jouée,  puis qu'on joue  celle-ci, est-ce  que le
    joueur maître est le premier  ou le second ?  Comme dans certaines
    situations  (deux de  pique et  trois de  coeur), on  ne  peut pas
    décider,  on définit  la comparaison  au sens  strict  comme étant
    "non" dans les cas qu'on ne sait pas traiter, et la comparaison au
    sens large décide que c'est "oui" quand même.

 *)

val sup_strict: carte -> carte -> bool
val sup_large: carte -> carte -> bool
val inf_strict: carte -> carte -> bool
val inf_large: carte -> carte -> bool

(** 

    Pour  faire  un  écart,  appeler   une  carte,  il  est  utile  de
    catégoriser facilement les cartes.

*)

(** 

    Une tête est un roi, une dame, un cavalier ou un valet.

*)
val est_tete : carte -> bool

(**

   Un roi peut être  appelé, ne peut pas être écarté du  tout. NB : en
   pratique,  ça  ne sert  pas  pour  l'appel  d'une carte,  car  dans
   certaines situations  on peut appeler  une dame (voire  un cavalier
   (voire un valet)).

 *)
val est_roi: carte -> bool

(** 

    Un atout ne peut pas être écarté, sauf s'il ne reste que des bouts
    et des rois.

*)
val est_atout: carte -> bool

(** 

    Un bout ne peut pas être écarté, et en plus il est utile de savoir
    le nombre  de bouts  pour compter les  points.  Les seuls  3 bouts
    sont le  petit, le 21 et  l'excuse. La fausse excuse  n'est PAS un
    bout, c'est une carte basse.

*)
val est_bout: carte -> bool

(** 
    
    Très important : une liste de  cartes à appeler en priorité. Si on
    ne possède pas  toutes les cartes de la liste de  tête, on ne peut
    pas espérer appeler une carte d'une liste d'un élément de la queue
    de la liste.

*)
val appeler_en_priorite: carte list list
				
(** 
    
    Les quatre  valeurs suivantes sont  définies pour créer  une carte
    avec l'opérateur infixe : [roi %% Coeur] compilera facilement dans
    ce module.

*)

val roi: valeur
val dame: valeur
val cavalier: valeur
val valet: valeur

(**  

     Pour  plus  de confort,  on  peut  définir  quelques cartes  très
     utilisées.   Ainsi,  les tests  d'égalité  avec  ces cartes  sont
     facilités.

*)

val petit: carte
val excuse: carte
val vingt_et_un: carte
val fausse_excuse: carte

(** 
    
    Retourne le nombre de demi-points  de la carte seule.  Carte basse
    : 1/2 point,  roi : 5 points moins 1/2.   La vraie excuse rapporte
    normalement 4.5 points, mais vu  qu'on a rajouté une fausse excuse
    qui est une valeur basse, la vraie excuse ne vaut que 4 points.

*)
val demipoints: carte -> int

(** 

    Les opérateurs  infixes suivants  permettent de manier  des cartes
    comme un dieu.

*)

(** 

    Équivalent de {!de}. Par exemple, [1 %% Coeur] est évalué en as de
    cœur. [17 %% Atout], comme le  17 d'atout.  [1 %% Atout], c'est le
    petit, et  [21 %% Atout],  le 21.  Grâce aux  valeurs prédéfinies,
    [dame  %% Carreau]  est également  possible.  Pour  l'excuse, nous
    conseillons d'utiliser  la carte  prédéfinie {!excuse} et  sa sœur
    démoniaque la {!fausse_excuse}.

*) 
val (%%): valeur -> couleur -> carte

(**  

     Les  4   opérateurs  suivants  correspondent   aux  fonctions  de
     comparaison du type {!sup_strict}.

     Exemple :  [(roi %%  Coeur) %> (dame  %% Pique)] vaut  faux, mais
     [(dame %% Pique) %<= (roi %% Coeur)] vaut vrai.

 *)
				 
val (%>): carte -> carte -> bool
val (%>=): carte -> carte -> bool
val (%<): carte -> carte -> bool
val (%<=): carte -> carte -> bool
			  
			   
