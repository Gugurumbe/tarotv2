open Partie_types

let deduire_preneur t =
  let encheres = Array.of_list t.encheres in
  let encheres_et_pos = Array.mapi (fun i e -> (i, e)) encheres in
  let encheres_et_joueurs =
    Array.map (fun (i, e) -> ((i + t.i_manche) mod 5, e))
      encheres_et_pos in
  let lst_encheres = Array.to_list encheres_et_joueurs in
  let cmp (_, a) (_, b) = compare a b in
  let max a b = if cmp a b > 0 then a else b in
  let (preneur, _) = List.fold_left (max)
      (List.hd lst_encheres) (List.tl lst_encheres) in
  preneur

let manche_suivante t =
  let () = t.i_manche <- t.i_manche + 1 in
  let () = match t.distribution with
    | [] -> ()
    | _ :: b -> t.distribution <- b in
  let () = t.encheres <- [] in
  let () = t.preneur <- None in
  let () = t.carte_appelee <- None in
  let () = t.joueur_appele <- None in
  let () = t.ecart <- None in
  let () = t.chelem_demande <- None in
  let () =
    for i = 0 to -1 + Array.length t.poignees_montrees do
      t.poignees_montrees.(i) <- [] done in
  let () = t.ouvreurs.(0) <- t.i_manche mod 5 in
  let () = for i = 0 to -1 + Array.length t.levees do
      t.levees.(i) <- [] done in
  let () = t.i_pli <- 0 in
  ()

let enchere t i enchere =
  if not (Partie_arbitre.verifier_enchere t i enchere)
  then failwith "Invalide"
  else
    let () = t.encheres <- t.encheres @ [enchere] in
    let () = Partie_arbitre.nouvel_etat t Enchere in
    (* On avance *)
    if List.length t.encheres = 5 then
      let i_preneur = deduire_preneur t in
      if Partie_arbitre.enchere_de t i_preneur = 0 then
        (* On redistribue *)
        let () = Partie_arbitre.nouvel_etat t MancheTerminee in
        let () = manche_suivante t in
        let () = match t.distribution with
          | [] -> ()
          | _ -> Partie_arbitre.nouvel_etat t NouvelleManche in
        ()
      else
        let () = t.preneur <- Some i_preneur in
        ()
let the = Partie_arbitre.the

let appel t i carte =
  if not (Partie_arbitre.verifier_appel t i carte)
  then failwith "Invalide"
  else
    let () = t.carte_appelee <- Some carte in
    let preneur = i in
    let () = assert (i = the t.preneur) in
    let enchere_preneur = Partie_arbitre.enchere_de t preneur in
    (* On cherche le joueur appelé *)
    let est_appele i =
      match t.distribution with
      | tab :: _ when List.exists ((=) carte) tab.(i) -> true
      | _ -> false        
    in
    let i_appele = ref 0 in
    let () = while !i_appele < 5 && not (est_appele !i_appele) do
        incr i_appele done in
    let () = if !i_appele = 5 then i_appele := preneur in
    let () = t.joueur_appele <- Some !i_appele in
    (* On lui rajoute les cartes du chien *)
    let () = match t.distribution with
      | tab :: _ when enchere_preneur < 3 ->
        tab.(preneur) <- tab.(5) @ tab.(preneur)
      | _ -> ()
    in
    Partie_arbitre.nouvel_etat t Appel

let ecart t i ecart =
  if not (Partie_arbitre.verifier_ecart t i ecart)
  then failwith "Invalide"
  else
    let () = t.ecart <- Some ecart in
    let () = assert (t.distribution <> []) in
    let distribution = List.hd t.distribution in
    (* On lui enlève ces cartes *)
    let () = distribution.(i) <-
        List.filter (fun carte ->
            not (List.exists ((=) carte) ecart))
          distribution.(i) in
    Partie_arbitre.nouvel_etat t EcartEffectue 

