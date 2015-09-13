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

let print_config c =
  let table_elements = Hashtbl.create (Hashtbl.length c) in
  let () = Hashtbl.iter (fun nom_court (nom_long, opt) ->
      let table_opt = Hashtbl.create 5 in
      let () = Hashtbl.add table_opt "name" (of_string nom_long) in
      let () =
        match opt with
        | Int (a, b, c) ->
          let () = Hashtbl.add table_opt "type" (of_string "int") in
          let add_opt cle = function
            | None -> ()
            | Some i -> Hashtbl.add table_opt cle (of_string (string_of_int i))
          in
          let () = add_opt "min" a in
          let () = add_opt "max" b in
          let () = add_opt "incr" c in
          ()
      in
      let v = of_table table_opt in
      Hashtbl.add table_elements nom_court v)
      c in
  of_table table_elements
        
