open Lwt

let open_connection ~pretty hote work =
  let do_client (input, output) =
    let input_stream = Lwt_io.read_chars input in
    let input_data_stream = Lwt_value.read_stream input_stream in
    let output_data_stream = work input_data_stream in
    let output_data_stream =
      Lwt_stream.concat
        (Lwt_stream.map
           (Lwt_value.print_stream ~pretty:pretty)
           output_data_stream) in
    Lwt_io.write_chars output output_data_stream
  in
  let ign _ = return () in
  let close chan () = catch
      (fun () -> Lwt_io.close chan) ign in
  let do_client (i, o) =
    do_client (i, o) >>= close i >>= close o in
  let () = async (fun () -> Lwt_io.open_connection hote >>= do_client) in
  ()

let request ~pretty host to_send =
  let (to_read, push_to_read) = Lwt_stream.create () in
  let work to_read =
    let () = async (fun () ->
        Lwt_stream.iter (function
            | Lwt_stream.Value v ->
              let () = push_to_read (Some v) in ()
            | Lwt_stream.Error exn ->
              let () = Printf.eprintf "Attention : erreur de parsage %S.\n%!" (Printexc.to_string exn) in
              let () = push_to_read None in ())
          to_read >>= fun () -> let () = push_to_read None in return ()) in
    to_send
    in
  let () = open_connection ~pretty host work in
  to_read

module Backend = struct
  let backend = ref (Unix.ADDR_INET (Unix.inet_addr_loopback, 45678))
  let requete r = request ~pretty:false !backend r
  let set_backend sockaddr = backend := sockaddr
end

module Proto_eff = Client_proto.Make (Backend)

