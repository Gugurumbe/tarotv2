type couleur = 
  | Coeur
  | Pique
  | Carreau
  | Trefle
  | Atout
  | Excuse ;;

type valeur = int

type carte = (valeur * couleur)

exception Pas_une_carte
exception Pas_une_couleur
exception Pas_une_valeur

let de a b = (a, b)

let (%%) = de
	       
let noms_valeurs_c =
  [| "as" ; "deux" ; "trois" ; "quatre" ; "cinq" ; "six" ; "sept" ; "huit" ; 
     "neuf" ; "dix" ; "valet" ; "cavalier" ; "dame" ; "roi" |]

let noms_valeurs_a =
  [| "petit" ; "deux" ; "trois" ; "quatre" ; "cinq" ; "six" ; "sept" ;
  "huit" ; "neuf" ; "dix" ; "onze" ; "douze" ; "treize" ; "quatorze" ;
  "quinze" ; "seize" ; "dix-sept" ; "dix-huit" ; "dix-neuf" ; "vingt"
  ; "vingt-et-un" |]

let couleurs = [|Coeur ; Pique ; Carreau ; Trefle ; Atout ; Excuse|]

let noms_couleurs = Array.map (function
				| Coeur -> "cœur"
				| Pique -> "pique"
				| Carreau -> "carreau"
				| Trefle -> "trèfle"
				| Atout -> "atout"
				| Excuse -> "excuse") couleurs

let valeurs = Array.init 21 (fun i -> i+1)

let i_couleurs = 
  let t = Hashtbl.create 6 in
  Array.iteri (fun c i -> Hashtbl.add t i c) couleurs ;
  t

let nombre_de_chaque_couleur = 
  Array.map
    (function 
      | Coeur | Carreau | Trefle | Pique -> 14
      | Atout -> 21
      | Excuse -> 2) couleurs

let cartes = 
  let valeurs = 
    Array.mapi
      (fun i n -> 
       Array.init 
	 n (fun j -> 
	    (valeurs.(j), couleurs.(i))))
      nombre_de_chaque_couleur
  in
  Array.concat (Array.to_list valeurs) 

let i_cartes =
  let t = Hashtbl.create 79 in
  let () = Array.iteri (fun c i -> Hashtbl.add t i c) cartes in
  t

let noms_cartes =
  Array.map
    (fun (v, c) ->
     match (v, c) with
     | (x, Pique) 
     | (x, Coeur)
     | (x, Carreau)
     | (x, Trefle) -> 
	(noms_valeurs_c.(x - 1))^" de "
	^(noms_couleurs.(Hashtbl.find i_couleurs c))
     | (1, Atout) -> "petit"
     | (21, Atout) -> "vingt-et-un"
     | (x, Atout) ->
	(noms_valeurs_a.(x - 1))^" d'"
	^(noms_couleurs.(Hashtbl.find i_couleurs c))
     | (1, Excuse) -> "excuse"
     | (2, Excuse) -> "dette d'excuse"
     | _ -> failwith "Ne peut arriver.")
    cartes

let int_of_couleur c = 
  try
    Hashtbl.find i_couleurs c
  with
  |Not_found -> raise Pas_une_couleur

let int_of_valeur v = 
  if v >= 1 && v <= 21 then
    v - 1 
  else raise Pas_une_valeur

let int_of_carte c =
  try
    Hashtbl.find i_cartes c
  with
  | Not_found -> raise Pas_une_carte

let string_of_couleur c =
  noms_couleurs.(int_of_couleur c)

let string_of_valeur v atout =
  if atout then noms_valeurs_a.(int_of_valeur v)
  else if v < Array.length noms_valeurs_c then noms_valeurs_c.(int_of_valeur v)
  else raise Pas_une_valeur

let string_of_carte c =
  noms_cartes.(int_of_carte c)

let couleur_of_int i = 
  try
    couleurs.(i)
  with 
  | Invalid_argument "index out of bounds" -> raise Pas_une_couleur

let valeur_of_int i = 
  try
    valeurs.(i)
  with
  | Invalid_argument "index out of bounds" -> raise Pas_une_valeur

let carte_of_int i =
  try
    cartes.(i)
  with
  | Invalid_argument "index out of bounds" -> raise Pas_une_carte

let sup_strict (v1, c1) (v2, c2) =
  if c1 = c2 then v1 > v2
  (* On se base uniquement sur la valeur *)
  else
(* Je suis supérieur strict si je suis un atout ou l'autre *)
(* est une excuse *)
    c1 = Atout || c2 = Excuse

let inf_strict a b = sup_strict b a

let sup_large a b = not (inf_strict a b)

let inf_large a b = sup_large b a

let (%>) = sup_strict
let (%<) = inf_strict
let (%>=) = sup_large
let (%<=) = inf_large
    
let est_tete (v, c) =
  match c with
  | Atout
  | Excuse -> false
  | _ -> v >= 11 && v <= 14 
			   
let valeur_tete (v, c) = (*unsafe*)
  v - 11

let est_roi c = 
  est_tete c
  && valeur_tete c = 3

let appeler_en_priorite =
  let sous_couleurs =
    [Coeur ; Pique ; Carreau ; Trefle] in
  let valeurs =
    [11 ; 12 ; 13 ; 14] in
  List.map
    (fun v -> List.map (fun c -> v %% c) 
		       sous_couleurs)
    (List.rev valeurs)
    
let roi = 14 
let dame = 13 
let cavalier = 12 
let valet = 11
let petit = 1 %% Atout
let excuse = 1 %% Excuse
let vingt_et_un = 21 %% Atout
let fausse_excuse = 2 %% Excuse

let est_atout = function
  | (_, Atout) -> true
  | _ -> false

let est_bout c = 
  c = petit || c = vingt_et_un || c = excuse

let demipoints (c, v) =
  match (c, v) with
  | (1, Atout) -> 9
  | (21, Atout) -> 9
  | (_, Atout) -> 1
  | (1, Excuse) -> 8 (* La vraie excuse *)
  | (11, _) -> 3 (* valets *)
  | (12, _) -> 5
  | (13, _) -> 7
  | (14, _) -> 9
  | _ -> 1
