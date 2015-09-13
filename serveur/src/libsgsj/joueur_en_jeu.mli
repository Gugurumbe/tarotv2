module type DATABASE = sig
  type 'a t
  val create: unit -> 'a t
  val add: 'a t -> Bytes.t -> 'a -> unit
  val remove: 'a t -> Bytes.t -> unit
  val find: 'a t -> Bytes.t -> 'a
end

module type TIMEOUT = sig
  type t
  val creer: float -> t
  val attendre: t -> unit Lwt.t
  val retarder: t -> unit
end

module type COMM = sig
  val transmettre_requete: Value.t Lwt_stream.t -> Value.t Lwt_stream.t
  val timeout_partie: unit -> float
end

module Make (D:DATABASE) (Comm:COMM) (T:TIMEOUT): sig
  exception Joueur_inconnu
  exception Requete_jeu_invalide
  val creer_partie: Bytes.t list -> Value.t -> unit Lwt.t
  val existe: Bytes.t -> bool Lwt.t
  val transmettre_requete: Bytes.t -> Value.t -> Value.t Lwt.t
  val deconnecter: Bytes.t -> unit Lwt.t
end
