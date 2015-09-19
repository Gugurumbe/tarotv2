type couleur =
  | Noir
  | Rouge
  | Atout

let couleurs =
  Array.init 79 (fun i_carte ->
      if i_carte >= 56 then Atout
      else if (i_carte / 14) mod 2 = 0 then Noir
      else Rouge)

let open_color = function
  | Noir -> "\027[30m\027[47;1m"
  | Rouge -> "\027[31m\027[47;1m"
  | Atout -> "\027[36m\027[47;1m"

let close_color = "\027[0m"

let render_carte portion couleur i =
  let carte = Carte_ascii.items.(i) in
  let transfo_ligne ligne =
    let portion = Bytes.sub ligne 0 (max 0 (min portion (Bytes.length ligne))) in
    let (prefixe, suffixe) =
      if couleur then
        (open_color couleurs.(i), close_color)
      else ("", "")
    in
    Bytes.concat "" [prefixe; portion; suffixe]
  in
  List.map transfo_ligne carte

type portion =
  | Complet
  | Partiel
        
let render_cartes couleur cartes =
  let une_carte (portion, i) =
    match portion with
    | Complet -> 
      Array.of_list (render_carte max_int couleur i)
    | Partiel ->
      Array.of_list (render_carte 2 couleur i)
  in
  let cartes = List.map une_carte cartes in
  let nlignes = List.fold_left max 0 (List.map Array.length cartes) in
  let get i tab = tab.(i) in
  let dest = Array.init nlignes
      (fun i -> Bytes.concat "" (List.map (get i) cartes)) in
  Array.to_list dest
