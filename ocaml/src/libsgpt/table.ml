let compteur () =
  let i = ref (-1) in
  let compter () =
    let () = incr i in
    !i
  in
  compter

let table = Hashtbl.create 42

let compteur = compteur ()

let nouvelle_partie distributions =
  match Partie.creer_partie distributions with
  | None -> None
  | Some t ->
    let num = compteur () in
    let cle = string_of_int num in
    let () = Hashtbl.add table cle t in
    Some cle

let lister_parties () =
  Hashtbl.fold (fun cle _ acc -> cle :: acc) table []

let trouver_partie id =
  Hashtbl.find table id

let supprimer_partie id =
  Hashtbl.remove table id

let lister_joueurs_prets () =
  Hashtbl.fold (fun cle partie acc ->
      let tous_joueurs = [0;1;2;3;4] in
      let peek =
        List.map
          (fun i -> (i, Partie.peek_message partie i))
          tous_joueurs in
      let a_un_message =
        List.filter (fun (_, msg) -> msg <> None) peek in
      let joueurs_prets = List.map (fst) a_un_message in
      (List.map (fun i -> (cle, i)) joueurs_prets)
      @ acc)
    table []

let lister_parties_terminees () =
  Hashtbl.fold (fun cle partie acc ->
      let scores = Partie.partie_terminee partie in
      match scores with
      | None -> acc
      | Some res -> (cle, res) :: acc)
    table []
