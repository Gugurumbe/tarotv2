open Value
open Partie
    
let of_event = function
  | NouvelleManche -> String "NouvelleManche"
  | Enchere -> String "Enchere"
  | Appel -> String "Appel"
  | ChienDevoile -> String "ChienDevoile"
  | EcartEffectue -> String "EcartEffectue"
  | Jeu -> String "Jeu"
  | PoigneeMontree -> String "PoigneeMontree"
  | CarteJouee -> String "CarteJouee"
  | PliTermine -> String "PliTermine"
  | MancheTerminee -> String "MancheTerminee"

let of_carte c = of_int (Carte.int_of_carte c)

let of_list of_val tab =
  List (List.map (of_val)
          (Array.to_list tab))

let of_carte_opt = function
  | None -> String "Cachee"
  | Some c -> of_labelled "Visible" (of_carte c)

let of_jeu = of_list of_carte

let of_ints = of_list of_int
    
let of_matrix of_val = of_list (of_list of_val)
let of_carte_matrix = of_matrix of_carte

let of_message m =
  let table = Hashtbl.create 30 in
  let add = Hashtbl.add table in
  let add_opt of_elem nom = function
    | None -> ()
    | Some x -> add nom (of_elem x)
  in
  let add_iopt = add_opt of_int in
  let add_copt = add_opt of_carte in
  let add_bopt = add_opt of_bool in
  add "evenement" (of_event m.evenement);
  add "mon_numero" (of_int m.mon_numero);
  add "numero_manche" (of_int m.numero_manche);
  add "mon_jeu" (of_jeu m.mon_jeu);
  add "chien" (of_jeu m.chien);
  add "encheres" (of_ints m.encheres);
  add_iopt "preneur" m.preneur;
  add_copt "carte_appelee" m.carte_appelee;
  add "ecart" (of_list of_carte_opt m.ecart);
  add_bopt "chelem_demande" m.chelem_demande;
  add "poignees_montrees" (of_carte_matrix m.poignees_montrees);
  add_iopt "entameur" m.entameur;
  add "pli_en_cours" (of_carte_matrix m.pli_en_cours);
  add_iopt "dernier_entameur" m.dernier_entameur;
  add "pli_en_cours" (of_carte_matrix m.dernier_pli);
  add "score" (of_ints m.score);
  add "doit_priser" (of_bool m.doit_priser);
  add "doit_appeler" (of_bool m.doit_appeler);
  add "doit_ecarter" (of_bool m.doit_ecarter);
  add "doit_decider_chelem" (of_bool m.doit_decider_chelem);
  add "peut_montrer_poignee" (of_bool m.peut_montrer_poignee);
  add "doit_jouer" (of_bool m.doit_jouer);
  of_table table

let configuration () =
  let table = Hashtbl.create 5 in
  let add = Hashtbl.add table in
  let configuration_entier ?min ?max ?incr nom =
    let table = Hashtbl.create 4 in
    let add = Hashtbl.add table in
    let add_o of_obj nom = function
      | None -> ()
      | Some x -> add nom (of_obj x) in
    add "type" (of_string "int");
    add "name" (of_string nom);
    add_o of_int "min" min;
    add_o of_int "max" max;
    add_o of_int "incr" incr;
    of_table table
  in
  add "nplayers" (configuration_entier ~min:5 ~max:5 "Nombre de joueurs");
  add "nlev" (configuration_entier ~min:1 ~max:24 "Nombre de levées");
  of_table table

let creer_partie_aleatoire seeds =
  let distributions = List.map (Partie.distribuer) seeds in
  Table.nouvelle_partie distributions
let creer_partie_aleatoire nombre =
  creer_partie_aleatoire
    (Array.to_list
       (Array.init nombre
          (fun _ ->
             Array.init 8
               (fun _ -> Random.bits ()))))
let lister_parties = Table.lister_parties
let supprimer_partie = Table.supprimer_partie
let lister_joueurs_prets = Table.lister_joueurs_prets
let lister_parties_terminees = Table.lister_parties_terminees
let peek_message partie =
  Partie.peek_message (Table.trouver_partie partie)
let next_message partie =
  Partie.next_message (Table.trouver_partie partie)
let verifier_enchere partie =
  Partie.verifier_enchere (Table.trouver_partie partie)
let verifier_appel partie =
  Partie.verifier_appel (Table.trouver_partie partie)
let verifier_ecart partie =
  Partie.verifier_ecart (Table.trouver_partie partie)
let verifier_chelem partie =
  Partie.verifier_chelem (Table.trouver_partie partie)
let verifier_poignee partie =
  Partie.verifier_poignee (Table.trouver_partie partie)
let verifier_jeu partie =
  Partie.verifier_jeu (Table.trouver_partie partie)
