(* Il reste à vérifier que ce joueur a fait la meilleure enchère (non
   nulle) et qu'aucune carte n'est encore appelée *)
let peut_appeler main carte =
  let appelables main =
    let par_valeur =
      Array.init
        4 (fun i -> let v = Carte.roi - i in
            List.map (fun c -> (v, c))
              [Carte.Coeur ; Carte.Pique ;
               Carte.Carreau ; Carte.Trefle])
    in
    let possedees =
      Array.map
        (List.map
           (fun appelable ->
              List.exists ((=) appelable) main))
        par_valeur
    in
    let niveaux_possedes =
      Array.map
        (List.fold_left (&&) true)
        possedees in
    let dernier_niveau =
      let rec examiner i =
        if niveaux_possedes.(i) then examiner (i + 1)
        else (i + 1) in
      examiner 0
    in
    let niveaux_appelables =
      Array.sub par_valeur
        0 dernier_niveau in
    let niveaux_appelables =
      Array.to_list niveaux_appelables in
    List.fold_right (@) niveaux_appelables []
  in
  List.exists ((=) carte) (appelables main)

(* Il reste à vérifier que ce joueur est le preneur, qu'il n'a pas
   encore fait d'écart, qu'il a fait un contrat prise ou garde, qu'il a
   appelé une carte et qu'on a montré le chien. *)
let peut_ecarter main ecart_donne =
  let ecart = Liste.to_list (Liste.of_list ecart_donne) in
  (* Permet de supprimer les doublons *)
  let (-) a b =
    Liste.to_list
      (Liste.difference (Liste.of_list a) (Liste.of_list b)) in
  let nbnr c = not (Carte.est_bout c) && not (Carte.est_roi c) in
  let mes_atouts = List.filter (Carte.est_atout) main in
  let atouts_ecartables = List.filter (nbnr) mes_atouts in
  let ecartables = List.filter (nbnr) (main - atouts_ecartables) in
  (List.length ecart = 3)
  && (List.length ecart_donne = 3) (* Pas de doublons *)
  && ((ecart - ecartables = []) (* Je n'écarte que des écartables *)
      || ((ecartables - ecart = []) (* J'ai écarté toutes les écartables... *)
          && ((ecart - ecartables) - atouts_ecartables = [])))
(*... et tout le reste de mon écart, c'est des atouts écartables *)

(* Il reste à vérifier que le jeu a commencé, et que c'est à ce joueur
   de jouer. On vérifie déjà si on en est au premier tour. Attention :
   l'écart doit être VIDE si ce n'est pas le preneur. *)
let peut_montrer_poignee main ecart poignee_donnee = 
  let (-) a b =
    Liste.to_list
      (Liste.difference (Liste.of_list a) (Liste.of_list b)) in
  let poignee = Liste.to_list (Liste.of_list
                                 (List.filter (fun c -> c = Carte.excuse
                                                        || Carte.est_atout c)
                                    poignee_donnee)) in
  let mes_atouts = List.filter (Carte.est_atout) main in
  let atouts_ecartes = List.filter (Carte.est_atout) ecart in
  let excuse = [Carte.excuse] in
  (List.length main = 15)
  && ((List.length poignee = 8)
      || (List.length poignee = 10)
      || (List.length poignee = 13))
  && (List.length poignee_donnee = List.length poignee)
  && (poignee_donnee - poignee = [])
  && (poignee - poignee_donnee = []) (* poignée donnée = poignée *)
  && ( (* 1er cas : je ne montre que des atouts à moi *)
    (poignee - mes_atouts = [])
    ||
    (* 2ème cas : je possède l'excuse, je montre l'excuse et que des
       atouts à moi, et il ne me reste pas d'autre atout à montrer *)
    (excuse - main = []
     && excuse - poignee = []
     && poignee - excuse - mes_atouts = []
     && mes_atouts - poignee = [])
    ||
    (* 3ème cas : je ne possède pas l'excuse, je ne la montre pas, je
       montre des atouts à moi et des atouts écartés, et il ne me reste
       pas d'autre atout à montrer. *)
    (excuse - main = excuse
     && excuse - poignee = excuse
     && poignee - mes_atouts - atouts_ecartes = []
     && mes_atouts - poignee = [])
    ||
    (* 4ème cas : je possède l'excuse, je la montre, je montre au plus
       des atouts à moi, l'excuse et des atouts écartés, et il ne me
       reste pas d'autre atout à montrer.*)
    (excuse - main = []
     && excuse - poignee = []
     && poignee - mes_atouts - excuse - atouts_ecartes = []
     && mes_atouts - poignee = []))

(* Il reste à vérifier que le jeu a commencé, que c'est bien à ce joueur de jouer. *)
let peut_jouer main carte_appelee cartes_sur_le_tapis carte_a_jouer =
  let valeur_atouts =
    List.map
      (fun c ->
         if Carte.est_atout c then fst c
         else 0)
      cartes_sur_le_tapis in
  let pgo = List.fold_left (max) 0 valeur_atouts in
  (* pgo vaut 0 si il n'y a pas d'atout sur le tapis *)
  let carte_appelee =
    match carte_appelee with
    | None -> failwith "On n'a pas encore appelé de carte."
    | Some c -> c
  in
  let carte_possedee = List.exists ((=) carte_a_jouer) main in
  let premier_tour = List.length main = 15 in
  let couleur_demandee =
    match cartes_sur_le_tapis with
    | [] -> None
    | [exc] when exc = Carte.excuse -> None
    | exc :: (_, c) :: _ when exc = Carte.excuse -> Some c
    | (_, c) :: _ -> Some c in
  let joue_excuse = carte_a_jouer = Carte.excuse in
  let joue_atout = Carte.est_atout carte_a_jouer in
  let interdit_au_premier_tour =
    (* Pas de couleur demandée, au premier tour, de la couleur
       appelée, pas la carte appelée *)
    couleur_demandee = None
    && premier_tour
    && snd carte_a_jouer = snd carte_appelee
    && carte_a_jouer <> carte_appelee in
  let ouvre = couleur_demandee = None in
  (* Pas de couleur demandée *)
  let fournit =
    match couleur_demandee with None -> false
                              | Some d -> snd carte_a_jouer = d in
  let fournit_atout =
    match couleur_demandee with
    | Some Carte.Atout -> fournit
    | _ -> false in
  let surcoupe =
    snd carte_a_jouer = Carte.Atout
    && fst carte_a_jouer > pgo in
  let possede_atout = List.exists (Carte.est_atout) main in
  let possede_atout_superieur =
    List.exists (fun (v, c) -> c = Carte.Atout && v > pgo)
      main in
  let peut_fournir = List.exists
      (fun (_, c) -> Some c = couleur_demandee)
      main in
  (* C'est bon :
   * - si je ne joue pas une carte interdite au premier tour,
   * - si je possède cette carte,
   * - si l'une des conditions suivantes est vérifiée :
   *    - je fais une ouverture,
   *    - je joue l'excuse,
   *    - je fournis,
   *    - je fournis (atout) :
   *      - je fournis à l'atout,
   *      - l'une des deux conditions suivantes est vérifiée :
   *        - je surcoupe,
   *        - je ne possède pas d'atout supérieur
   *    - je coupe :
   *      - je ne peux pas fournir,
   *      - je joue atout,
   *      - l'une des deux conditions suivantes est vérifiée :
   *        - je surcoupe,
   *        - je ne possède pas d'atout supérieur
   *    - je pisse :
   *      - je ne peux pas fournir,
   *      - je ne joue pas atout,
   *      - je ne possède pas d'atout. *)
  not interdit_au_premier_tour
  && carte_possedee
  &&(
    ouvre
    || joue_excuse
    || fournit
    ||(
      fournit_atout
      &&(
        surcoupe
        || not (possede_atout_superieur)
      )
    )
    ||(
      not peut_fournir
      && joue_atout
      &&(
        surcoupe
        || not (possede_atout_superieur)
      )
    )
    ||(
      not peut_fournir
      && not joue_atout
      && not possede_atout
    )
  )

let peut_distribuer distribution =
  (* 6 éléments, dont 15 cartes par personne et 3 pour le chien, avec surjectivité et pas de petit sec (pour les joueurs) *)
  let tailles =
    Array.to_list
      (Array.map (List.length) distribution) in
  let surjection = Array.make 78 false in
  let petit_sec main =
    let atouts = List.filter (Carte.est_atout) main in
    let excuse = if List.exists ((=) Carte.excuse) main
      then [Carte.excuse] else [] in
    let atouts = excuse @ atouts in
    (List.length main = 15)
(* On peut avoir petit sec au chien *)
    && (List.exists ((=) Carte.petit) main)
    && (List.length atouts = 1)
  in
  let petit_sec = Array.map (petit_sec) distribution in
  let petit_sec = Array.fold_left (||) false petit_sec in
  let () =
    Array.iter
      (List.iter
         (fun c ->
            let i = Carte.int_of_carte c in
            surjection.(i) <- true))
      distribution in
  let tailles_ok = tailles = [15; 15; 15; 15; 15; 3] in
  let surjection = Array.fold_left (&&) true surjection in
  let pas_petit_sec = not petit_sec in
  tailles_ok && surjection && pas_petit_sec
