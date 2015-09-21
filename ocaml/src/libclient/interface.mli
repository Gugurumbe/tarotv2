class virtual interface : object
  method virtual connecte: Client_config.configuration -> unit
  method virtual echec_connexion: unit -> unit
  method virtual identifie: Bytes.t -> unit
  method virtual echec_identification: unit -> unit
  method virtual deconnecte: unit -> unit
  method virtual message_envoye: Bytes.t -> unit
  method virtual trop_bavard: unit -> unit
  method virtual invitation_reussie: Bytes.t list -> (Bytes.t * Client_config.config_val) list -> unit
  method virtual echec_invitation: Bytes.t list -> (Bytes.t * Client_config.config_val) list -> unit
  method virtual invitation_annulee: unit -> unit
  method virtual reponse_jeu: int -> Value.t option -> unit
  method virtual nouveau_joueur: Bytes.t -> unit
  method virtual depart_joueur: Bytes.t -> unit
  method virtual message_recu: Bytes.t -> Bytes.t -> unit
  method virtual en_jeu: (Bytes.t (* ID *) * Unix.sockaddr) ->
    Bytes.t array (* les noms *) ->
    int (* mon numéro *) ->
    (Bytes.t * Client_config.config_val) list (* Les paramètres *) ->
    unit
  method virtual invitations: Liste_invitations.invitation list -> unit
  method verifier_invitation: int -> (Bytes.t * Client_config.config_val) list -> bool
  method set_host: Unix.sockaddr -> unit
  method identifier: Bytes.t -> unit
  method deconnecter: unit
  method message: Bytes.t -> unit
  method inviter: Bytes.t list -> (Bytes.t * Client_config.config_val) list -> unit
  method annuler_invitation: unit
  method jeu: Value.t -> int
end
