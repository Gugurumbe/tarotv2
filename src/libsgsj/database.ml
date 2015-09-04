open Lwt
    
class ['a] table = object(self)
  val table: (Bytes.t, 'a) Hashtbl.t = Hashtbl.create 1
  val mutex = Lwt_mutex.create ()
  method lock = Lwt_mutex.lock mutex
  method unlock = Lwt_mutex.unlock mutex
  method add = Hashtbl.add table
  method remove = Hashtbl.remove table
  method iter f = Hashtbl.iter (fun _ -> f) table
  method find x = Hashtbl.find table x
end

type 'a t = 'a table
let create () = new table
let add t = t#add
let remove t = t#remove
let iter f t = t#iter f
let find t = t#find
let lock t = t#lock
let unlock t = t#unlock
