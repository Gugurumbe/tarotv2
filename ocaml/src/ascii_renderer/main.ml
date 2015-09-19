let couleur = ref false

let a_representer_rev = ref []

let representer chaine =
  if chaine = "" then
    let () = Printf.eprintf "Wrong void argument ''.\n%!" in
    exit 2
  else try match Bytes.get chaine 0 with
    | '+' ->
      let i = int_of_string (Bytes.sub chaine 1 (-1 + Bytes.length chaine)) in
      a_representer_rev := (Renderer.Complet, i) :: (!a_representer_rev)
    | _ ->
      let i = int_of_string chaine in
      a_representer_rev := (Renderer.Partiel, i) :: (!a_representer_rev)
    with Failure "int_of_string" ->
      let () = Printf.eprintf
          "Wrong argument %S. Expected \"+?{int between 0 inclusive and 79 exclusive}\"\n%!"
          chaine in
      exit 3

let speclist = [("-colors", Arg.Set couleur, "Use colors for rendering cards. May be slow.")]

let hello = "tarotv-ascii is a tool to render ASCII card games. \n\
             It prints on standard output a rectangle of size 12 lines * ((2 + a) * x + (16 + a) * y) columns, \
             where x is the number of partially visible cards and y the number of fully visible cards,\
             and a is 0 if no colors are required or 16 if colors are represented. \n\
             The representable cards are every tarot card plus the back of a card.\n"

let usage_message =
  Printf.sprintf "%s 1 78 +13 27 renders a deck containing in this order \
                  the two of spades, a hidden card, the king of spades, \
                  the king of hearts. Only the king of spades is fully visible, \
                  the other cards are reduced to a 2-column card whose name is \
                  fully readable. The numbers of the cards are:\n\
                  \t->from 0 inclusive to 14 exclusive: from ace of spades to king of spades (\"pique\")\n\
                  \t->14 - 28: hearts (\"coeur\")\n\
                  \t->28 - 42: clubs (\"trefle\")\n\
                  \t->42 - 56: diamonds (\"carreau\")\n\
                  \t->56 - 78: trump cards (\"atouts\" + \"excuse\")\n\
                  \t->78: a hidden card."
    (Sys.argv.(0))
      
let () = Arg.parse speclist representer (hello^usage_message)

let () = if !a_representer_rev = [] then
    let () = Printf.eprintf "See option --help for usage.\n%!" in
    ()
  else
    let liste = Renderer.render_cartes !couleur (List.rev !a_representer_rev) in
    List.iter print_endline liste
