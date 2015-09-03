open Value

let decrire_option intitule = function
  | (nom, Config.Int (min, max, increment)) ->
    Printf.sprintf
      "%s (%S) est un entier%s%s%s."
      intitule nom
      (match min with None -> "" | Some min ->
        Printf.sprintf ", au minimum %d" min)
      (match max with None -> "" | Some max ->
        Printf.sprintf ", au maximum %d" max)
      (match increment with None -> "" | Some i ->
        Printf.sprintf ", multiple de %d" i)

let decrire_config cfg =
  (Bytes.concat
     "\n"
     (Hashtbl.fold
        (fun intitule opt acc ->
           (decrire_option intitule opt) :: acc)
        cfg []))

let verifier_aux effectuer_requete = function
  | List [String np; arg] ->
    Config.valider_invitation effectuer_requete (int_of_string np) arg
  | _ ->
    Lwt.fail (Failure "Format désiré : (\"5\" ...) pour 5 joueurs")

let verifier_invitation effectuer_requete = function
  | Lwt_stream.Value v ->
    Lwt.try_bind
      (fun () -> verifier_aux effectuer_requete v)
      (fun () ->
         Lwt.return
           (List [String "Accepté."]))
      (fun exn ->
         Lwt.return
           (List [String "Refusé."; String (Printexc.to_string exn)]))
  | Lwt_stream.Error exn ->
    Lwt.return
      (List [String "Vous avez commis une erreur :";
             String (Printexc.to_string exn)])

let repeter effectuer_requete = function
  | Lwt_stream.Value v ->
    Lwt.try_bind (fun () -> Config.get_config effectuer_requete)
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
  Lwt_stream.map_s (verifier_invitation requete_jeu)