class lwt_interface = object(self)
  val mutable config = Hashtbl.create 1
  val mutable id = ""
  val mutable joueurs_invites = []
  val mutable parametres = []
  val mutable mon_nom = ""
  val mutable mon_numero = 0
  method mon_numero = mon_numero
  method id = id
  method joueurs_invites = joueurs_invites
  method parametres = parametres
  method deconnecter =
    catch
      (fun () -> Proto_eff.effectuer_requete_logout id)
      (fun _ -> return ())
  method private set_host_unsafe addr =
    let () = Backend.set_backend addr in
    Proto_eff.effectuer_requete_config () >>= function
    | None -> fail (Failure (Printf.sprintf "Erreur : le serveur n'est pas compatible."))
    | Some cfg ->
      let () = config <- cfg in
      return cfg
  method set_host addr =
    self#deconnecter >>= fun () ->
    try_bind (fun () -> self#set_host_unsafe addr)
      (fun cfg -> return (Some cfg))
      (fun exn ->
         let () = Printf.eprintf "Warning : impossible de récupérer la config : %S.\n%!"
             (Printexc.to_string exn) in
         return None)
  method private get_id nom =
    self#deconnecter >>= fun () ->
    try_bind
      (fun () -> Proto_eff.effectuer_requete_login nom)
      (function
        | None -> return false
        | Some mon_id -> id <- mon_id; return true)
      (fun exn ->
         let () = Printf.eprintf "Warning : impossible de récupérer un ID : %S.\n%!"
             (Printexc.to_string exn) in
         return false)
  method private get_ev =
    try_bind
      (fun () -> Proto_eff.effectuer_requete_peek id)
      (function
        | None -> return None
        | Some Proto_eff.En_jeu -> return (Some Proto_eff.En_jeu)
        | Some ev ->
          try_bind
            (fun () -> Proto_eff.effectuer_requete_pop id)
            (fun () -> return (Some ev))
            (fun exn ->
               let () = Printf.eprintf "Warning : impossible de passer au message suivant : %S.\n%!"
                   (Printexc.to_string exn) in
               return (Some ev)))
      (fun exn ->
         let () = Printf.eprintf "Warning : impossible de récupérer un message : %S.\n%!"
             (Printexc.to_string exn) in
         return None)
  method private get_ev_stream =
    let fin = ref false in
    let fini () = !fin in
    let former () =
      self#get_ev >>= function
      | None -> fin := true; return None
      | Some msg when fini () -> return None
      | Some Proto_eff.En_jeu -> let () = fin := true in return (Some Proto_eff.En_jeu)
      | Some msg -> return (Some msg) in
    Lwt_stream.from former
  method identifier nom =
    let () = mon_nom <- nom in
    self#get_id nom >>= function
    | true -> return (Some (self#get_ev_stream))
    | false -> return None
  method message msg =
    catch
      (fun () -> Proto_eff.effectuer_requete_message id msg)
      (fun exn ->
         let () = Printf.eprintf "Warning : impossible d'envoyer un message : %S.\n%!"
             (Printexc.to_string exn) in
         return false)
  method inviter joueurs options =
    let () = joueurs_invites <- joueurs in
    let () = parametres <- options in
    let rec chercher i = function
      | a :: b when a <> mon_nom ->
        chercher (i + 1) b
      | _ -> i
    in
    let () = mon_numero <- chercher 0 joueurs in
    catch
      (fun () -> Proto_eff.effectuer_requete_invitation id joueurs options)
      (fun exn ->
         let () = Printf.eprintf "Warning : impossible d'envoyer une invitation : %S.\n%!"
             (Printexc.to_string exn) in
         return false)
  method annuler_invitation =
    catch
      (fun () -> Proto_eff.effectuer_requete_annulation_invitation id)
      (fun exn ->
         let () = Printf.eprintf "Warning : impossible d'annuler une invitation : %S.\n%!"
             (Printexc.to_string exn) in
         return ())
  method jeu requete =
    try Proto_eff.effectuer_requete_jeu id requete
    with exn ->
      let () = Printf.eprintf "Warning : impossible d'annuler une invitation : %S.\n%!"
          (Printexc.to_string exn) in
      let (nul, pousser) = Lwt_stream.create () in
      let () = pousser None in
      nul
  method verifier_invitation = Client_config.respecte config
end

class virtual interface = object(self)
  val interf = new lwt_interface
  val invitations: Liste_invitations.t = ref []
  val mutable prochaine_requete_jeu = 0
  method private prochaine_requete_jeu =
    let i = prochaine_requete_jeu in
    let () = prochaine_requete_jeu <- i + 1 in
    i
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
  method virtual en_jeu: (Bytes.t * Unix.sockaddr) ->
    Bytes.t array -> int ->
    (Bytes.t * Client_config.config_val) list ->
    unit
  method virtual invitations: Liste_invitations.invitation list -> unit
  method verifier_invitation = interf#verifier_invitation
  method set_host addr =
    Lwt.async (fun () ->
        interf#set_host addr >>= function
        | Some cfg ->
          let () = self#connecte cfg in
          return ()
        | None ->
          let () = self#echec_connexion () in
          return ())
  method identifier nom =
    Lwt.async (fun () ->
        interf#identifier nom >>= function
        | Some flux ->
          let () = self#identifie nom in
          Lwt_stream.iter (fun ev ->
              try match ev with
                | Proto_eff.Nouveau_joueur j -> self#nouveau_joueur j
                | Proto_eff.Depart_joueur j -> self#depart_joueur j
                | Proto_eff.Invitation (Some (invites, parametre), invitant) ->
                  let () = Liste_invitations.recevoir_invitation invitations invitant invites
                      parametre in
                  self#invitations !invitations
                | Proto_eff.Invitation (None, annulant) ->
                let () = Liste_invitations.invitation_annulee invitations annulant in
                self#invitations !invitations
                | Proto_eff.Message (parlant, message) ->
                  self#message_recu parlant message
                | Proto_eff.En_jeu ->
                  self#en_jeu
                    (interf#id, !(Backend.backend))
                    (Array.of_list interf#joueurs_invites)
                    (interf#mon_numero) (interf#parametres)
              with exn ->
                let () = Printf.eprintf "Warning : erreur en transmettant un message : %S."
                    (Printexc.to_string exn) in
                ())
            flux
        | None -> let () = self#echec_identification () in return ())
  method deconnecter =
    Lwt.async (fun () -> interf#deconnecter >>= fun () ->
                let () = self#deconnecte () in
                Lwt.return ())
  method message msg =
    Lwt.async (fun () -> interf#message msg >>= function
      | true -> let () = self#message_envoye msg in return ()
      | false -> let () = self#trop_bavard () in return ())
  method inviter joueurs options =
    Lwt.async (fun () -> interf#inviter joueurs options >>= function
      | true -> let () = self#invitation_reussie joueurs options in return ()
      | false -> let () = self#echec_invitation joueurs options in return ())
  method annuler_invitation =
    Lwt.async (fun () -> interf#annuler_invitation >>= fun () ->
                let () = self#invitation_annulee () in return ())
  method jeu requete =
    let i = self#prochaine_requete_jeu in
    let reponse = interf#jeu requete in
    let () = Lwt.async (fun () -> Lwt_stream.get reponse >>= fun rep ->
                         let () = self#reponse_jeu i rep in
                         return ()) in
    i
end
