let request req =
  Tarotv.run (Lwt_stream.map_exn req)

let server =
  Lwt_unix_server.run_server
    ~pretty:true
    (Unix.ADDR_INET (Unix.inet_addr_any, 45678))
    (Mgmt.run request)

let () = Lwt_main.run (fst (Lwt.wait ()))
