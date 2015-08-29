type evenement = 
  | NouvelleManche
  | Enchere
  | Appel
  | ChienDevoile
  | EcartEffectue
  | Jeu
  | PoigneeMontree
  | CarteJouee
  | PliTermine
  | MancheTerminee

type message = {
  evenement: evenement;
  joueurs: Bytes.t array;
  mon_numero: int;
  numero_manche: int;
  mon_jeu: Carte.carte array;
  chien: Carte.carte array;
  encheres: int array;
  preneur: int option;
  carte_appelee: Carte.carte option;
  ecart: Carte.carte option array;
  (* Éventuellement (si l'écart est fait), une liste contenant
     éventuellement les atouts écartés. *)
  chelem_demande: bool option;
  poignees_montrees: Carte.carte array array;
  entameur: int option;
  pli_en_cours: Carte.carte array array;
  (* "list list" : si qqn joue l'excuse, il joue les 2 à la fois. *)
  dernier_entameur: int option;
  dernier_pli: Carte.carte array array;
  score: int array;
  doit_priser: bool;
  doit_appeler: bool;
  doit_ecarter: bool;
  doit_decider_chelem: bool;
  peut_montrer_poignee: bool;
  (* Faux si j'ai strictement moins de 8 * (atout ou excuse), en
     piochant dans l'écart si je suis le preneur. *)
  doit_jouer: bool;
}

let trier tab =
  let presents = Array.make 79 false in
  let inserer i =
    let i = Carte.int_of_carte tab.(i) in
    presents.(i) <- true
  in
  let () = for i = 0 to -1 + Array.length tab do
      inserer i done in
  let presents =
    Array.mapi
      (fun i ok -> (Carte.carte_of_int i, ok))
      presents in
  let presents = Array.to_list presents in
  let presents = List.filter (snd) presents in
  List.map (fst) presents

let supermodulo k n = ((k mod n) + n) mod n

type partie = {
  adversaires: Bytes.t array; (* L'ordre ne change pas *)
  mutable i_manche: int;
  mutable distribution: (Carte.carte list array) list;
  (* Toutes les distributions jusqu'à la fin de la partie *)
  mutable encheres: int list;
  mutable preneur: int option;
  mutable carte_appelee: Carte.carte option;
  mutable joueur_appele: int option;
  mutable ecart: Carte.carte list option;
  mutable chelem_demande: bool option;
  poignees_montrees: Carte.carte list array;
  ouvreurs: int array;
  levees: Carte.carte list list array;
  pli_en_cours: int; (* Le numéro du pli *)
  scores_manche: int array; (* Cumulés *)
  etats_en_attente:  message Queue.t array;
}
