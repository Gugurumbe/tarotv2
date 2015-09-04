module type COMM = sig
  val get_config: unit -> Config.configuration Lwt.t
  val vitesse_lecture: unit -> float (* en caractères par seconde *)
  val timeout_partie: unit -> float
end

module type TIME = sig
  val gettimeofday: unit -> float
end

module Make (C:COMM) (Time:TIME): sig
  val accepter_identification: Bytes.t -> bool Lwt.t 
  val accepter_invitation: int -> Value.t -> bool Lwt.t
  val accepter_message: Bytes.t -> Bytes.t -> bool Lwt.t
  val timeout: unit -> float
end
