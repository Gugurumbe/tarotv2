module type BACKEND = sig
  val requete: Value.t Lwt_stream.t -> Value.t Lwt_stream.t
end

module type FRONTEND = sig
  val print_exceptions_on_stderr: unit -> bool
  val send_exceptions: unit -> bool
  val timeout: unit -> float
end

module Make (B:BACKEND) (F:FRONTEND): sig
  val run: Value.t Lwt_stream.result Lwt_stream.t -> Value.t Lwt_stream.t
end