let enchere partie = Partie.enchere (Table.trouver_partie partie)
let appel partie = Partie.appel (Table.trouver_partie partie)
let ecart partie = Partie.ecart (Table.trouver_partie partie)
let chelem partie = Partie.chelem (Table.trouver_partie partie)
let poignee partie = Partie.poignee (Table.trouver_partie partie)
let jeu partie = Partie.jeu (Table.trouver_partie partie)

open Value

exception Too_many_players
exception Too_few_players
exception Too_many_rounds
exception Too_few_rounds
exception Too_many_arguments
exception Too_few_arguments
exception Missing_argument of Bytes.t
exception Invalid_command of Bytes.t

let to_carte t =
  let i = to_int t in
  Carte.carte_of_int i

let to_cartes t = List.map to_carte (to_list t)

let traiter_requete x =
  let (cmd, arg) = to_labelled x in
  let table = to_table arg in
  let nargs_expected n =
    if Hashtbl.length table > n
    then raise Too_many_arguments
    else if Hashtbl.length table < n
    then raise Too_few_arguments in
  let find x = try Hashtbl.find table x
    with Not_found -> raise (Missing_argument x) in
  let mem = Hashtbl.mem table in
  match cmd with
  | "config" ->
    let () = nargs_expected 0 in
    configuration ()
  | "creer_partie" ->
    let () = nargs_expected 2 in
    let nombre_joueurs = to_int (find "nplayers") in
    let nombre_levees = to_int (find "nlev") in
    let () = if nombre_joueurs < 5 then raise Too_few_players
      else if nombre_joueurs > 5 then raise Too_many_players in
    let () = if nombre_levees < 1 then raise Too_few_rounds
      else if nombre_joueurs > 24 then raise Too_many_rounds in
    let partie =
      match creer_partie_aleatoire nombre_levees
      with None -> failwith "Impossible de distribuer"
         | Some id -> id in
    String partie
  | "lister_parties" ->
    let () = nargs_expected 0 in
    List (List.map (fun s -> String s) (lister_parties ()))
  | "lister_joueurs_prets" ->
    let () = nargs_expected 0 in
    List (List.map (fun (p, j) -> of_labelled p (of_int j))
            (lister_joueurs_prets ()))
  | "lister_parties_terminees" ->
    let () = nargs_expected 0 in
    List (List.map (fun (p, res) ->
        of_labelled p
          (List (List.map of_int (Array.to_list res))))
        (lister_parties_terminees ()))
  | "supprimer_partie" ->
    let () = nargs_expected 1 in
    let nom = to_string (find "partie") in
    let () = supprimer_partie nom in
    List []
  | "peek_message" ->
    let () = nargs_expected 2 in
    let partie = to_string (find "partie") in
    let numero_joueur = to_int (find "joueur") in
    let msg = peek_message partie numero_joueur in
    let reponse = match msg with
      | None -> List []
      | Some msg -> List [of_message msg]
    in
    reponse
  | "next_message" ->
    let () = nargs_expected 2 in
    let partie = to_string (find "partie") in
    let numero_joueur = to_int (find "joueur") in
    let () = next_message partie numero_joueur in
    List []
  | "verifier" ->
    let () = nargs_expected 3 in
    let p = to_string (find "partie") in
    let j = to_int (find "joueur") in
    let ok =
      if mem "enchere"
      then verifier_enchere p j (to_int (find "enchere")) else
      if mem "appel"
      then verifier_appel p j (to_carte (find "appel")) else
      if mem "ecart"
      then verifier_ecart p j (to_cartes (find "ecart")) else
      if mem "chelem"
      then verifier_chelem p j (to_bool (find "chelem")) else
      if mem "poignee"
      then verifier_poignee p j (to_cartes (find "poignees")) else
      if mem "jeu"
      then verifier_jeu p j (to_carte (find "jeu")) else
        raise (Missing_argument "enchere | appel | ecart \
                                 | chelem | poignee | jeu")
    in
    of_bool ok
  | "effectuer" ->
    let () = nargs_expected 3 in
    let p = to_string (find "partie") in
    let j = to_int (find "joueur") in
    let () =
      if mem "enchere"
      then enchere p j (to_int (find "enchere")) else
      if mem "appel"
      then appel p j (to_carte (find "appel")) else
      if mem "ecart"
      then ecart p j (to_cartes (find "ecart")) else
      if mem "chelem"
      then chelem p j (to_bool (find "chelem")) else
      if mem "poignee"
      then poignee p j (to_cartes (find "poignees")) else
      if mem "jeu"
      then jeu p j (to_carte (find "jeu")) else
        raise (Missing_argument "enchere | appel | ecart \
                                 | chelem | poignee | jeu")
    in
    List []
  | str -> raise (Invalid_command str)
             
let traiter_requete = function
  | Lwt_stream.Value v -> traiter_requete v
  | Lwt_stream.Error exn -> raise exn

let traiter_requete req =
  try
    of_labelled "OK" (traiter_requete req)
  with exn ->
    of_labelled "ERR"
      (of_string (Printexc.to_string exn))

let run = Lwt_stream.map (traiter_requete)
