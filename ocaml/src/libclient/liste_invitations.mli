type decision =
  | Attente
  | Refus
  | Accord

type invitation = {
  noms: Bytes.t array;
  parametres: Value.t;
  prets: decision array;
}

type t = invitation list ref

val creer: unit -> t (*... let creer () = ref [] *)

val recevoir_invitation: t -> Bytes.t -> Bytes.t list -> Value.t -> unit
val invitation_annulee: t -> Bytes.t -> unit
val concernant: Bytes.t -> invitation list -> invitation list
