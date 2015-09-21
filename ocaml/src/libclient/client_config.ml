open Value

exception SGPT_error of Bytes.t
exception Invalid_server_response

type config_type =
  | Int of (int option * int option * int option)
  (* Minimum - maximum - incrément *)
  | Bool

type config_val =
  | Int_val of int
  | Bool_val of bool

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

let respecte cfg nplayers liste =
  let a_trouver = Hashtbl.fold (fun nom (_, t) accu -> (nom, t) :: accu) cfg [] in
  let donnees = ("nplayers", Int_val(nplayers)) :: liste in
  let sup x = function
    | None -> true
    | Some y -> x >= y in
  let inf x = function
    | None -> true
    | Some y -> x <= y in
  let modulo x = function | None -> 0
                          | Some y -> x mod y
  in
  let moins x = function
    | None -> x
    | Some y -> x - y in
  let rec verifier a_trouver donnees =
    match donnees with
    | [] -> a_trouver = []
    | (d, v) :: reste ->
      let (trouve, reste_a_trouver) = List.partition (fun (a, _) -> a = d) a_trouver in
      match (trouve, v) with
      | ((_, Bool) :: r, Bool_val _) ->
        let reste_a_trouver = r @ reste_a_trouver in
        verifier reste_a_trouver reste
      | ((_, Int (min, max, incr)) :: r, Int_val i)
        when sup i min && inf i max && modulo (moins i min) incr = 0 ->
        let reste_a_trouver = r @ reste_a_trouver in
        verifier reste_a_trouver reste
      | _ -> false
  in
  verifier a_trouver donnees

let _ = Callback.register "caml_config_respecte"
    respecte
