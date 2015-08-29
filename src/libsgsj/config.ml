open Value
    
exception Invalid_constraint of Bytes.t * Bytes.t
exception Invalid_option of Bytes.t
exception Invalid_config_elt of Bytes.t

type config_type =
  | Int of (int option * int option * int option)
  (* Minimum - maximum - incrément *)

type configuration = {
  min_players: int;
  max_players: int;
  options: (Bytes.t, config_type) Hashtbl.t
}

let read_config_opt = function
  | List (String intitule :: String "int" :: constraints) ->
    let min = ref None in
    let max = ref None in
    let increment = ref None in
    let iter_constraint = function
      | List [String "min"; String m] ->
        min := Some (int_of_string m)
      | List [String "max"; String m] ->
        max := Some (int_of_string m)
      | List [String "increment"; String i] ->
        increment := Some (int_of_string i)
      | c -> raise (Invalid_constraint
                      ("int", Value.print false c))
    in
    let () = List.iter iter_constraint constraints in
    (intitule, Int (!min, !max, !increment))
  | c -> raise (Invalid_option (Value.print false c))

let read_config = function
  | List elements ->
    let min_players = ref 0 in
    let max_players = ref max_int in
    let options = Hashtbl.create 10 in
    let iter = function
      | List [String "min_players"; String min] ->
        min_players := int_of_string min
      | List [String "max_players"; String max] ->
        max_players := int_of_string max
      | List [String "options"; List opt] ->
        List.iter
          (fun opt ->
             let (nom, t) = read_config_opt opt in
             Hashtbl.add options nom t)
          opt
      | c -> raise (Invalid_config_elt (Value.print false c))
    in
    let () = List.iter iter elements in
    {min_players = !min_players; max_players = !max_players;
     options = options}
  | String str ->
    failwith
      (Printf.sprintf
         "Que voulez-vous que je fasse de %s, M. SGPT ?"
         str)

let get_config envoyer_requete () =
  let (requete, requeter) = Lwt_stream.create () in
  let () = requeter (Some (String "config")) in
  let reponse = envoyer_requete requete in
  let (>>=) = Lwt.bind in
  Lwt_stream.get reponse
  >>= (fun item ->
      let () = requeter None in
      match item with
      | None -> Lwt.fail (Failure "SGPT n'a pas répondu")
      | Some rep ->
        try
          let cfg = read_config rep in
          Lwt.return cfg
        with exn -> Lwt.fail exn)
