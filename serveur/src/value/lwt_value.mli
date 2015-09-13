val read_stream: char Lwt_stream.t ->
  Value.t Lwt_stream.result Lwt_stream.t
val print_stream: pretty:bool -> Value.t -> char Lwt_stream.t
