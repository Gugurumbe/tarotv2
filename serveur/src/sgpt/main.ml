let server =
  Lwt_unix_server.run_server
    ~pretty:true
    (Unix.ADDR_INET (Unix.inet_addr_any, 45678))
    Tarotv.run

let () = Lwt_main.run (fst (Lwt.wait ()))
