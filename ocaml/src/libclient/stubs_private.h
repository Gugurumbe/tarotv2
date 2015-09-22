#ifndef STUBS_PRIVATE_TAROTV_VALUE
#define STUBS_PRIVATE_TAROTV_VALUE

#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "stubs.h"

struct tarotv_value * copy_value_from_caml(value v);
value copy_value_to_caml(struct tarotv_value * v);

value caml_connecte(value interface, value cfg_arr);
value caml_echec_connexion(value interface);
value caml_identifie(value interface, value nom);
value caml_echec_identification(value interface);
value caml_deconnecte(value interface);
value caml_message_envoye(value interface);
value caml_trop_bavard(value interface);
value caml_invitation_reussie(value interface);
value caml_echec_invitation(value interface);
value caml_invitation_annulee(value interface);
value caml_reponse_jeu(value interface, value id_requete, value reponse_opt);
value caml_nouveau_joueur(value interface, value nom);
value caml_depart_joueur(value interface, value nom);
value caml_message_recu(value interface, value expediteur, value message);
value caml_en_jeu(value interface, value sockaddr, value joueur_arr, value parametres);
value caml_invitations_modifiees(value interface, value invitations);
value caml_about_to_delete(value interface);

#endif
