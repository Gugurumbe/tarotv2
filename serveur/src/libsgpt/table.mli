val nouvelle_partie: Carte.carte list array list -> Bytes.t option
val lister_parties: unit -> Bytes.t list
(* Les fonctions suivantes peuvent lever Not_found *)
val trouver_partie: Bytes.t -> Partie.t
val supprimer_partie: Bytes.t -> unit
val lister_joueurs_prets: unit -> (Bytes.t * int) list
(* Liste des joueurs qui ont un message *)
val lister_parties_terminees: unit -> (Bytes.t * int array) list
