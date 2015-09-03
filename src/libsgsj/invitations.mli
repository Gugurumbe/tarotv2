module type Data = sig
  type t
  val eq: t -> t -> bool
end

module Make (Parametre:Data): sig
  val exists: Bytes.t -> bool
  val set: Bytes.t -> (Bytes.t list * Parametre.t) option -> unit
  val get: Bytes.t -> (Bytes.t list * Parametre.t) option
  val get_ready: unit -> (Bytes.t list * Parametre.t) list
end
