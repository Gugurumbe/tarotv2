exception Not_a_number of Bytes.t
exception Not_an_operation of Bytes.t
exception Wrong_number_of_arguments of (Bytes.t * int * int)
exception No_operations
exception No_lambda

let rec add vlist =
  let ev = List.map eval vlist in
  List.fold_left (+) 0 ev
and substract a b =
  let a = eval a in
  let b = eval b in
  a - b
and multiply vlist =
  let fois a b = a * b in
  let ev = List.map eval vlist in
  List.fold_left fois 1 ev 
and divide a b =
  let a = eval a in
  let b = eval b in
  a / b
and modulo a b =
  let a = eval a in
  let b = eval b in
  a mod b
and eval = function
  | Value.String str ->
    begin try int_of_string str
      with _ -> raise (Not_a_number str) end
  | Value.List [] -> raise No_operations
  | Value.List (Value.String "+" :: x) -> add x
  | Value.List [Value.String "-"; a; b] -> substract a b
  | Value.List (Value.String "-" :: ops) ->
    raise (Wrong_number_of_arguments
             ("-", (List.length ops), 2))
  | Value.List (Value.String "*" :: x) -> multiply x
  | Value.List [Value.String "/"; a; b] -> divide a b
  | Value.List (Value.String "/" :: ops) ->
    raise (Wrong_number_of_arguments
             ("/", (List.length ops), 2))
  | Value.List [Value.String "%"; a; b] -> modulo a b
  | Value.List (Value.String "%" :: ops) ->
    raise (Wrong_number_of_arguments
             ("%", (List.length ops), 2))
  | Value.List (Value.String op :: _) ->
    raise (Not_an_operation op)
  | Value.List (Value.List _ :: _) ->
    raise No_lambda

let run_calculation calc =
  Value.List [Value.String "ok";
              Value.String (string_of_int (eval calc))]

let run_calculation = function
  | Lwt_stream.Value c -> run_calculation c
  | Lwt_stream.Error exn -> raise exn

let run_calculation calc =
  try run_calculation calc
  with exn -> Value.String (Printexc.to_string exn)

let run_calculation items =
  Lwt_stream.map (run_calculation) items
