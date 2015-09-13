type t =
  | String of Bytes.t
  | List of t list

type token_unescaped =
  | Nothing
  | Char_skipped of char
  | Unescaped of Bytes.t

exception Invalid_escaped of char
exception Invalid_character of char
exception Invalid_hex_digit of char
exception Invalid_digit of char
exception Invalid_escaped_number of int
exception Parenthesis_mismatch
exception Invalid_nonstring_char of char

exception Invalid_escape_sequence of char list

let read_unescaped () =
  let escape_sequence = ref [] in
  let chars = Buffer.create 80 in
  let skipped = ref true in
  let push c =
    let () = Buffer.add_char chars c in
    let () = escape_sequence := [] in
    None
  in
  let est_chiffre_hex c =
    (c >= '0' && c <= '9')
    || (c >= 'A' && c <= 'F')
    || (c >= 'a' && c <= 'f')
  in
  let est_chiffre c = c >= '0' && c <= '9' in
  let chiffre c =
    if c >= '0' && c <= '9'
    then (int_of_char c - int_of_char '0') else
    if c >= 'A' && c <= 'F'
    then (int_of_char c - int_of_char 'A' + 10) else
    if c >= 'a' && c <= 'f'
    then (int_of_char c - int_of_char 'a' + 10)
    else failwith "Pas un chiffre" in
  let resolve_escape_sequence () =
    try
      match List.rev !escape_sequence with
      | [] -> None
      | ['\\'; 'n'] -> push '\n'
      | ['\\'; 'r'] -> push '\r'
      | ['\\'; 't'] -> push '\t'
      | ['\\'; 'b'] -> push '\b'
      | ['\\'; sic]
        when sic = '\\' || sic = '\"'
             || sic = '\'' || sic = ' '
        -> push sic
      | ['\\'; 'x'; c1; c2]
        when est_chiffre_hex c1 && est_chiffre_hex c2 ->
        push (char_of_int (chiffre c1 * 16 + chiffre c2))
      | ['\\'; 'x'; c1; c2]
        when est_chiffre_hex c1 ->
        raise (Invalid_hex_digit c2)
      | ['\\'; 'x'; c]
        when est_chiffre_hex c -> None
      | ['\\'; 'x'; c] -> raise (Invalid_hex_digit c)
      | ['\\'; 'x'] -> None
      | ['\\'; c1; c2; c3]
        when est_chiffre c1
             && est_chiffre c2
             && est_chiffre c3
             && chiffre c1 * 100
                + chiffre c2 * 10
                + chiffre c3 < 256 ->
        push (char_of_int
                (chiffre c1 * 100
                 + chiffre c2 * 10
                 + chiffre c3))
      | ['\\'; c1; c2; c3]
        when est_chiffre c1
             && est_chiffre c2
             && est_chiffre c3 ->
        raise (Invalid_escaped_number
                 (chiffre c1 * 100
                  + chiffre c2 * 10
                  + chiffre c3))
      | ['\\'; _; _; c3] when not (est_chiffre c3) ->
        raise (Invalid_digit c3)
      | ['\\'; c1; c2]
        when est_chiffre c1 && est_chiffre c2
             && chiffre c1 * 100
                + chiffre c2 * 10 < 256 -> None
      | ['\\'; c1; c2]
        when est_chiffre c1 && est_chiffre c2 ->
        raise (Invalid_escaped_number
                 (chiffre c1 * 100
                  + chiffre c2 * 10))
      | ['\\'; _; c2] when not (est_chiffre c2) ->
        raise (Invalid_digit c2)
      | ['\\'; '0'] -> None
      | ['\\'; '1'] -> None
      | ['\\'; '2'] -> None
      | ['\\'; c] when est_chiffre c ->
        raise (Invalid_escaped_number (chiffre c * 100))
      | ['\\'; c] -> raise (Invalid_escaped c)
      | ['\\'] -> None
      | ['\"'] ->
        let () = skipped := true in
        let () = escape_sequence := [] in
        let str = Buffer.to_bytes chars in
        let () = Buffer.clear chars in
        Some str
      | [c] when int_of_char c < 32
                 || int_of_char c >= 127 ->
        raise (Invalid_character c)
      | [c] -> push c
      | list -> raise (Invalid_escape_sequence list)
    with exn ->
      let () = escape_sequence := List.tl !escape_sequence in
      raise exn
  in
  let read = function
    | '\"' when !skipped -> begin
        skipped := false;
        Nothing
      end
    | c when !skipped ->
      Char_skipped c
    | c -> begin
        escape_sequence := c :: !escape_sequence;
        match resolve_escape_sequence () with
        | None -> Nothing
        | Some str -> Unescaped str
      end
  in
  read

let stack_npop q =
  let rec aux acc remaining =
    if remaining = 0 then acc
    else aux ((Stack.pop q) :: acc) (remaining - 1)
  in
  aux []

let read () =
  let read_unescaped = read_unescaped () in
  let value_stack = Stack.create () in
  let n_items = Stack.create () in
  let read c =
    match (read_unescaped c) with
    | Nothing -> None
    | Char_skipped ' '
    | Char_skipped '\t'
    | Char_skipped '\r'
    | Char_skipped '\n' -> None
    | Char_skipped '(' ->
      let () = Stack.push 0 n_items in None
    | Char_skipped ')'
      when not (Stack.is_empty n_items) ->
      let list = stack_npop value_stack (Stack.pop n_items) in
      if Stack.is_empty n_items then
        Some (List list)
      else
        let () = Stack.push (List list) value_stack in
        let () = Stack.push (Stack.pop n_items + 1) n_items in
        None
    | Char_skipped ')' ->
      raise Parenthesis_mismatch
    | Char_skipped c ->
      raise (Invalid_nonstring_char c)
    | Unescaped str ->
      let v = String str in
      if Stack.is_empty n_items then Some v
      else
        let () = Stack.push v value_stack in 
        let () = Stack.push (Stack.pop n_items + 1) n_items in
        None
  in
  read

let print pretty value =
  let b = Buffer.create 80 in
  let escaped str = "\"" ^ Bytes.escaped str ^ "\"" in
  let add_line i str =
    let () = 
      if pretty
      then Buffer.add_bytes b
          (Printf.sprintf "\n%s%s"
             (Bytes.make i ' ') (escaped str))
      else Buffer.add_bytes b (escaped str) in
    i
  in
  let opn i =
    let () = if pretty then Buffer.add_char b ' ' in
    let () = Buffer.add_char b '(' in
    i + 1
  in
  let cls i =
    let () = if pretty
      then Buffer.add_bytes b
          (Printf.sprintf "\n%s"
             (Bytes.make (i - 1) ' ')) in
    let () = Buffer.add_char b ')' in
    i - 1
  in
  let rec aux indent = function
    | (to_write, 0 :: rest) ->
      let indent = cls indent in
      aux indent (to_write, rest)
    | ([], []) -> ()
    | (String str :: tl, []) ->
      let indent = add_line indent str in
      aux indent (tl, [])
    | (List lst :: tl, []) ->
      let indent = opn indent in
      aux indent (lst @ tl, [List.length lst])
    | (String str :: tl, remaining :: tlremaining) ->
       let indent = add_line indent str in
       aux indent (tl, (remaining - 1) :: tlremaining)
    | (List lst :: tl, remaining :: tlremaining) ->
      let indent = opn indent in
      aux indent (lst @ tl, (List.length lst) :: (remaining - 1)
                            :: tlremaining)
    | ([], _) -> failwith "Ne peut arriver"
  in
  let () = aux 0 ([value], []) in
  Buffer.to_bytes b
