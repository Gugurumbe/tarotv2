type t = String of Bytes.t | List of t list

exception Invalid_escaped of char
exception Invalid_character of char
exception Invalid_hex_digit of char
exception Invalid_digit of char
exception Invalid_escaped_number of int
exception Parenthesis_mismatch
exception Invalid_nonstring_char of char
    
exception Invalid_escape_sequence of char list
(* Should not happen *)

val read: unit -> (char -> t option)

val print: bool -> t -> Bytes.t
(* "pretty" or not *)
                          
val liste_incluse: (t -> t -> bool) -> (* Test d'égalité entre deux éléments *)
  t -> t -> (* Les deux listes à comparer *)
  bool

val listes_egales: t -> t -> bool (* Au sens de Pervasives.compare *)
val memes_elements:(t -> t -> bool) -> (* Test d'égalité entre deux éléments *)
  t -> t -> (* Les deux listes à comparer *)
  bool (* vrai ssi l'une est incluse dans l'autre et l'autre dans l'une. *)
(* Elles doivent comporter exactement les mêmes éléments en même nombre (au sens de la fonction de comparaison). *)

exception Not_labelled (* Pas sous la forme List [String nom; argument] *)
exception Not_an_int (* Pas sous la forme String "42" *)
exception Not_a_float (* Ni sous la forme String "42", ni sous la forme String "42.3" *)
exception Not_a_table (* Pas sous la forme d'une List ne contenant que des label.*)
exception Not_a_bool (* Ni String "true", ni String "false" *)
exception Not_a_string
exception Not_a_list

val to_labelled: t -> Bytes.t * t
val to_int: t -> int
val to_float: t -> float
val to_table: t -> (Bytes.t, t) Hashtbl.t
val to_bool: t -> bool
val to_string: t -> Bytes.t
val to_list: t -> t list

val of_labelled: Bytes.t -> t -> t
val of_int: int -> t
val of_float: float -> t
val of_table: (Bytes.t, t) Hashtbl.t -> t
val of_bool: bool -> t
val of_string: Bytes.t -> t
val of_list: t list -> t
