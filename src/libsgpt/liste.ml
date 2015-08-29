type t = bool array

let aucune () = Array.make 79 false

let toutes () = Array.make 79 false

let to_list t =
  let rec examiner cartes i =
    if i < Array.length t then
      if t.(i) then
	examiner ((Carte.carte_of_int i) :: cartes) (i + 1)
      else examiner cartes (i + 1)
    else List.rev cartes
  in
  examiner [] 0

let of_list liste =
  let t = aucune () in
  let rec examiner = function
    | [] -> t
    | c :: b ->
       let i = Carte.int_of_carte c in
       let () = t.(i) <- true in
       examiner b
  in
  examiner liste

let union ll =
  let t = aucune () in
  let ajouter liste =
    Array.iteri
      (fun i ok ->
       if ok then t.(i) <- true)
      liste
  in
  let () = List.iter (ajouter) ll in
  t

let intersection ll =
  let t = toutes () in
  let soustraire liste =
    Array.iteri
      (fun i ok ->
       if not ok then t.(i) <- false)
      liste
  in
  let () = List.iter (soustraire) ll in
  t

let contraire =
  Array.map (not)

let difference a b =
  intersection [a ; contraire b]

let filtrer fonction liste =
  Array.mapi
    (fun i ok ->
     if ok && not (fonction (Carte.carte_of_int i)) then
       false
     else ok)
    liste
