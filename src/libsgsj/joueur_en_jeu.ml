(* -*- compile-command: "cd ../../ && make -j 5" -*- *)
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

module type Joueur_en_jeu = sig
  exception Joueur_inconnu
  exception Requete_jeu_invalide
  val creer_partie: Bytes.t list -> Value.t -> unit Lwt.t
  val existe: Bytes.t -> bool Lwt.t
  val transmettre_requete: Bytes.t -> Value.t -> Value.t Lwt.t
  val deconnecter: Bytes.t -> unit Lwt.t
end
open Lwt

module Make (Database:DATABASE) (Comm:COMM) (Timeout:TIMEOUT): Joueur_en_jeu = struct
  exception Joueur_inconnu
  exception Requete_jeu_invalide
  type partie = {
    ids: Bytes.t list;
    id_partie: Bytes.t;
    timeout: Timeout.t
  }
  
  let tables = Database.create ()
  let joueurs = Database.create () (* Contient les numéros de tables de chaque joueur *)
      
  let find id =
    try return (Database.find joueurs id) >>=
      fun id_partie -> return (Database.find tables id_partie)
    with exn -> fail (match exn with
        | Not_found -> Joueur_inconnu
        | _ -> exn)
  let find_num id t =
    let rec chercher i = function
      | [] -> raise Not_found
      | a :: _ when a = id -> i
      | _ :: b -> chercher (i + 1) b
    in
    chercher 0 t.ids
  let effectuer_requete req =
    let (requete, requeter) = Lwt_stream.create () in
    let reponse = Comm.transmettre_requete requete in
    let () = requeter (Some req) in
    let () = requeter None in
    Lwt_stream.get reponse >>=
    function Some v -> return v
           | None -> failwith "Impossible d'effectuer la requête de jeu."
  let detruire_partie t =
    List.iter (Database.remove joueurs) t.ids;
    Database.remove tables t.id_partie;
    let arguments_suppr = Hashtbl.create 0 in
    Hashtbl.add arguments_suppr "partie" (Value.of_string t.id_partie);
    effectuer_requete (Value.of_labelled "supprimer_partie" (Value.of_table arguments_suppr)) >>= fun rep ->
    Lwt.return ()
  let deconnecter id =
    find id >>= detruire_partie
  let creer_partie ids parametre =
    let params = Value.to_table parametre in
    let () = Hashtbl.add params "nplayers" (Value.of_int (List.length ids)) in
    let arguments = Value.of_table params in
    let commande = Value.of_labelled "creer_partie" arguments in
    effectuer_requete commande >>=
    function
    | Value.List [Value.String "OK"; Value.String id] ->
      let t_o = Timeout.creer (Comm.timeout_partie ()) in
      let t = {ids = ids; id_partie = id; timeout = t_o} in
      Database.add tables id t;
      List.iter (fun i -> Database.add joueurs i id) ids;
      async (fun () ->
          catch (fun () -> 
              Timeout.attendre t_o >>= fun () -> detruire_partie t)
            (fun _ -> return ()));
      return ()
    | _ -> failwith "Impossible de créer la partie :'("
  let existe id = try_bind (fun () -> find id) (fun _ -> return true) (fun _ -> return false)
  let transmettre_requete id req = find id >>= fun t ->
    let (cmd, args) = Value.to_labelled req in
    match cmd with "creer_partie" | "supprimer_partie" | "lister_parties" | "lister_joueurs_prets" | "lister_parties_terminees" ->
      fail Requete_jeu_invalide
                 | _ ->
                   let arguments = Value.to_table args in
                   let () = if Hashtbl.mem arguments "id" then Hashtbl.remove arguments "id" in
                   let () = if Hashtbl.mem arguments "partie" then Hashtbl.remove arguments "partie" in
                   let () = if Hashtbl.mem arguments "joueur" then Hashtbl.remove arguments "joueur" in
                   let () = Timeout.retarder t.timeout in
                   let () = Hashtbl.add arguments "partie" (Value.of_string t.id_partie) in
                   let () = Hashtbl.add arguments "joueur" (Value.of_int (find_num id t)) in
                   effectuer_requete (Value.of_labelled cmd (Value.of_table arguments))
  let deconnecter joueur = find joueur >>= fun p -> detruire_partie p
end
