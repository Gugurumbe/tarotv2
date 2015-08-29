val run_server:
  pretty:bool ->
  Unix.sockaddr ->
  (Value.t Lwt_stream.result Lwt_stream.t -> Value.t Lwt_stream.t) ->
  Lwt_io.server
