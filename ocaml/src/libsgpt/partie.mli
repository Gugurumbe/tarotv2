type evenement = 
  | NouvelleManche
  | Enchere
  | Appel
  | ChienDevoile
  | EcartEffectue
  | Jeu
  | PoigneeMontree
  | CarteJouee
  | PliTermine
  | MancheTerminee

type message = {
  evenement: evenement;
  mon_numero: int;
  numero_manche: int;
  mon_jeu: Carte.carte array;
  chien: Carte.carte array;
  encheres: int array;
  preneur: int option;
  carte_appelee: Carte.carte option;
  ecart: Carte.carte option array;
  (* Éventuellement (si l'écart est fait), une liste contenant
     éventuellement les atouts écartés. *)
  chelem_demande: bool option;
  poignees_montrees: Carte.carte array array;
  entameur: int option;
  pli_en_cours: Carte.carte array array;
  (* "list list" : si qqn joue l'excuse, il joue les 2 à la fois. *)
  dernier_entameur: int option;
  dernier_pli: Carte.carte array array;
  score: int array;
  doit_priser: bool;
  doit_appeler: bool;
  doit_ecarter: bool;
  doit_decider_chelem: bool;
  peut_montrer_poignee: bool;
  (* Faux si j'ai strictement moins de 8 * (atout ou excuse), en
     piochant dans l'écart si je suis le preneur. *)
  doit_jouer: bool;
}

type t

val peek_message: t -> int -> message option
val next_message: t -> int -> unit
val partie_terminee: t -> int array option
(* None : pas terminé *)
(* Some score : terminé *)
val distribuer: int array -> Carte.carte list array
(* La graine *)
val creer_partie: Carte.carte list array list -> t option
(* Renvoie None si c'est pas valide (petit sec, ...) *)
val verifier_enchere: t -> int -> int -> bool
val verifier_appel: t -> int -> Carte.carte -> bool
val verifier_ecart: t -> int -> Carte.carte list -> bool
val verifier_chelem: t -> int -> bool -> bool
val verifier_poignee: t -> int -> Carte.carte list -> bool
val verifier_jeu: t -> int -> Carte.carte -> bool
(* Les fonctions suivantes lèvent Failure "Invalide" *)
val enchere: t -> int -> int -> unit
val appel: t -> int -> Carte.carte -> unit
val ecart: t -> int -> Carte.carte list -> unit
val chelem: t -> int -> bool -> unit
val poignee: t -> int -> Carte.carte list -> unit
val jeu: t -> int -> Carte.carte -> unit
