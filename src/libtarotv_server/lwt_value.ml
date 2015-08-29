let read_stream strm =
  let reader = Value.read () in
  Lwt_stream.map_exn (Lwt_stream.filter_map (reader) strm)

let print_stream ~pretty v =
  (Lwt_stream.of_string
     (Value.print pretty v))
