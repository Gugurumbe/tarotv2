module type BACKEND = sig
  val requete: Value.t Lwt_stream.t -> Value.t Lwt_stream.t
end

module Make (B:BACKEND): sig
  exception Invalid_response
  type message =
    | Nouveau_joueur of Bytes.t
    | Depart_joueur of Bytes.t
    | Invitation of (Bytes.t list * Value.t) option * Bytes.t
    | Message of (Bytes.t * Bytes.t)
    | En_jeu
  val effectuer_requete_login: Bytes.t -> Bytes.t option Lwt.t
  val effectuer_requete_logout: Bytes.t -> unit Lwt.t
  val effectuer_requete_config: unit -> Client_config.configuration option Lwt.t
  val effectuer_requete_peek: Bytes.t -> message option Lwt.t
  val effectuer_requete_pop: Bytes.t -> unit Lwt.t
  val effectuer_requete_message: Bytes.t -> Bytes.t -> bool Lwt.t
  val effectuer_requete_invitation: Bytes.t -> Bytes.t list -> (Bytes.t * Client_config.config_val) list -> bool Lwt.t
  val effectuer_requete_annulation_invitation: Bytes.t -> unit Lwt.t
  val effectuer_requete_jeu: Bytes.t -> Value.t -> Value.t Lwt_stream.t
end
