(* -*- compile-command: "cd ../../ && make -j 5" -*- *)
module type ARBITRE = sig
  val accepter_identification: Bytes.t -> bool Lwt.t (* Sous réserve qu'il n'est pas déjà pris *)
  val accepter_invitation: int -> Value.t -> bool Lwt.t
  val accepter_message: Bytes.t -> Bytes.t -> bool Lwt.t
  val timeout: unit -> float
end

module type DATABASE = sig
  type 'a t
  val create: unit -> 'a t
  val add: 'a t -> Bytes.t -> 'a -> unit
  val remove: 'a t -> Bytes.t -> unit
  val iter: ('a -> unit) -> 'a t -> unit
  val find: 'a t -> Bytes.t -> 'a
  val lock: 'a t -> unit Lwt.t
  val unlock: 'a t -> unit
end

module type TIMEOUT = sig
  type t
  val creer: float -> t
  val attendre: t -> unit Lwt.t
  val retarder: t -> unit
end

module type JOUEUR_EN_JEU = sig
  val existe: Bytes.t -> bool Lwt.t
  val creer_partie: Bytes.t list -> Value.t -> unit Lwt.t
end

module Make (D:DATABASE) (A:ARBITRE) (T:TIMEOUT) (Joueur_en_jeu:JOUEUR_EN_JEU): sig
  type evenement = 
    | Nouveau_joueur of Bytes.t
    | Depart_joueur of Bytes.t
    | Invitation of (Bytes.t list * Value.t) option * Bytes.t
    | Message of (Bytes.t * Bytes.t) (* nom - contenu *)
    | En_jeu
  exception Joueur_inconnu
  exception Identification_refusee
  exception Invitation_refusee
  exception Trop_bavard
  val nouveau: Bytes.t -> Bytes.t Lwt.t (* L'id *)
  val deconnecter: Bytes.t -> unit Lwt.t
  val nom: Bytes.t -> Bytes.t Lwt.t (* id -> nom *)
  val invitation: Bytes.t -> (Bytes.t list * Value.t) option Lwt.t (* ids des joueurs invités *)
  val peek_message: Bytes.t -> evenement Lwt.t
  val next_message: Bytes.t -> unit Lwt.t
  val dire: Bytes.t -> Bytes.t -> unit Lwt.t
  val set_invitation: Bytes.t -> (Bytes.t list * Value.t) option -> unit Lwt.t
end
