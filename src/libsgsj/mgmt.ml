open Value
    
exception Invalid_constraint of Bytes.t * Bytes.t
exception Invalid_option of Bytes.t
exception Invalid_config_elt of Bytes.t

let decrire_option intitule = function
  | Config.Int (min, max, increment) ->
    Printf.sprintf
      "\"%S\" est un entier%S%S%S."
      intitule
      (match min with None -> "" | Some min ->
        Printf.sprintf ", au minimum %d" min)
      (match max with None -> "" | Some max ->
        Printf.sprintf ", au maximum %d" max)
      (match increment with None -> "" | Some i ->
        Printf.sprintf ", multiple de %d" i)

let decrire_config cfg =
  Printf.sprintf
    "On choisit entre %d et %d joueurs (inclus), et on fournit les \
     options suivantes :\n%s\n%!"
    cfg.Config.min_players cfg.Config.max_players
    (Bytes.concat
       "\n"
       (Hashtbl.fold
          (fun intitule opt acc ->
             (decrire_option intitule opt) :: acc)
          cfg.Config.options []))

let repeter get_config = function
  | Lwt_stream.Value v ->
    Lwt.try_bind (get_config)
      (fun cfg ->
         let ret =
           List [String (decrire_config cfg);
                 String "Vous avez dit :";
                 v] in
         Lwt.return ret)
      (fun exn ->
         Lwt.return
           (List [String "Impossible d'obtenir la config :";
                  String (Printexc.to_string exn)]))
  | Lwt_stream.Error exn ->
    Lwt.return
      (List [String "Vous avez commis une erreur :";
             String (Printexc.to_string exn)])
      
let run requete_jeu =
  let config = Config.get_config requete_jeu in
  Lwt_stream.map_s (repeter config)
