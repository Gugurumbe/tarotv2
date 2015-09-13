type t
val creer: float -> (* délai *) t
val attendre: t -> unit Lwt.t
val retarder: t -> unit
