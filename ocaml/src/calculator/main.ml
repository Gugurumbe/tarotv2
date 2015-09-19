let server =
  Lwt_unix_server.run_server
    ~pretty:true
    (Unix.ADDR_INET (Unix.inet_addr_any, 45678))
    Calculator.run_calculation

let () = Lwt_main.run (fst (Lwt.wait ()))
