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
