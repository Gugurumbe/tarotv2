open Value
open Partie
    
let string_of_event = function
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

let string_of_int i = String (string_of_int i)

let string_of_carte c = string_of_int (Carte.int_of_carte c)

let string_of_bool = function
  | true -> String "true" | false -> String "false"

let list_of_list of_val tab =
  List (List.map (of_val)
          (Array.to_list tab))

let list_of_jeu = list_of_list string_of_carte

let list_of_ints = list_of_list string_of_int

let list_of_opt of_val = function
  | None -> String "None"
  | Some x -> List [String "Some"; of_val x]
                
let list_of_bool_opt = list_of_opt string_of_bool
let list_of_int_opt = list_of_opt (string_of_int)
let list_of_carte_opt = list_of_opt (string_of_carte)
let list_of_jeu_opt = list_of_list (list_of_opt string_of_carte)
let list_of_matrix of_val = list_of_list (list_of_list of_val)
let list_of_carte_matrix = list_of_matrix string_of_carte

let string_of_message m =
  List [
    List [String "evenement"; string_of_event m.evenement];
    List [String "mon_numero"; string_of_int m.mon_numero];
    List [String "numero_manche"; string_of_int m.numero_manche];
    List [String "mon_jeu"; list_of_jeu m.mon_jeu];
    List [String "chien"; list_of_jeu m.chien];
    List [String "encheres"; list_of_ints m.encheres];
    List [String "preneur"; list_of_int_opt m.preneur];
    List [String "carte_appelee"; list_of_carte_opt m.carte_appelee];
    List [String "ecart"; list_of_jeu_opt m.ecart];
    List [String "chelem_demande"; list_of_bool_opt m.chelem_demande];
    List [String "poignees_montrees"; list_of_carte_matrix
            m.poignees_montrees];
    List [String "entameur"; list_of_int_opt m.entameur];
    List [String "pli_en_cours"; list_of_carte_matrix m.pli_en_cours];
    List [String "dernier_entameur";
          list_of_int_opt m.dernier_entameur];
    List [String "dernier_pli"; list_of_carte_matrix m.dernier_pli];
    List [String "score"; list_of_ints m.score];
    List [String "doit_priser"; string_of_bool m.doit_priser];
    List [String "doit_appeler"; string_of_bool m.doit_appeler];
    List [String "doit_ecarter"; string_of_bool m.doit_ecarter];
    List [String "doit_decider_chelem";
          string_of_bool m.doit_decider_chelem];
    List [String "peut_montrer_poignee";
          string_of_bool m.peut_montrer_poignee];
    List [String "doit_jouer"; string_of_bool m.doit_jouer]
  ]

let configuration () =
  List [
    List [
      String "min_players"; String "5"
    ];
    List [
      String "max_players"; String "5"
    ];
    List [
      String "options";
      List [
        List [
          String "Nombre de levées";
          String "int";
          List [
            String "max"; String "24";
          ];
          List [
            String "min"; String "1";
          ]
        ]
      ]
    ]
  ]

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

let carte_of_string str =
  let i = int_of_string str in
  Carte.carte_of_int i
let carte_of_string = function
  | List _ -> failwith "Mauvais format de carte"
  | String s -> carte_of_string s 
 
