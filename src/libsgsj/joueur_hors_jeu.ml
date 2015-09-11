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

module type Joueur_hors_jeu = sig
  type evenement = 
    | Nouveau_joueur of Bytes.t
    | Depart_joueur of Bytes.t
    | Invitation of (Bytes.t list * Value.t) option * Bytes.t
    | Message of (Bytes.t * Bytes.t)
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
open Lwt

module Make (Database:DATABASE) (Arbitre:ARBITRE) (Timeout:TIMEOUT) (Joueur_en_jeu:JOUEUR_EN_JEU): Joueur_hors_jeu = struct
  type evenement =
    | Nouveau_joueur of Bytes.t
    | Depart_joueur of Bytes.t
    | Invitation of (Bytes.t list * Value.t) option * Bytes.t
    | Message of (Bytes.t * Bytes.t)
    | En_jeu

  exception Joueur_inconnu
  exception Identification_refusee
  exception Invitation_refusee
  exception Trop_bavard

  type t = {
    nom: Bytes.t;
    id: Bytes.t;
    mutable invitation: (Bytes.t list * Value.t) option;
    evenements: evenement Queue.t;
    timeout: Timeout.t
  }

  let db: t Database.t = Database.create ()

  let with_mutex f =
    Database.lock db >>= fun () ->
    try_bind f
      (fun ret -> let () = Database.unlock db in return ret)
      (fun exn -> let () = Database.unlock db in fail exn)

  let waiting = Hashtbl.create 50

  let wait id =
    let liste = try Hashtbl.find waiting id with Not_found -> [] in
    let () = try Hashtbl.remove waiting id with Not_found -> () in
    let (t, u) = wait () in
    let () = Hashtbl.add waiting id (u :: liste) in
    t

  let wakeup id msg =
    let liste = try Hashtbl.find waiting id with Not_found -> [] in
    let () = try Hashtbl.remove waiting id with Not_found -> () in
    List.iter (fun x -> Lwt.wakeup x msg) (List.rev liste)

  let add_ev joueur msg =
    let () = Queue.push msg joueur.evenements in
    let () = wakeup joueur.id msg in
    ()
      
  let find id =
    try return (Database.find db id)
    with exn -> fail (match exn with
        | Not_found -> Joueur_inconnu
        | _ -> exn)
  let deconnecter_unsafe id =
    find id >>= fun t ->
    let informer gus =
      let () = match t.invitation with
        | None -> ()
        | _ -> add_ev gus (Invitation (None, t.nom)) in
      add_ev gus (Depart_joueur t.nom)
    in
    Database.iter informer db;
    Database.remove db id;
    Lwt.return ()
  let deconnecter id = with_mutex (fun () -> deconnecter_unsafe id)
  let nouveau_unsafe nom =
    let iter = Database.iter in
    let rec creer_id () =
      let alphabet = "0123456789AZERTYUIOPQSDFGHJKLMWXCVBNazertyuiopqsdfghjklmwxcvbn+/" in
      let n = Bytes.length alphabet in
      let lettre = Bytes.get alphabet in
      let lettre _ = lettre (Random.int n) in
      let chaine = Bytes.init 32 lettre in
      let existe = try_bind
          (fun () -> find chaine)
          (fun _ -> return true)
          (fun _ -> return false) in
      existe >>= function
      | true -> creer_id ()
      | false -> return chaine
    in
    let deja_pris = ref false in
    let examiner j = if j.nom = nom then deja_pris := true in
    iter examiner db;
    (if !deja_pris then fail Identification_refusee
     else return ()) >>= fun () ->
    Arbitre.accepter_identification nom >>= fun b ->
    (if b then creer_id ()
     else fail Identification_refusee) >>= fun id ->
    let ev = Queue.create () in
    let () = Queue.push (Nouveau_joueur nom) ev in
    let presenter j =
      let () = add_ev j (Nouveau_joueur nom) in
      Queue.push (Nouveau_joueur j.nom) ev 
    in
    let presenter_invitation j =
      match j.invitation with
      | None -> ()
        | some_i -> Queue.push (Invitation (some_i, j.nom)) ev in
    iter presenter db;
    iter presenter_invitation db;
    let nouveau = {
      nom = nom; id = id; invitation = None; evenements = ev;
      timeout = Timeout.creer (Arbitre.timeout ())
    } in
    let () = Lwt.async (fun () ->
        Timeout.attendre nouveau.timeout >>= fun () ->
        Lwt.catch
          (fun () -> deconnecter id)
          (fun _ -> Lwt.return ())) in
    Database.add db id nouveau;
    return id
  let nouveau nom = with_mutex (fun () -> nouveau_unsafe nom)
  let nom id = find id >>= fun t -> return t.nom
  let invitation id = find id >>= fun t -> return t.invitation
  let peek_message id =
    try_bind (fun () -> find id)
      (fun t ->
         Timeout.retarder t.timeout;
         try return (Queue.peek t.evenements) with
         | _ -> wait id)
      (function
        | Joueur_inconnu ->
          let est_en_jeu = Joueur_en_jeu.existe id in
          let verifier ok =
            if ok then return En_jeu
            else fail Joueur_inconnu
          in
          est_en_jeu >>= verifier
        | exn -> fail exn)        
  let next_message id = find id >>= fun t ->
    Timeout.retarder t.timeout;
    let _ = Queue.take t.evenements in
    return ()
  let dire id message =
    find id >>= fun t ->
    Timeout.retarder t.timeout;
    Arbitre.accepter_message id message >>= fun ok ->
    if not ok then fail Trop_bavard
    else let informer gus = add_ev gus (Message (t.nom, message)) in
      let () = Database.iter informer db in
      return ()
  let set_invitation_unsafe id invit =
    match invit with
    | None ->
      (* Tout le monde reçoit le message *)
      (return (Database.find db id))
      >>= (fun t ->
          Timeout.retarder t.timeout;
          let ancienne = t.invitation in
          let () = t.invitation <- None in
          match ancienne with
          | None -> return ()
          | Some ancienne ->
            return
              (Database.iter
                 (fun autre -> add_ev autre (Invitation (None, t.nom)))
                 db))
    | Some (liste, parametre) ->
      (return (Database.find db id))
      >>= (fun t ->
          Timeout.retarder t.timeout;
          let moi_present = List.exists ((=) t.nom) liste in
          let rec tous_differents = function
            | [] -> true
            | a :: b when not (List.exists ((=) a) b) ->
              tous_differents b
            | _ -> false
          in
          let tous_differents = tous_differents liste in
          let joueurs_concernes = Hashtbl.create (List.length liste) in
          let examiner autre =
            if List.exists ((=) autre.nom) liste
            then Hashtbl.add joueurs_concernes autre.nom autre
          in
          if not tous_differents || not moi_present then fail Invitation_refusee
          else return ()
            >>= (fun () -> return (Database.iter examiner db))
            >>= (fun () ->
                try let liste = List.map (Hashtbl.find joueurs_concernes) liste in
                  (Arbitre.accepter_invitation (List.length liste) parametre)
                  >>= function true -> return liste
                             | false -> fail Invitation_refusee
                with Not_found -> fail Joueur_inconnu)
            >>= (fun liste_joueurs ->
                let liste_ids = List.map (fun j -> j.id) liste_joueurs in
                let () = t.invitation <- Some (liste_ids, parametre) in
                (* On informe tout le monde *)
                (return (Database.iter 
                           (fun j ->
                              add_ev j (Invitation (Some (liste, parametre), t.nom)))
                           db))
                >>= (fun () -> return liste_ids))
            >>= (fun liste_ids ->
                (* Il ne reste plus qu'à vérifier si tout le monde est d'accord *)
                let ok = ref true in
                let examiner j =
                  match (t.invitation, j.invitation) with
                  | (None, _) -> failwith "Impossible"
                  | (Some (liste_t, param_t), Some (liste_j, param_j))
                    when Value.memes_elements Value.listes_egales param_t param_j ->
                    ()
                  | _ ->
                    ok := false
                in
                (return (Database.iter examiner db))
                >>= (fun () -> return (liste_ids, !ok)))
            >>= (fun (liste_ids, ok) ->
                if not ok then return ()
                else
                  let () = Printf.printf "L'invitation a réussi entre %s (%s).\n%!"
                      (Bytes.concat ", " liste_ids) (Value.print false parametre) in
                  Joueur_en_jeu.creer_partie liste_ids parametre))
  let set_invitation id invit = with_mutex (fun () -> set_invitation_unsafe id invit)
end
