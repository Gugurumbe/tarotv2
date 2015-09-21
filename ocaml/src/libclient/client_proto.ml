module type BACKEND = sig
  val requete: Value.t Lwt_stream.t -> Value.t Lwt_stream.t
end

open Lwt
open Value

module type Client_proto_sig = sig
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

module Make (Backend:BACKEND) : Client_proto_sig = struct
  exception Invalid_response
  type message =
    | Nouveau_joueur of Bytes.t
    | Depart_joueur of Bytes.t
    | Invitation of (Bytes.t list * Value.t) option * Bytes.t
    | Message of (Bytes.t * Bytes.t)
    | En_jeu
  let to_message ev =
    let to_stringlist list =
      List.map to_string (to_list list)
    in
    try let (t, args) = to_labelled ev in
      let a = to_table args in
      let find = Hashtbl.find a in
      let find_string x = to_string (find x) in
      let find_stringlist x = to_stringlist (find x) in
      match t with
      | "Nouveau_joueur" -> Nouveau_joueur (find_string "joueur")
      | "Depart_joueur" -> Depart_joueur (find_string "joueur")
      | "Invitation_annulee" -> Invitation (None, find_string "joueur")
      | "Invitation" -> Invitation (Some (find_stringlist "invites",
                                          find "argument"),
                                    find_string "joueur")
      | "Message" -> Message (find_string "joueur", find_string "message")
      | "En_jeu" -> En_jeu
      | x -> failwith (Printf.sprintf "Invalid SGSJ message type %S." x)
    with exn ->
      let () = Printf.eprintf "Warning : invalid SGSJ message syntax %S.\n%!"
          (print false ev) in
      raise Invalid_response
  let effectuer_requete req =
    let (flux, pousser) = Lwt_stream.create () in
    let () = pousser (Some req) in
    let () = pousser None in
    let reponse = Backend.requete flux in
    Lwt_stream.get reponse >>= function
    | None -> fail Invalid_response
    | Some c -> return c
  let effectuer_requete cmd args =
    effectuer_requete (of_labelled cmd (of_table args)) >>= function
    | List [String "ERR"; List []] -> return None
    | List [String "OK"; r] -> return (Some r)
    | v -> let () = Printf.eprintf "Warning : invalid sgsj response %S.\n%!" (print false v) in
      Lwt.fail Invalid_response
  let effectuer_requete cmd arg_list =
    let table = Hashtbl.create (List.length arg_list) in
    let () = List.iter (fun (nom, v) -> Hashtbl.add table nom v) arg_list in
    effectuer_requete cmd table
  let effectuer_requete_login nom =
    effectuer_requete "identifier" [("nom", String nom)] >>= function
    | None -> return None
    | Some (List [String "id"; String id]) -> return (Some id)
    | Some v ->
      let () = Printf.eprintf "Warning : invalid login response %S.\n%!" (print false v) in
      fail Invalid_response
  let ignore _ = return ()
  let effectuer_requete_logout id =
    effectuer_requete "deconnecter" [("id", String id)] >>= ignore
  let effectuer_requete_config () =
    effectuer_requete "configuration" [] >>= function
    | None -> return None
    | Some (List [String "config"; cfg]) ->
      begin try let cfg = Client_config.read_config cfg in return (Some cfg)
        with exn ->
          let () = Printf.eprintf "Warning : invalid config response %S (%s).\n%!"
              (print false cfg) (Printexc.to_string exn) in
          fail Invalid_response end
    | Some v ->
      let () = Printf.eprintf "Warning : invalid config response %S.\n%!"
          (print false v) in
      fail Invalid_response
  let effectuer_requete_peek id =
    effectuer_requete "peek_message" [("id", String id)] >>= function
    | None -> return None
    | Some msg -> return (Some (to_message msg))
  let effectuer_requete_pop id =
    effectuer_requete "next_message" [("id", String id)] >>= ignore
  let effectuer_requete_message id msg =
    effectuer_requete "dire" [("id", String id); ("message", String msg)] >>= function
    | None -> return false
    | Some _ -> return true
  let effectuer_requete_invitation id invites parametres =
    let table = Hashtbl.create (List.length parametres) in
    let () = List.iter (function
        | (nom, Client_config.Int_val i) -> Hashtbl.add table nom (of_int i)
        | (nom, Client_config.Bool_val b) -> Hashtbl.add table nom (of_bool b))
        parametres in
    effectuer_requete "inviter" [("id", String id); ("invites", List (List.map of_string invites));
                                 ("arguments", Value.of_table table)] >>= function
    | None -> return false
    | Some _ -> return true
  let effectuer_requete_annulation_invitation id =
    effectuer_requete "annuler_invitation" [("id", String id)] >>= ignore
  let effectuer_requete_jeu id args =
    let a = Hashtbl.create 2 in
    let () = Hashtbl.add a "id" (String id) in
    let () = Hashtbl.add a "arguments" args in
    let req = of_labelled "jeu" (of_table a) in
    let (flux, pousser) = Lwt_stream.create () in
    let () = pousser (Some req) in
    let () = pousser None in
    Backend.requete flux
end
