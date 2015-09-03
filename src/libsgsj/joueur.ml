module type INVITATIONS =
sig
  val exists: Bytes.t -> bool
  val set: Bytes.t -> (Bytes.t list * Value.t) option -> bool Lwt.t
  val get: Bytes.t -> (Bytes.t list * Value.t) option
end

module Make (Inv:INVITATIONS) =
  struct
    type evenement =
      | Nouveau_joueur of Bytes.t
      | Depart_joueur of Bytes.t
      | Invitation of (Bytes.t list * Value.t) option * Bytes.t
                      
    class type joueur = object
      method nom: Bytes.t
      method id: Bytes.t
      method id_jeu: (Bytes.t * int) option
      method inviter: Bytes.t list * Value.t -> bool Lwt.t
      method annuler_invitation: unit
      method entrer_en_jeu: Bytes.t -> int -> unit
      method peek_event: evenement option
      method add_event: evenement -> unit
    end
  end
