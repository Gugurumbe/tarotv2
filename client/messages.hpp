#ifndef MESSAGES_DEFINIS

#define MESSAGES_DEFINIS

#include <string>
#include <vector>
#include <map>
#include <stdexcept>

#include "value.hpp"

namespace tarotv{
  namespace game{
    typedef int carte;
  };
  namespace protocol{
    class invalid_message_structure: public std::runtime_error{
    public: invalid_message_structure(const std::string & err):
      std::runtime_error("Invalid message structure." + err){}
    };
    struct nouveau_joueur{
	std::string nom;
    };
    struct depart_joueur{
      std::string nom;
    };
    struct invitation_annulee{
	std::string responsable;
    };
    struct invitation{
      std::string joueur;
      std::vector<std::string> invites;
      std::map<std::string, value> parametres;	
    };
    struct text{
      std::string joueur;
	std::string contenu;
    };
    enum t_message {
      is_nouveau_joueur, is_depart_joueur, is_invitation_annulee,
      is_invitation, is_text, is_en_jeu
    };
    struct message{
      t_message t;
      struct nouveau_joueur nouveau_joueur;
      struct depart_joueur depart_joueur;
      struct invitation invitation;
      struct invitation_annulee invitation_annulee;
      struct text text;
    };
    struct message get_message(const value & v);
    typedef struct message message;
    enum t_message_jeu{
      nouvelle_manche, enchere, appel, chien_devoile, ecart_effectue,
      jeu, poignee_montree, carte_jouee, pli_termine, manche_terminee
    };
    struct message_jeu{
      enum t_message_jeu evenement;
      int mon_numero;
      int numero_manche;
      std::vector<tarotv::game::carte> mon_jeu;
      std::vector<tarotv::game::carte> chien;
      std::vector<int> encheres;
      std::vector<int> preneur;
      std::vector<tarotv::game::carte> carte_appelee;
      std::vector<std::vector<tarotv::game::carte> > ecart;
      std::vector<bool> chelem_demande;
      std::vector<std::vector<tarotv::game::carte> > poignees_montrees;
      std::vector<int> entameur;
      std::vector<std::vector<tarotv::game::carte> > pli_en_cours;
      std::vector<int> dernier_entameur;
      std::vector<std::vector<tarotv::game::carte> > dernier_pli;
      std::vector<int> score;
      bool doit_priser;
      bool doit_appeler;
      bool doit_ecarter;
      bool doit_decider_chelem;
      bool peut_montrer_poignee;
      bool doit_jouer;
    };
    struct message_jeu get_message_jeu(const value & v);
  };
};

#endif
