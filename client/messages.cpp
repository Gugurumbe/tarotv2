// -*- compile-command: "cd ../../ && make -j 5" -*-
#include "messages.hpp"

using namespace std;
using namespace tarotv::protocol;

tarotv::protocol::message tarotv::protocol::get_message(const tarotv::protocol::value & v){
  value contenu;
  string type;
  struct message msg;
  if(v.to_labelled(type, contenu)){
    map<string, value> table;
    map<string, value>::iterator i;
    if(contenu.to_table(table)){
      if(type == "Nouveau_joueur"){
	i = table.find("joueur");
	if(i != table.end()){
	  if(i->second.type() == value::is_string){
	    msg.t = is_nouveau_joueur;
	    msg.nouveau_joueur.nom = i->second.to_string();
	  }
	  else throw invalid_message_structure("Nouveau_joueur: String expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Nouveau_joueur: no \"joueur\" argument in "
					     + contenu.print());
      }
      else if(type == "Depart_joueur"){
	i = table.find("joueur");
	if(i != table.end()){
	  if(i->second.type() == value::is_string){
	    msg.t = is_depart_joueur;
	    msg.depart_joueur.nom = i->second.to_string();
	  }
	  else throw invalid_message_structure("Depart_joueur: String expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Depart_joueur: no \"joueur\" argument in "
					     + contenu.print());
      }
      else if(type == "Invitation_annulee"){
	i = table.find("joueur");
	if(i != table.end()){
	  if(i->second.type() == value::is_string){
	    msg.t = is_invitation_annulee;
	    msg.invitation_annulee.responsable = i->second.to_string();
	  }
	  else throw invalid_message_structure("Invitation_annulee: String expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Invitation_annulee: no \"joueur\" argument in "
					     + contenu.print());
      }
      else if(type == "Invitation"){
	i = table.find("joueur");
	if(i != table.end()){
	  if(i->second.type() == value::is_string){
	    msg.t = is_invitation;
	    msg.invitation.joueur = i->second.to_string();
	  }
	  else throw invalid_message_structure("Invitation: String expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Invitation: no \"joueur\" argument in "
					     + contenu.print());
	i = table.find("invites");
	if(i != table.end()){
	  if(i->second.type() == value::is_list){
	    vector<value> liste = i->second.to_list();
	    msg.invitation.invites.reserve(liste.size());
	    for(vector<value>::iterator j = liste.begin();
		j != liste.end(); j++){
	      if(j->type() == value::is_string){
		msg.invitation.invites.push_back(j->to_string());
	      }
	      else throw invalid_message_structure("Invitation: string expected as a name in "
						   + j->print());
	    }
	  }
	  else throw invalid_message_structure("Invitation: List expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Invitation: no \"invites\" argument in "
					     + contenu.print());
	i = table.find("argument");
	if(i != table.end()){
	  map<string, value> parametres;
	  if(i->second.to_table(parametres)){
	    msg.invitation.parametres = parametres;
	  }
	  else throw invalid_message_structure("Invitation: Table expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Invitation: no \"argument\" argument in "
					     + contenu.print());
      }
      else if(type == "Message"){
	i = table.find("joueur");
	if(i != table.end()){
	  if(i->second.type() == value::is_string){
	    msg.t = is_text;
	    msg.text.joueur = i->second.to_string();
	  }
	  else throw invalid_message_structure("Text: String expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Text: no \"joueur\" argument in "
					     + contenu.print());
	i = table.find("message");
	if(i != table.end()){
	  if(i->second.type() == value::is_string){
	    msg.text.contenu = i->second.to_string();
	  }
	  else throw invalid_message_structure("Text: String expected in "
					       + i->second.print());
	}
	else throw invalid_message_structure("Text: no \"message\" argument in "
					     + contenu.print());
      }
      else if(type == "En_jeu"){
	msg.t = is_en_jeu;
      }
      else throw invalid_message_structure(type + " is not a valid message type in "
					   + v.print());
    }
    else throw invalid_message_structure("No message arguments in " + v.print());
  }
  else throw invalid_message_structure("No message type in " + v.print());
  return msg;
}
