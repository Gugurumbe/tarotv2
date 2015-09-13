#ifndef MESSAGES_DEFINIS

#define MESSAGES_DEFINIS

#include <string>
#include <vector>
#include <map>
#include <stdexcept>

#include "value.hpp"

namespace tarotv{
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
  };
};

#endif
