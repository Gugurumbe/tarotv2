(* -*- compile-command: "cd ../../ && make -j 5" -*- *)
module type BACKEND = sig
  val requete: Value.t Lwt_stream.t -> Value.t Lwt_stream.t
end

module type FRONTEND = sig
  val print_exceptions_on_stderr: unit -> bool
  val send_exceptions: unit -> bool
    val timeout: unit -> float
end

open Lwt

module Make (Backend:BACKEND) (Frontend:FRONTEND) = struct
  module Comm = struct
    let get_config () = Config.get_config Backend.requete
    let vitesse_lecture () = 0.01
    let timeout_partie () = 600.
    let transmettre_requete = Backend.requete
  end
  module Time = struct
    let gettimeofday () = Unix.gettimeofday ()
  end
  module Arbitre_eff = Arbitre.Make (Comm) (Time)
  module Timeout = Videur
  module Jej = Joueur_en_jeu.Make (Database) (Comm) (Timeout)
  module Jhj = Joueur_hors_jeu.Make (Database) (Arbitre_eff) (Timeout) (Jej)
  let of_message = function
    | Jhj.Nouveau_joueur nom ->
      let table = Hashtbl.create 1 in
      let () = Hashtbl.add table "joueur" (Value.of_string nom) in
      Value.of_labelled "Nouveau_joueur" (Value.of_table table)
    | Jhj.Depart_joueur nom ->
      let table = Hashtbl.create 1 in
      let () = Hashtbl.add table "joueur" (Value.of_string nom) in
      Value.of_labelled "Depart_joueur" (Value.of_table table)
    | Jhj.Invitation (None, gus) ->
      let table = Hashtbl.create 1 in
      let () = Hashtbl.add table "joueur" (Value.of_string gus) in
      Value.of_labelled "Invitation_annulee" (Value.of_table table)
    | Jhj.Invitation (Some (types, argument), gus) ->
      let table = Hashtbl.create 3 in
      let () = Hashtbl.add table "joueur" (Value.of_string gus) in
      let () = Hashtbl.add table "invites"
          (Value.of_list (List.map Value.of_string types)) in
      let () = Hashtbl.add table "argument" argument in
      Value.of_labelled "Invitation" (Value.of_table table)
    | Jhj.Message (emetteur, msg) ->
      let table = Hashtbl.create 2 in
      let () = Hashtbl.add table "joueur" (Value.of_string emetteur) in
      let () = Hashtbl.add table "message" (Value.of_string msg) in
      Value.of_labelled "Message" (Value.of_table table)
    | Jhj.En_jeu ->
      let table = Hashtbl.create 0 in
      Value.of_labelled "En_jeu" (Value.of_table table)
  exception Too_many_arguments
  exception Too_few_arguments
  exception Invalid_command
  let effectuer_requete req =
    let (nom, arguments) = Value.to_labelled req in
    let table = Value.to_table arguments in
    let argc = Hashtbl.length table in
    let attendus n =
      if n < argc then raise Too_many_arguments
      else if n > argc then raise Too_few_arguments
    in
    let find x =
      try Hashtbl.find table x
      with Not_found -> raise (Invalid_argument x)
    in
    match nom with
    | "identifier" ->
      let () = Printf.printf "Identification demandée !\n%!" in
      let () = attendus 1 in
      (Jhj.nouveau (Value.to_string (find "nom")))
      >>= fun id -> return
        (Value.of_labelled "id" (Value.of_string id))
    | "deconnecter" ->
      let () = attendus 1 in
      (Jhj.deconnecter (Value.to_string (find "id")))
      >>= fun () -> return (Value.of_list [])
    | "configuration" ->
      let () = attendus 0 in
      Comm.get_config () >>= fun c ->
      return (Value.of_labelled "config" (Config.print_config c))
    | "peek_message" ->
      let () = attendus 1 in
      (Jhj.peek_message (Value.to_string (find "id")))
      >>= fun msg -> return (of_message msg)
    | "next_message" ->
      let () = attendus 1 in
      (Jhj.next_message (Value.to_string (find "id")))
      >>= fun () -> return (Value.of_list [])
    | "dire" ->
      let () = attendus 2 in
      (Jhj.dire (Value.to_string (find "id"))
         (Value.to_string (find "message")))
      >>= fun () -> return (Value.of_list [])
    | "inviter" ->
      let () = attendus 3 in
      let liste_joueurs = List.map (Value.to_string)
          (Value.to_list (find "invites")) in
      (Jhj.set_invitation (Value.to_string (find "id"))
         (Some (liste_joueurs, find "parametre")))
      >>= fun () -> return (Value.of_list [])
    | "annuler_invitation" ->
      let () = attendus 1 in
      (Jhj.set_invitation (Value.to_string (find "id")) None)
      >>= fun () -> return (Value.of_list [])
    | "jeu" ->
      let () = attendus 2 in
      let arguments = find "arguments" in
      let id = Value.to_string (find "id") in
      Jej.transmettre_requete id arguments
    | _ -> raise Invalid_command
  let effectuer_requete = function
    | Lwt_stream.Value req -> effectuer_requete req
    | Lwt_stream.Error err -> raise err
  let effectuer_requete req =
    try effectuer_requete req with exn -> Lwt.fail exn
  let effectuer_requete req =
    Lwt.try_bind (fun () -> effectuer_requete req)
      (fun res -> return (Value.of_labelled "OK" res))
      (fun err ->
         let () = if Frontend.print_exceptions_on_stderr () then
             Printf.eprintf "Warning: %s.\n%!" (Printexc.to_string err) in
         let res =
           Value.of_labelled "ERR"
             (Value.of_list
                (if Frontend.send_exceptions ()
                 then [Value.of_string (Printexc.to_string err)]
                 else [])) in
         return res)
  let run str =
    let t = Timeout.creer (Frontend.timeout ()) in
    let fin = Timeout.attendre t in
    let fin = Lwt.bind fin (fun () -> Lwt.return None) in
    let effectuer_requete = function
      | None -> Lwt.return None
      | Some req ->
        let () = Timeout.retarder t in
        Lwt.bind (effectuer_requete req) (fun s -> Lwt.return (Some s)) in
    let wait () = Lwt.choose [fin; Lwt.bind (Lwt_stream.get str) effectuer_requete] in
    Lwt_stream.from wait
end
