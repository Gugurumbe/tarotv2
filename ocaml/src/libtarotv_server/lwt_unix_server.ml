let run_server ~pretty sockaddr work =
  let (>>=) = Lwt.bind in
  let do_server (input, output) =
    let input_stream = Lwt_io.read_chars input in
    let input_data_stream = Lwt_value.read_stream input_stream in
    let output_data_stream = work input_data_stream in
    let output_data_stream =
      Lwt_stream.concat
        (Lwt_stream.map
           (Lwt_value.print_stream ~pretty:pretty)
           output_data_stream) in
    (Lwt_io.write_chars output output_data_stream)
  in
  let ign _ = Lwt.return () in
  let close chan () = Lwt.catch
      (fun () -> Lwt_io.close chan) (ign) in
  let do_server (input, output) =
    (do_server (input, output))
    >>= close input
    >>= close output in
  let do_server io = Lwt.async (fun () -> do_server io) in
  Lwt_io.establish_server sockaddr do_server
  
