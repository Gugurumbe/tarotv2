open Value

exception SGPT_error of Bytes.t
exception Invalid_server_response

type config_type =
  | Int of (int option * int option * int option)
  (* Minimum - maximum - incrément *)

type configuration = (Bytes.t, (Bytes.t * config_type)) Hashtbl.t

let read_config_opt x =
  let table = to_table x in
  let find = Hashtbl.find table in
  let find_opt x =
    try Some (to_int (find x))
    with Not_found -> None in
  match to_string (find "type") with
  | "int" -> (to_string (find "name"), Int (find_opt "min", find_opt "max", find_opt "incr"))
  | _ -> raise Invalid_server_response

let read_config rep =
  try
    let (res, arg) = to_labelled rep in
    if res = "ERR"
    then raise (SGPT_error (to_string arg))
    else
      let table = to_table arg in
      let r = Hashtbl.create (Hashtbl.length table) in
      let () = Hashtbl.iter (fun nom_court x ->
          Hashtbl.add r nom_court (read_config_opt x))
          table in
      r
  with exn ->
    let () = Printf.printf "Warning: %S.\n%!" (Printexc.to_string exn) in
    raise Invalid_server_response

let get_config envoyer_requete =
  let (requete, requeter) = Lwt_stream.create () in
  let () = requeter (Some (of_labelled "config" (List []))) in
  let reponse = envoyer_requete requete in
  let (>>=) = Lwt.bind in
  Lwt_stream.get reponse
  >>= (fun item ->
      let () = requeter None in
      match item with
      | None -> Lwt.fail Invalid_server_response
      | Some rep ->
        try
          let cfg = read_config rep in
          Lwt.return cfg
        with exn -> Lwt.fail exn)

let valider_invitation envoyer_requete njoueurs argument =
  let open Lwt in
  (get_config envoyer_requete)
  >>= (fun table ->
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
        let argument = to_table argument in
        if Hashtbl.mem argument "nplayers" then raise (Invalid_argument "nplayers")
        else let () = Hashtbl.add argument "nplayers" (of_int njoueurs) in
          let () = Hashtbl.iter (verifier_safe argument) table in
          Lwt.return ()
      with exn -> Lwt.fail exn)
