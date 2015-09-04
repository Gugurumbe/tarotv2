module type COMM = sig
  val get_config: unit -> Config.configuration Lwt.t
  val vitesse_lecture: unit -> float (* en caractères par seconde *)
  val timeout_partie: unit -> float (* en secondes *)
end

module type TIME = sig
  val gettimeofday: unit -> float
end

module type Arbitre = sig
  val accepter_identification: Bytes.t -> bool Lwt.t 
  val accepter_invitation: int -> Value.t -> bool Lwt.t
  val accepter_message: Bytes.t -> Bytes.t -> bool Lwt.t
  val timeout: unit -> float
end

module Make (Comm:COMM) (Time:TIME): Arbitre = struct
  
  open Lwt
  open Value
  open Config

  let autorisations_parler = Hashtbl.create 5

  let accepter_identification gus =
    Lwt.return (Bytes.length gus >= 3 && Bytes.length gus < 100)

  let valider_invitation n arg =
    Comm.get_config () >>= fun table ->
    try
      let verifier argument nom_court = function
        | (_, Int (minp, maxp, incrp)) ->
          let valeur = to_int
              (Hashtbl.find argument nom_court) in
          let minimum = ref 0 in
          let ok_min =
            match minp with None -> true
                          | Some m ->
                            let () = minimum := m in
                            valeur >= m
          in
          let ok_max =
            match maxp with None -> true
                          | Some m -> valeur <= m
          in
          let ok_incr =
            match incrp with None -> true
                           | Some m -> (valeur - !minimum) mod m = 0
          in
          ok_min && ok_max && ok_incr in
      let verifier_safe arg nom assoc =
        try
          if verifier arg nom assoc then ()
          else raise (Invalid_argument nom)
        with _ -> raise (Invalid_argument nom)
      in
      let argument = to_table arg in
      if Hashtbl.mem argument "nplayers" then raise (Invalid_argument "nplayers")
      else let () = Hashtbl.add argument "nplayers" (of_int n) in
        let () = Hashtbl.iter (verifier_safe argument) table in
        return ()
    with exn -> fail exn

  let accepter_invitation n arg =
    try_bind (fun () -> valider_invitation n arg)
      (fun () -> return true)
      (fun exn ->
         let () = Printf.eprintf "Warning: invitation refusée (%s)\n%!"
             (Printexc.to_string exn) in
         return false)

  let liberer_silencieux date =
    let concat gus d accu =
      if d > date then accu
      else gus :: accu
    in
    let silencieux = Hashtbl.fold concat autorisations_parler [] in
    let () = List.iter (Hashtbl.remove autorisations_parler) silencieux in
    ()

  let peut_parler date gus =
    try let debut = Hashtbl.find autorisations_parler gus in
      debut >= date
    with Not_found -> true

  let penaliser date penalite gus =
    try let delivrance = Hashtbl.find autorisations_parler gus in
      let () = Hashtbl.remove autorisations_parler gus in
      let date_theorique = delivrance +. 2. *. (delivrance -. date) in
      let date_minimale = date +. penalite in
      let date_maximale = date +. 600. in
      let delivrance = min date_maximale (max date_minimale date_theorique) in
      Hashtbl.add autorisations_parler gus delivrance
    with Not_found ->
      Hashtbl.add autorisations_parler gus (date +. (min 600. penalite))

  let accepter_message gus msg =
    let date = Time.gettimeofday () in
    let () = liberer_silencieux date in
    let penalite = (float_of_int (Bytes.length msg)) *. (Comm.vitesse_lecture ()) in
    let ok = peut_parler date gus && (Bytes.length msg < 300) in
    let () = penaliser date penalite gus in
    Lwt.return ok

  let timeout () = Comm.timeout_partie ()
end
