type t = Value_read.t = String of Bytes.t | List of t list

exception Invalid_escaped of char
exception Invalid_character of char
exception Invalid_hex_digit of char
exception Invalid_digit of char
exception Invalid_escaped_number of int
exception Parenthesis_mismatch
exception Invalid_nonstring_char of char

exception Invalid_escape_sequence of char list
      
exception Not_labelled
exception Not_an_int
exception Not_a_float
exception Not_a_table
exception Not_a_bool
exception Not_a_string
exception Not_a_list

let read = Value_read.read
let print = Value_read.print
let liste_incluse = Comparaison.liste_incluse
let listes_egales = Comparaison.listes_egales
let memes_elements = Comparaison.memes_elements

let to_labelled = Comparaison.to_labelled
let to_int = Comparaison.to_int
let to_float = Comparaison.to_float
let to_table = Comparaison.to_table
let to_bool = Comparaison.to_bool
let to_string = function
  | String s -> s
  | _ -> raise Not_a_string
let to_list = function
  | List items -> items
  | _ -> raise Not_a_list

let of_labelled = Comparaison.of_labelled
let of_int = Comparaison.of_int
let of_float = Comparaison.of_float
let of_table = Comparaison.of_table
let of_bool = Comparaison.of_bool
let of_string str = String str
let of_list items = List items
