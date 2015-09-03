module type Data =
sig
  type t
  val eq: t -> t -> bool
end

module Make (Parametre:Data) =
struct
  let table = Hashtbl.create 10
  let exists = Hashtbl.mem table
  let set name invit =
    let () = if Hashtbl.mem table name
      then Hashtbl.remove table name in
    Hashtbl.add table name invit
  let get = Hashtbl.find table
  let get_ready () =
    let rec invitations_egales = function
      | [] 
      | [Some _] -> true
      | (Some (a, b)) :: (Some (c, d)) :: tl
        when a = c && Parametre.eq b d ->
        invitations_egales (Some (c, d) :: tl)
      | _ -> false
    in
    let examiner nom (liste, invitation) reussi =
      let invitations = List.map (Hashtbl.find table) liste in
      if invitations_egales ((Some (liste, invitation)) :: invitations)
      then let () = List.iter (Hashtbl.remove table) liste in
        (liste, invitation) :: reussi
      else reussi
    in
    let examiner nom i r =
      match i with
      | None -> r
      | Some x -> examiner nom x r
    in
    Hashtbl.fold examiner table []
end