let chelem t i chel =
  if not (Partie_arbitre.verifier_chelem t i chel)
  then failwith "Invalide"
  else let () = t.chelem_demande <- Some chel in
    let preneur = the t.preneur in
    let () = t.ouvreurs.(0) <- preneur in
    Partie_arbitre.nouvel_etat t Jeu

let poignee t i poignee =
  if not (Partie_arbitre.verifier_poignee t i poignee)
  then failwith "Invalide"
  else let () = t.poignees_montrees.(i) <- poignee in
    Partie_arbitre.nouvel_etat t PoigneeMontree

let jeu t i carte =
  if not (Partie_arbitre.verifier_jeu t i carte)
  then failwith "Invalide"
  else let () = assert (t.distribution <> []) in
    let distribution = List.hd t.distribution in
    let () = distribution.(i) <- List.filter ((<>) carte)
          distribution.(i) in
    let () = Partie_arbitre.nouvel_etat t CarteJouee in
    (* On passe au pli suivant ? *)
    if List.length t.levees.(t.i_pli) = 5 then
      let tapis = List.map (List.hd) t.levees.(t.i_pli) in
      let ouvreur = t.ouvreurs.(t.i_pli) in
      let rec trouver_joueur_excuse i = function
        | [] -> None
        | a :: _ when a = Carte.excuse -> Some (i mod 5)
        | _ :: b -> trouver_joueur_excuse (i + 1) b in
      let joueur_excuse = trouver_joueur_excuse ouvreur tapis in
      let preneur = the t.preneur and appele = the t.joueur_appele in
      let est_attaquant i = i = preneur || i = appele in
      let meme_camp a b = est_attaquant a = est_attaquant b in
      let ennemis a b = not (meme_camp a b) in
      let equipe_adverse =
        match joueur_excuse with
        | None -> [0; 1; 2; 3; 4]
        | Some joueur_excuse ->
          List.filter (ennemis joueur_excuse)
            [0; 1; 2; 3; 4] in
      let excuse_gagnante =
        (* Si on n'en est pas au dernier tour, pas de chelem *)
        (t.i_pli = -1 + Array.length t.levees)
        (* Il faut qu'on joue l'excuse *)
        && (joueur_excuse <> None)
        && (let pli_echec_chelem = ref 1 in
            let () =
              while !pli_echec_chelem < Array.length t.levees
                    && not (List.exists
                              ((=) t.ouvreurs.(!pli_echec_chelem))
                              equipe_adverse) do
                incr pli_echec_chelem done in
            !pli_echec_chelem = Array.length t.levees)
        (* Ça rate s'il reste un atout *)
        && not (List.exists (List.exists (Carte.est_atout))
                  t.levees.(t.i_pli)) in
      let maitre =
        if excuse_gagnante then the joueur_excuse
        else
          let rec comparer i_maitre carte_maitresse i = function
            | [] -> i_maitre
            | a :: b when Carte.sup_large carte_maitresse a ->
              comparer i_maitre carte_maitresse (i + 1) b
            | a :: b -> comparer i a (i + 1) b in
          let pas_modulo =
            comparer ouvreur (List.hd tapis) (ouvreur + 1)
              (List.tl tapis) in
          pas_modulo mod 5 in
      let () = t.i_pli <- t.i_pli + 1 in
      let () = t.ouvreurs.(t.i_pli) <- maitre in
      let () = Partie_arbitre.nouvel_etat t PliTermine in
      (* Faut-il relancer une manche ? *)
      if t.i_pli >= Array.length t.levees then
        let points = Partie_compter_points.compter_points t in
        let () = Array.iteri (fun i pt ->
            t.scores.(i) <- t.scores.(i) + pt) points in
        let () = Partie_arbitre.nouvel_etat t MancheTerminee in
        let () = manche_suivante t in
        match t.distribution with
        | [] -> () (* fini *)
        | _ -> Partie_arbitre.nouvel_etat t NouvelleManche
