exception SGPT_error of Bytes.t
exception Invalid_server_response

type config_type =
  | Int of (int option * int option * int option)
  (* Minimum - maximum - incrément *)

type configuration = (Bytes.t, (Bytes.t * config_type)) Hashtbl.t

val get_config:
  (Value.t Lwt_stream.t -> Value.t Lwt_stream.t) ->
  (* Fonction pour effectuer une requête de jeu *)
  configuration Lwt.t

val valider_invitation:
  (Value.t Lwt_stream.t -> Value.t Lwt_stream.t) ->
  (* Fonction pour effectuer une requête de jeu *)
  int -> Value.t -> unit Lwt.t
(* Lève Invalid_argument nom_de_l_argument si un argument manque ou n'est pas correct *)
