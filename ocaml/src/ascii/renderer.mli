type portion =
  | Complet
  | Partiel

val render_cartes: bool -> (portion * int) list -> Bytes.t list
