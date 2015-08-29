open Partie_types

let distribuer graine =
  let state = Random.get_state () in
  let s = Random.State.make graine in
  let () = Random.set_state s in
  let random_int = Random.State.int s in
  let rec distribution_valide () =
    let permutation = Array.init 78 (fun i -> i) in
    let inserer i =
      let pos = random_int (i + 1) in
      let ancien = permutation.(i) in
      let () = permutation.(i) <- permutation.(pos) in
      permutation.(pos) <- ancien
    in
    let () = for i = 1 to -1 + Array.length permutation do
        inserer i done in
    let part_de i =
      let debut = i * 15 in
      let fin = min (Array.length permutation) (debut + 15) in
      let nombre = fin - debut in
      let tab = Array.sub permutation debut nombre in
      let list = Array.to_list tab in
      List.map (Carte.carte_of_int) list
    in
    let d = Array.init 6 (part_de) in
    if Verifications.peut_distribuer d then d
    else distribution_valide ()
  in
  let d = distribution_valide () in
  let () = Random.set_state state in
  d

let the = function
  | Some x -> x
  | None -> failwith "Indécidable"
let jeu_de t i =
  match t.distribution with
  | [] -> []
  | tab :: _ -> trier (tab.(i))
let doit_priser t i =
  (List.length t.encheres = supermodulo (i - t.i_manche) 5)
  && (t.distribution <> [])
let enchere_de t i =
  List.nth t.encheres (supermodulo (i - t.i_manche) 5)
let doit_appeler t i =
  (List.length t.encheres = 5)
  && (let encheres = Array.init 5 (enchere_de t) in
      let mon_enchere = encheres.(i) in
      let () = encheres.(i) <- 0 in
      let meilleur = Array.map ((>) mon_enchere) encheres in
      Array.fold_left (&&) true meilleur)
  && (t.carte_appelee = None)
let doit_ecarter t i =
  (t.preneur = Some i)
  && (t.carte_appelee <> None)
  && (let mon_enchere = enchere_de t i in
      mon_enchere = 1 || mon_enchere = 2)
  && (t.ecart = None)
let peut_demander_chelem t i =
  (t.preneur = Some i)
  && (let mon_enchere = enchere_de t i in
      t.ecart <> None || mon_enchere >= 3)
  (* Après la phase de l'écart *)
  && (t.chelem_demande = None)
let doit_jouer t i =
  (t.chelem_demande <> None)
  && (t.i_pli < Array.length t.levees)
  && (let ouvreur = t.ouvreurs.(t.i_pli) in
      let levee_en_cours = t.levees.(t.i_pli) in
      let nombre_cartes_jouees = List.length levee_en_cours in
      let position_prochain = ouvreur + nombre_cartes_jouees in
      i = position_prochain mod 5)
let peut_montrer_poignee t i =
  (t.i_pli = 0)
  && (doit_jouer t i)
  && (let ecart_dispo =
        if t.preneur = Some i then
          match t.ecart with None -> [] | Some e -> e
        else [] in
      let mon_jeu = jeu_de t i in
      let montrable_au_pire c = Carte.est_atout c
                                || c = Carte.excuse in
      let montrables_au_pire =
        List.filter (montrable_au_pire) (ecart_dispo @ mon_jeu) in
      List.length montrables_au_pire >= 8)
  && (t.poignees_montrees.(i) = [])
     
let verifier_enchere t i enchere =
  let passe = enchere = 0 in
  let encheres_dominees = List.map ((>) enchere) t.encheres in
  let superieur = List.fold_left (&&) true encheres_dominees in
  doit_priser t i
  && enchere <= 4
  && enchere >= 0
  && (passe || superieur)

let verifier_appel t i appel =
  doit_appeler t i
  && Verifications.peut_appeler (jeu_de t i) appel

let verifier_ecart t i ecart =
  doit_ecarter t i
  && Verifications.peut_ecarter (jeu_de t i) ecart

let verifier_chelem t i _ =
  peut_demander_chelem t i

let verifier_poignee t i poignee =
  let ecart =
    if t.preneur = Some i then match t.ecart with
      | None -> [] | Some e -> e
    else [] in
  peut_montrer_poignee t i
  && Verifications.peut_montrer_poignee (jeu_de t i) ecart poignee

let verifier_jeu t i carte =
  doit_jouer t i
  && Verifications.peut_jouer (jeu_de t i) t.carte_appelee
    (List.map (List.hd) t.levees.(t.i_pli)) carte

let nouvel_etat t evenement =
  let chien_devoilable =
    List.length t.encheres = 5
    && t.carte_appelee <> None
    && (let preneur = the t.preneur in
        let enchere_preneur = enchere_de t preneur in
        enchere_preneur < 3) in
  let ecart =
    match t.ecart with
    | None -> [||]
    | Some list ->
      let list = trier list in
      Array.map (fun c -> Some c) (Array.of_list list) in
  let cacher_ecart () =
    Array.map (function
        | Some c when not (Carte.est_atout c) -> None
        | c -> c) ecart
  in
  for i = 0 to 4 do
    Queue.push {
      evenement = evenement;
      mon_numero = i;
      numero_manche = t.i_manche;
      mon_jeu = Array.of_list (jeu_de t i);
      chien = if chien_devoilable then
          Array.of_list (jeu_de t 5) else [||];
      encheres = Array.of_list t.encheres;
      preneur = t.preneur;
      carte_appelee = t.carte_appelee;
      ecart =
        if t.preneur = Some i then
          cacher_ecart ()
        else Array.copy ecart;
      chelem_demande = t.chelem_demande;
      poignees_montrees = Array.map (Array.of_list)
          (Array.map (trier) t.poignees_montrees);
      entameur =
        if t.i_pli < Array.length t.ouvreurs then
          Some t.ouvreurs.(t.i_pli)
        else None;
      pli_en_cours =
        if t.i_pli < Array.length t.levees then
          Array.of_list (List.map (Array.of_list) t.levees.(t.i_pli))
        else [||];
      dernier_entameur =
        if t.i_pli > 0 then Some t.ouvreurs.(t.i_pli - 1)
        else None;
      dernier_pli = if t.i_pli > 0 then
          Array.of_list (List.map (Array.of_list)
                           t.levees.(t.i_pli - 1))
        else [||];
      score = Array.copy t.scores;
      doit_priser = doit_priser t i;
      doit_appeler = doit_appeler t i;
      doit_ecarter = doit_ecarter t i;
      doit_decider_chelem = peut_demander_chelem t i;
      peut_montrer_poignee = peut_montrer_poignee t i;
      doit_jouer = doit_jouer t i;
    }
      (t.etats_en_attente.(i))
  done
