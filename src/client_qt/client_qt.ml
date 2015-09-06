(* The goal of this file is to replace the executable with another executable built by ocamlbuild but not understood by oasis. *)

let () = Sys.remove "_build/src/client_qt/client_qt.byte"

let () = Sys.rename "_build/src/client_qt/client_qt.cxxnative" "_build/src/client_qt/client_qt.byte"
