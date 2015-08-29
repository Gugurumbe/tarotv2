exception Invalid_constraint of Bytes.t * Bytes.t
exception Invalid_option of Bytes.t
exception Invalid_config_elt of Bytes.t

val run: (Value.t Lwt_stream.t -> Value.t Lwt_stream.t) ->
  (* Fonction pour effectuer une requête et récupérer la réponse *)
  Value.t Lwt_stream.result Lwt_stream.t -> Value.t Lwt_stream.t
