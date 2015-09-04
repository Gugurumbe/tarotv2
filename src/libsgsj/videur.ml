module type TIMEOUT = sig
  type t
  val creer: float -> (* délai *) t
  val attendre: t -> unit Lwt.t
  val retarder: t -> unit
end

module Timeout: TIMEOUT = struct
  type t = {
    delai: float;
    mutable expire: float;
  }  
  let creer delai = {
    delai = delai;
    expire = delai +. Unix.gettimeofday ()
  }  
  let attendre tout =
    let flux_alertes =
      Lwt_stream.from
        (fun () ->
           let () = Printf.printf "Waiting for timeout...\n%!" in
           let date = Unix.gettimeofday () in
           let restant = tout.expire -. date in
           if restant < 0. then
             let () = Printf.printf "Done.\n%!" in
             Lwt.return (Some true)
           else
             let () = Printf.printf "%f seconds remaining.\n%!" restant in
             Lwt.bind (Lwt_unix.sleep restant)
               (fun () -> Lwt.return (Some false))) in
    let flux_arret = Lwt_stream.filter (fun b -> b) flux_alertes in
    Lwt.bind (Lwt_stream.get flux_arret)
      (fun _ -> Lwt.return ())      
  let retarder tout = tout.expire <- tout.delai +. Unix.gettimeofday ()
end

include Timeout
