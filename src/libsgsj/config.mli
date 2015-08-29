exception Invalid_constraint of Bytes.t * Bytes.t
exception Invalid_option of Bytes.t
exception Invalid_config_elt of Bytes.t

type config_type =
  | Int of (int option * int option * int option)
  (* Minimum - maximum - incrément *)

type configuration = {
  min_players: int;
  max_players: int;
  options: (Bytes.t, config_type) Hashtbl.t
}

val get_config:
  (Value.t Lwt_stream.t -> Value.t Lwt_stream.t) ->
  (* Fonction pour effectuer une requête de jeu *)
  (unit -> configuration Lwt.t)
