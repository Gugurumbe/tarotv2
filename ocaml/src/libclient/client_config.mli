exception Invalid_server_response

type config_type =
  | Int of (int option * int option * int option)
  (* Minimum - maximum - incrément *)
  | Bool

type config_val =
  | Int_val of int
  | Bool_val of bool

type configuration = (Bytes.t, (Bytes.t * config_type)) Hashtbl.t
val read_config: Value.t -> configuration
val respecte: configuration -> int -> (Bytes.t * config_val) list -> bool
(* Config, nombre de joueurs, paramètres *)
