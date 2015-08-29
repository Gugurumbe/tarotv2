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

let trier liste =
  let presents = Array.make 79 false in
  let inserer c =
    let i = Carte.int_of_carte c in
    presents.(i) <- true
  in
  let () = List.iter inserer liste in
  let presents =
    Array.mapi
      (fun i ok -> (Carte.carte_of_int i, ok))
      presents in
  let presents = Array.to_list presents in
  let presents = List.filter (snd) presents in
  List.map (fst) presents

let supermodulo k n = ((k mod n) + n) mod n

type t = {
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
  (* L'ouvreur indice 15 existe : c'est le joueur qui a remporté
     le dernier pli. *)
  levees: Carte.carte list list array;
  mutable i_pli: int; (* Le numéro du pli *)
  scores: int array; (* Cumulés *)
  etats_en_attente: message Queue.t array;
}

let peek_message t i =
  if Queue.is_empty t.etats_en_attente.(i) then None
  else Some (Queue.peek t.etats_en_attente.(i))

let next_message t i =
  let _ = Queue.take t.etats_en_attente.(i) in
  ()

let partie_terminee t =
  match t.distribution with
  | [] -> Some (t.scores)
  | _ -> None

let creer_partie distributions =
  let ok = List.map (Verifications.peut_distribuer)
      distributions in
  if List.fold_left (&&) true ok then
    let p = {
      i_manche = 0;
      distribution = distributions;
      encheres = [];
      preneur = None;
      carte_appelee = None;
      joueur_appele = None;
      ecart = None;
      chelem_demande = None;
      poignees_montrees = Array.make 5 [];
      ouvreurs = Array.make 16 0;
      levees = Array.make 15 [];
      i_pli = 0;
      scores = Array.make 5 0;
      etats_en_attente = Array.init 5 (fun _ -> Queue.create ());
    }
    in
    let () =
      match p.distribution with
      | [] -> ()
      | main :: _ ->
        for i = 0 to 4 do
          Queue.push begin {
            evenement = NouvelleManche;
            mon_numero = i;
            numero_manche = 0;
            mon_jeu = Array.of_list (trier main.(i));
            chien = [||];
            encheres = [||];
            preneur = None;
            carte_appelee = None;
            ecart = [||];
            chelem_demande = None;
            poignees_montrees = [||];
            entameur = None;
            pli_en_cours = [||];
            dernier_entameur = None;
            dernier_pli = [||];
            score = Array.make 5 0;
            doit_priser = (i = 0);
            doit_appeler = false;
            doit_ecarter = false;
            doit_decider_chelem = false;
            peut_montrer_poignee = false;
            doit_jouer = false;
          } end
            (p.etats_en_attente.(i))
        done
    in
    Some p
  else None