let traiter_requete = function
  | String "config" -> configuration ()
  | List [
      String "creer_partie";
      List [String "nombre_joueurs"; String "5"];
      List [
        String "options";
        List [
          String "Nombre de levées";
          String nombre_levees
        ]
      ]
    ] ->
    let nombre_levees = int_of_string nombre_levees in
    let partie = match creer_partie_aleatoire nombre_levees
      with None -> failwith "Impossible de distribuer"
         | Some id -> id in
    String partie
  | String "lister_parties" ->
    List
      (List.map (fun s -> String s) (lister_parties ()))
  | List [String "supprimer_partie"; String id] ->
    let () = supprimer_partie id in
    List []
  | String "lister_joueurs_prets" ->
    List (List.map (fun (p, j) ->
        List [String p; string_of_int j])
        (lister_joueurs_prets ()))
  | String "lister_parties_terminees" ->
    List (List.map (fun (p, res) ->
        List [String p;
              List (List.map
                      (fun i -> string_of_int i)
                      (Array.to_list res))])
        (lister_parties_terminees ()))
  | List [String "peek_message"; String partie; String joueur] ->
    let msg = peek_message partie (int_of_string joueur) in
    let reponse = match msg with
      | None -> List []
      | Some msg -> List [string_of_message msg] in
    reponse
  | List [String "next_message"; String partie; String joueur] ->
    let () = next_message partie (int_of_string joueur) in
    List []
  | List [String "verifier_enchere"; String partie; String joueur;
          String enchere] ->
    if verifier_enchere partie (int_of_string joueur)
        (int_of_string enchere)
    then String "true"
    else String "false"
  | List [String "verifier_appel"; String partie; String joueur;
          appel] ->
    if verifier_appel partie (int_of_string joueur)
        (carte_of_string appel)
    then String "true"
    else String "false"
  | List [String "verifier_ecart"; String partie; String joueur;
          List ecart] ->
    let ecart = List.map (carte_of_string) ecart in
    if verifier_ecart partie (int_of_string joueur) ecart
    then String "true"
    else String "false"
  | List [String "verifier_chelem"; String partie; String joueur;
          String "true"] ->
    if verifier_chelem partie (int_of_string joueur) true
    then String "true"
    else String "false"
  | List [String "verifier_chelem"; String partie; String joueur;
          String "false"] ->
    if verifier_chelem partie (int_of_string joueur) false
    then String "true"
    else String "false"
  | List [String "verifier_poignee"; String partie; String joueur;
          List poignee] ->
    let poignee = List.map (carte_of_string) poignee in
    if verifier_poignee partie (int_of_string joueur) poignee
    then String "true"
    else String "false"
  | List [String "verifier_jeu"; String partie; String joueur;
          carte] ->
    if verifier_jeu partie (int_of_string joueur)
        (carte_of_string carte)
    then String "true"
    else String "false"
  | List [String "enchere"; String partie; String joueur;
          String mon_enchere] ->
    let () = enchere partie (int_of_string joueur)
        (int_of_string mon_enchere) in
    List []
  | List [String "appel"; String partie; String joueur;
          mon_appel] ->
    let () = appel partie (int_of_string joueur)
        (carte_of_string mon_appel) in
    List []
  | List [String "ecart"; String partie; String joueur;
          List mon_ecart] ->
    let mon_ecart = List.map (carte_of_string) mon_ecart in
    let () = ecart partie (int_of_string joueur) mon_ecart in
    List []
  | List [String "chelem"; String partie; String joueur;
          String "true"] ->
    let () = chelem partie (int_of_string joueur) true in
    List []
  | List [String "chelem"; String partie; String joueur;
          String "false"] ->
    let () = chelem partie (int_of_string joueur) false in
    List []
  | List [String "poignee"; String partie; String joueur;
          List ma_poignee] ->
    let ma_poignee = List.map (carte_of_string) ma_poignee in
    let () = poignee partie (int_of_string joueur) ma_poignee in
    List []
  | List [String "jeu"; String partie; String joueur;
          carte] ->
    let () = jeu partie (int_of_string joueur)
        (carte_of_string carte) in
    List []
  | _ -> failwith "Commande incomprise"

let traiter_requete = function
  | Lwt_stream.Value v -> traiter_requete v
  | Lwt_stream.Error exn -> raise exn

let traiter_requete req =
  try traiter_requete req
  with exn -> String (Printf.sprintf "Error: %s."
                        (Printexc.to_string exn))

let run = Lwt_stream.map (traiter_requete)
