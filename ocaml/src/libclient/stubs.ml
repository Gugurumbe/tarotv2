type t_interface_handler

type t_stubs_interface = (int * t_interface_handler)

type configuration = (Bytes.t * Bytes.t * Client_config.config_type) array

let embed_to_c table =
  let liste = Hashtbl.fold (fun nom_court (nom_long, t) accu ->
      (nom_court, nom_long, t) :: accu) table [] in
  Array.of_list liste

external connecte: t_stubs_interface ->
  configuration ->
  unit = "caml_connecte"
external echec_connexion: t_stubs_interface ->
  unit = "caml_echec_connexion"
external identifie: t_stubs_interface ->
  Bytes.t ->
  unit = "caml_identifie"
external echec_identification: t_stubs_interface ->
  unit = "caml_echec_identification"
external deconnecte: t_stubs_interface ->
  unit = "caml_deconnecte"
external message_envoye: t_stubs_interface ->
  unit = "caml_message_envoye"
external trop_bavard: t_stubs_interface ->
  unit = "caml_trop_bavard"
external invitation_reussie: t_stubs_interface ->
  unit = "caml_invitation_reussie"
external echec_invitation: t_stubs_interface ->
  unit = "caml_echec_invitation"
external invitation_annulee: t_stubs_interface ->
  unit = "caml_invitation_annulee"
external reponse_jeu: t_stubs_interface ->
  int ->
  Value.t option ->
  unit = "caml_reponse_jeu"
external nouveau_joueur: t_stubs_interface ->
  Bytes.t ->
  unit = "caml_nouveau_joueur"
external depart_joueur: t_stubs_interface ->
  Bytes.t ->
  unit = "caml_depart_joueur"
external message_recu: t_stubs_interface ->
  Bytes.t ->
  Bytes.t ->
  unit = "caml_message_recu"
external en_jeu: t_stubs_interface ->
  (Bytes.t * Unix.sockaddr) ->
  Bytes.t array -> int ->
  (Bytes.t * Client_config.config_val) list ->
  (* paramètres *)
  unit = "caml_en_jeu"
external invitations_modifiees: t_stubs_interface ->
  Liste_invitations.invitation list ->
  unit
  = "caml_invitations_modifiees"
external about_to_delete: t_stubs_interface ->
  unit
  = "caml_about_to_delete"

class stubs_interface id = object(self)
  inherit Interface.interface
  method connecte c = connecte id (embed_to_c c)
  method echec_connexion () = echec_connexion id
  method identifie = identifie id
  method echec_identification () = echec_identification id
  method deconnecte () = deconnecte id
  method message_envoye _ = message_envoye id
  method trop_bavard () = trop_bavard id
  method invitation_reussie _ _ = invitation_reussie id
  method echec_invitation _ _ = echec_invitation id
  method invitation_annulee () = invitation_annulee id
  method reponse_jeu = reponse_jeu id
  method nouveau_joueur = nouveau_joueur id
  method depart_joueur = depart_joueur id
  method message_recu = message_recu id
  method en_jeu = en_jeu id
  method invitations = invitations_modifiees id
  method send_delete_signal = about_to_delete id
end

module Int = struct
  type t = int
  let compare = Pervasives.compare
end

module IntMap = Map.Make (Int)

let (interfaces: stubs_interface IntMap.t ref) = ref (IntMap.empty)

exception Interface_not_found

let apply_to f id =
  let i =
    try IntMap.find id !interfaces
    with Not_found -> raise Interface_not_found in
  f i

let _ = Callback.register "caml_alloc_interface"
    (fun handler -> let id = try
                   fst (IntMap.max_binding !interfaces)
                 with Not_found -> 0 in
      let nouveau = new stubs_interface (id, handler) in
      let () =
        interfaces := IntMap.add id nouveau !interfaces in
      id)
       
let _ = Callback.register "caml_delete_interface"
    (fun id ->
       let () = apply_to (fun i -> i#send_delete_signal) id in
       let () = interfaces := IntMap.remove id !interfaces in ())

let _ = Callback.register "caml_verifier_invitation"
    (apply_to (fun i -> i#verifier_invitation))

let _ = Callback.register "caml_set_host"
    (apply_to (fun i -> i#set_host))

let _ = Callback.register "caml_identifier"
    (apply_to (fun i -> i#identifier))

let _ = Callback.register "caml_deconnecter"
    (apply_to (fun i -> i#deconnecter))

let _ = Callback.register "caml_message"
    (apply_to (fun i -> i#message))

let _ = Callback.register "caml_inviter"
    (apply_to (fun i -> i#inviter))

let _ = Callback.register "caml_annuler_invitation"
    (apply_to (fun i -> i#annuler_invitation))

let _ = Callback.register "caml_jeu"
    (apply_to (fun i -> i#jeu))
