type decision =
  | Attente
  | Refus
  | Accord

type invitation = {
  noms: Bytes.t array;
  parametres: Value.t;
  prets: decision array;
}

type t = invitation list ref

let memes_elements = Value.memes_elements (Value.listes_egales)
                  
let trouver tab valeur =
  let rec aux i =
    if i >= Array.length tab then None
    else if tab.(i) = valeur then Some i
    else aux (i + 1)
  in
  aux 0

let creer () = ref []

let recevoir_invitation liste responsable invites parametres =
  let nouvelle_liste =
    if List.exists (fun i ->
        Array.to_list i.noms = invites
        && memes_elements i.parametres parametres)
        !liste then
      List.map
        (fun autre_invitation ->
           if Array.to_list autre_invitation.noms = invites
           && memes_elements autre_invitation.parametres parametres then
             let () = match trouver autre_invitation.noms responsable with
               | None -> ()
               | Some i -> autre_invitation.prets.(i) <- Accord in
             autre_invitation
           else
             let () = match trouver autre_invitation.noms responsable with
               | None -> ()
               | Some i -> autre_invitation.prets.(i) <- Refus in
             autre_invitation)
        !liste
    else 
      let nouvelle_invitation = {noms = Array.of_list invites;
                                 parametres = parametres;
                                 prets = Array.make (List.length invites) Attente} in
      let () = match trouver nouvelle_invitation.noms responsable with
        | None -> () (* Au cas où il serait autorisé de ne pas s'inviter soi-même... *)
        | Some i -> nouvelle_invitation.prets.(i) <- Accord in
      let autres = List.map
          (fun autre_invitation ->
             let () = Array.iteri (fun i decision ->
                 let nom = autre_invitation.noms.(i) in
                 match trouver nouvelle_invitation.noms nom with
                 | None -> ()
                 | Some place_invitee ->
                   match decision with
                   | Attente
                   | Refus -> ()
                   | Accord ->
                     nouvelle_invitation.prets.(place_invitee) <- Refus)
                 autre_invitation.prets in
             let () = match trouver autre_invitation.noms responsable with
               | None -> ()
               | Some i -> autre_invitation.prets.(i) <- Refus in
             autre_invitation)
          !liste in
      nouvelle_invitation :: autres
  in
  liste := nouvelle_liste

let invitation_annulee liste responsable =
  let retracter_dans invitation =
    match trouver invitation.noms responsable with
    | None -> invitation
    | Some place_refus ->
      let () = invitation.prets.(place_refus) <- Refus in
      invitation
  in
  let un_ok invitation =
    List.exists ((=) Accord) (Array.to_list invitation.prets)
  in
  liste := List.filter un_ok (List.map retracter_dans !liste)

let concernant gus = List.filter (fun invitation ->
    List.exists ((=) gus) (Array.to_list invitation.noms))
