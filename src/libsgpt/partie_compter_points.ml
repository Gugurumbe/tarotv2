open Partie_types

let ultime t = t.(-1 + Array.length t)
let penultieme t = t.(-2 + Array.length t)

type camp_opt =
  | Personne
  | Attaque
  | Defense

let the = function
  | None -> failwith "Quiproquo"
  | Some x -> x

let compter_points t =
  let joueurs_maitres =
    let seq = Array.init 15 ((+) 1) in (* [1..15] *)
    Array.map (Array.get t.ouvreurs) seq in
  (* ouvreur du prochain tour *)
  (* Si le dernier joueur maître a joué l'excuse, alors il a le
     droit de compter le petit au bout à l'avant-dernier tour. *)
  (* En effet, si le joueur qui a posé l'excuse au dernier tour 
     est le joueur maître, c'est que son chelem est réussi, donc 
     c'est son équipe qui a remporté le petit. *)
  let levee_contient levee carte =
    List.exists (List.exists ((=) carte)) levee in
  let nieme_carte levee i entameur =
    List.nth levee (supermodulo (i - entameur) 5) in
  let compter liste fonction =
    List.length (List.filter fonction liste) in
  let chien = match t.distribution with
    | [] -> failwith "Ne peut arriver."
    | tab :: _ -> tab.(5) in
  let petit_au_bout =
    let dernier_pli = ultime t.levees in
    let avant_dernier_pli = penultieme t.levees in
    let maitre_dernier_pli = ultime joueurs_maitres in
    let entameur_dernier_pli = penultieme joueurs_maitres in
    if levee_contient dernier_pli Carte.petit
    then Some maitre_dernier_pli else
    if nieme_carte dernier_pli
        maitre_dernier_pli entameur_dernier_pli
       = [Carte.excuse; Carte.fausse_excuse]
       && levee_contient avant_dernier_pli Carte.petit
    then Some entameur_dernier_pli
    else None
    in
    let preneur = the t.preneur and appele = the t.joueur_appele in
    let est_attaquant i = i = preneur || i = appele in
    let camp_pab =
      match petit_au_bout with
      | None -> Personne
      | Some i when est_attaquant i -> Attaque
      | Some _ -> Defense in
    let dp_attaque = ref 0 in
    let bouts_attaque = ref 0 in
    let carte_attaque c =
      if Carte.est_bout c then incr bouts_attaque;
      dp_attaque := !dp_attaque + Carte.demipoints c
    in
    let nombre_plis_attaque =
      compter (Array.to_list joueurs_maitres) est_attaquant in
    let enchere_preneur =
      List.nth t.encheres (supermodulo (preneur - t.i_manche) 5) in
    let cartes_attaque_supplementaires =
      match enchere_preneur with
      | 3 (* garde sans *) -> chien
      | 2 | 1 -> the t.ecart
      | _ -> [] in
    let () = List.iter (carte_attaque)
        cartes_attaque_supplementaires in
    (* L'excuse est remportée par celui qui l'a posée, 
       sauf au dernier tour où elle revient au joueur maître. *)
    (* N.B. Si un chelem est réussi, on sait déjà 
       que le joueur maître est celui qui réussit le chelem. *)
    let traiter_tour i_tour =
      let ouvreur = t.ouvreurs.(i_tour) in
      let maitre = joueurs_maitres.(i_tour) in
      let cartes = Array.of_list t.levees.(i_tour) in
      let cartes_et_position = Array.mapi
          (fun i c -> (i, c)) cartes in
      let cartes_et_poseur =
        Array.to_list
          (Array.map
             (fun (i, c) -> ((i + ouvreur) mod 5, c))
             cartes_et_position) in
      let toutes_cartes =
        List.map (fun (i, c) ->
            List.map (fun c -> (i, c)) c) cartes_et_poseur in
      let toutes_cartes = List.concat toutes_cartes in
      let traiter_carte (poseur, carte) =
        if (carte = Carte.excuse
            && i_tour + 1 < Array.length t.levees
            && est_attaquant poseur)
           || est_attaquant maitre
        then carte_attaque carte
      in
      List.iter traiter_carte toutes_cartes
    in
    let () = for i = 0 to 14 do traiter_tour i done in
    let chelem_attaque = nombre_plis_attaque = 15 in
    let chelem_defense = nombre_plis_attaque = 0 in
    (* Ainsi, la défense peut faire un chelem même si l'attaque 
       fait un écart. Et l'attaque peut réussir un chelem 
       même avec une garde contre. *)
    let barre_dp = 2 * ([|56; 51; 41; 36|].(!bouts_attaque)) in
    let contrat_realise = !dp_attaque > barre_dp in
    let score_reussite = if contrat_realise then 50 else -50 in
    let score_dp = score_reussite + !dp_attaque - barre_dp in
    let score_points =
      if score_dp mod 2 = 1 && contrat_realise
      then 1 + (score_dp / 2)
      else score_dp / 2 in
    let bonus_pab = match camp_pab with
      | Personne -> 0 | Attaque -> 10 | Defense -> -10 in
    let score_non_multiplie = score_points + bonus_pab in
    let score_mult = score_non_multiplie
                     * ([|0; 1; 2; 4; 6|].(enchere_preneur)) in
    let bonus_poignee liste =
      if List.length liste = 8 then 20 else
      if List.length liste = 10 then 30 else
      if List.length liste = 13 then 40 else 0 in
    let poignees = Array.map (bonus_poignee) t.poignees_montrees in
    let score_avec_poignees = score_mult
                              + Array.fold_left (+) 0 poignees in
    let score_total =
      score_avec_poignees
      + match t.chelem_demande with
      | None -> failwith "Ne peut arriver"
      | Some false when chelem_attaque -> 200
      | Some false when chelem_defense -> -200
      | Some false -> 0
      | Some true when chelem_attaque -> 400
      | Some true when chelem_defense -> -400
      | Some true -> -200 in
    (* Tout le monde gagne l'opposé de ce score. *)
    let resultat = Array.make 5 (-score_total) in
    (* Le joueur appelé oppose son score *)
    let () = resultat.(appele) <- -(resultat.(appele)) in
    (* Le preneur enlève la somme totale. *)
    let somme = Array.fold_left (+) 0 resultat in
    let () = resultat.(preneur) <- resultat.(preneur) - somme in
    let () = assert ((Array.fold_left (+) 0 resultat) = 0) in
    resultat
