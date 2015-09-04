type 'a t
val create: unit -> 'a t
val add: 'a t -> Bytes.t -> 'a -> unit
val remove: 'a t -> Bytes.t -> unit
val iter: ('a -> unit) -> 'a t -> unit
val find: 'a t -> Bytes.t -> 'a
val lock: 'a t -> unit Lwt.t
val unlock: 'a t -> unit
