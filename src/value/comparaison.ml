open Value_read

let rec transferer dest = function
  | [] -> dest
  | a :: b -> transferer (a :: dest) b

let rec sauf_un accu f = function
  | a :: b when not (f a) -> sauf_un (a :: accu) f b
  | _ :: b ->
    transferer b accu
  | [] -> transferer [] accu

let sauf_un f = sauf_un [] f

let rec liste_incluse egal x y =
  match (x, y) with
  | (List [], List _) -> true
  | (List (x :: tx), List y) when List.exists (egal x) y ->
    liste_incluse egal (List tx) (List (sauf_un (egal x) y))
  | _ -> false

let listes_egales = (=)

let memes_elements egal x y = liste_incluse egal x y && liste_incluse egal y x

exception Not_labelled
exception Not_an_int
exception Not_a_float
exception Not_a_table
exception Not_a_bool

let to_labelled = function
  | List [String a; b] -> (a, b)
  | _ -> raise Not_labelled

let to_int = function
  | List _ -> raise Not_an_int
  | String i ->
    try int_of_string i
    with _ -> raise Not_an_int

let to_float = function
  | List _ -> raise Not_a_float
  | String x ->
    try float_of_string x
    with _ -> try float_of_int (int_of_string x)
      with _ -> raise Not_a_float

let to_table = function
  | String _ -> raise Not_a_table
  | List items ->
    let table = Hashtbl.create (List.length items) in
    try
      let items = List.map to_labelled items in
      let () = List.iter (fun (name, value) -> Hashtbl.add table name value)
          items in
      table
    with Not_labelled -> raise Not_a_table

let to_bool = function
  | String "true" -> true
  | String "false" -> false
  | _ -> raise Not_a_bool

let of_labelled name v = List [String name; v]

let of_int i = String (string_of_int i)
let of_float f = String (string_of_float f)
let of_table t =
  let liste = Hashtbl.fold (fun n v acc -> (of_labelled n v) :: acc)
      t [] in
  let comparer a b =
    match (a, b) with
    | (List [String a; _], List [String b;_]) ->
      Bytes.compare a b
    | _ -> failwith "Ne peut arriver"
  in
  let liste_triee = List.sort comparer liste in
  List liste_triee
let of_bool (b: bool): t = String (if b then "true" else "false")
