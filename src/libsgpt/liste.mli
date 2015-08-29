(* Une liste de cartes *)
type t
val aucune: unit -> t
val toutes: unit -> t
val to_list: t -> Carte.carte list
val of_list: Carte.carte list -> t
val union: t list -> t
val intersection: t list -> t
val contraire: t -> t
val difference: t -> t -> t
val filtrer: (Carte.carte -> bool) -> t -> t
