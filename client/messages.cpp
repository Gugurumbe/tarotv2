#include "messages.hpp"
#include <QDebug>

using namespace std;
using namespace tarotv::protocol;
using namespace tarotv::game;

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
	qDebug()<<"Reçu : en jeu";
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

tarotv::protocol::message_jeu tarotv::protocol::get_message_jeu(const value & v){
  message_jeu msg;
  map<string, value> table;
  map<string, value>::iterator i;
  if(v.to_table(table)){
    i = table.find("evenement");
    if(i != table.end()){
      if(i->second.type() == value::is_string){
	if(i->second.to_string() == "NouvelleManche"){msg.evenement = nouvelle_manche;}
	else if(i->second.to_string() == "Enchere"){msg.evenement = enchere;}
	else if(i->second.to_string() == "Appel"){msg.evenement = appel;}
	else if(i->second.to_string() == "ChienDevoile"){msg.evenement = chien_devoile;}
	else if(i->second.to_string() == "EcartEffectue"){msg.evenement = ecart_effectue;}
	else if(i->second.to_string() == "Jeu"){msg.evenement = jeu;}
	else if(i->second.to_string() == "PoigneeMontree"){msg.evenement = poignee_montree;}
	else if(i->second.to_string() == "CarteJouee"){msg.evenement = carte_jouee;}
	else if(i->second.to_string() == "PliTermine"){msg.evenement = pli_termine;}
	else if(i->second.to_string() == "MancheTerminee"){msg.evenement = manche_terminee;}
	else throw invalid_message_structure("Invalid value for field evenement : "
					     + i->second.to_string());
      } else throw invalid_message_structure("Expected string argument in evenement field, got "
					     + i->second.print());
    } else throw invalid_message_structure("Missing evenement field.");
    i = table.find("mon_numero");
    if(i != table.end()){
      if(!(i->second.to_int(msg.mon_numero)))
	throw invalid_message_structure("Expected an int for mon_numero field, got "
					+ i->second.print());
    }
    i = table.find("numero_manche");
    if(i != table.end()){
      if(!(i->second.to_int(msg.numero_manche)))
	throw invalid_message_structure("Expected an int for numero_manche field, got "
					+ i->second.print());
    }
    i = table.find("mon_jeu");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.mon_jeu.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator j = liste.begin(); j != liste.end(); j++){
	  int numero;
	  if(j->to_int(numero)){
	    msg.mon_jeu.push_back(numero);
	  } else throw invalid_message_structure("Expected an int for a card, got "
						 + j->print());
	}
      } else throw invalid_message_structure("Expected a list for mon_jeu field, got "
					     + i->second.print());
    }
    i = table.find("chien");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.chien.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator j = liste.begin(); j != liste.end(); j++){
	  int numero;
	  if(j->to_int(numero)){
	    msg.chien.push_back(numero);
	  } else throw invalid_message_structure("Expected an int for a card, got "
						 + j->print());
	}
      } else throw invalid_message_structure("Expected a list for chien field, got "
					     + i->second.print());
    }
    i = table.find("encheres");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.encheres.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator j = liste.begin(); j != liste.end(); j++){
	  int e;
	  if(j->to_int(e)){
	    msg.encheres.push_back(e);
	  } else throw invalid_message_structure("Expected an int for a... une enchère... got "
						 + j->print());
	}
      } else throw invalid_message_structure("Expected a list for encheres field, got "
					     + i->second.print());
    }
    i = table.find("preneur");
    if(i != table.end()){
      int p;
      if(i->second.to_int(p)){
	msg.preneur.push_back(p);
      } else throw invalid_message_structure("Expected an int for... le preneur... got "
					     + i->second.print());
    }
    i = table.find("carte_appelee");
    if(i != table.end()){
      int p;
      if(i->second.to_int(p)){
	msg.carte_appelee.push_back(p);
      } else throw invalid_message_structure("Expected an int for... la carte appelée... got "
					     + i->second.print());
    }
    i = table.find("ecart");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.ecart.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator j = liste.begin(); j != liste.end(); j++){
	  vector<carte> c;
	  string type_visible;
	  value resultat_visible;
	  int carte_visible;
	  if(j->type() == value::is_string && j->to_string() == "Cachee"){
	    msg.ecart.push_back(c);
	  } else if(j->to_labelled(type_visible, resultat_visible)
		    && type_visible == "Visible"
		    && resultat_visible.to_int(carte_visible)){
	    c.push_back(carte_visible);
	    msg.ecart.push_back(c);
	  } else throw invalid_message_structure("Expected Cachee or Visible of int, got "
						 + j->print());	  
	}
      } else throw invalid_message_structure("Expected a list for ecart field, got "
					     + i->second.print());
    }
    i = table.find("chelem_demande");
    if(i != table.end()){
      bool ok;
      if(i->second.to_bool(ok)){
	msg.chelem_demande.push_back(ok);
      } else throw invalid_message_structure("Expected bool for field chelem_demande, got "
					     + i->second.print());
    }
    i = table.find("poignees_montrees");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.poignees_montrees.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator poignee = liste.begin();
	    poignee != liste.end(); poignee++){
	  vector<carte> p; int c;
	  if(poignee->type() == value::is_list){
	    vector<value> lcartes = poignee->to_list();
	    for(vector<value>::const_iterator atout = lcartes.begin();
		atout != lcartes.end(); atout++){
	      if(atout->to_int(c)){
		p.push_back(c);
	      }
	      else throw invalid_message_structure("Pas un atout, " + atout->print());
	    }
	    msg.poignees_montrees.push_back(p);
	  }
	  else throw invalid_message_structure("Pas une poignée, " + poignee->print());
	}
      }
      else throw invalid_message_structure("Liste (de poignées) attendue, et non "
					   + i->second.print());
    }
    i = table.find("entameur");
    if(i != table.end()){
      int e;
      if(i->second.to_int(e)){
	msg.entameur.push_back(e);
      } else throw invalid_message_structure("Entier attendu (entameur), et non "
					     + i->second.print());
    }
    i = table.find("pli_en_cours");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.pli_en_cours.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator ensemble_cartes = liste.begin();
	    ensemble_cartes != liste.end(); ensemble_cartes++){
	  vector<carte> p; int c;
	  if(ensemble_cartes->type() == value::is_list){
	    vector<value> lcartes = ensemble_cartes->to_list();
	    for(vector<value>::const_iterator carte_jouee = lcartes.begin();
		carte_jouee != lcartes.end(); carte_jouee++){
	      if(carte_jouee->to_int(c)){
		p.push_back(c);
	      }
	      else throw invalid_message_structure("Pas une carte, " + carte_jouee->print());
	    }
	    msg.pli_en_cours.push_back(p);
	  }
	  else throw invalid_message_structure("Pas un ensemble de cartes, "
					       + ensemble_cartes->print());
	}
      }
      else throw invalid_message_structure("Liste (de cartes) attendue, et non "
					   + i->second.print());
    }
    i = table.find("dernier_entameur");
    if(i != table.end()){
      int e;
      if(i->second.to_int(e)){
	msg.dernier_entameur.push_back(e);
      } else throw invalid_message_structure("Entier attendu (dernier_entameur), et non "
					     + i->second.print());
    }
    i = table.find("dernier_pli");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.dernier_pli.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator ensemble_cartes = liste.begin();
	    ensemble_cartes != liste.end(); ensemble_cartes++){
	  vector<carte> p; int c;
	  if(ensemble_cartes->type() == value::is_list){
	    vector<value> lcartes = ensemble_cartes->to_list();
	    for(vector<value>::const_iterator carte_jouee = lcartes.begin();
		carte_jouee != lcartes.end(); carte_jouee++){
	      if(carte_jouee->to_int(c)){
		p.push_back(c);
	      }
	      else throw invalid_message_structure("Pas une carte, " + carte_jouee->print());
	    }
	    msg.dernier_pli.push_back(p);
	  }
	  else throw invalid_message_structure("Pas un ensemble de cartes, "
					       + ensemble_cartes->print());
	}
      }
      else throw invalid_message_structure("Liste (de cartes) attendue, et non "
					   + i->second.print());
    }
    i = table.find("score");
    if(i != table.end()){
      if(i->second.type() == value::is_list){
	msg.score.clear();
	vector<value> liste = i->second.to_list();
	for(vector<value>::const_iterator joueur = liste.begin();
	    joueur != liste.end(); joueur++){
	  int s;
	  if(joueur->to_int(s)){
	    msg.score.push_back(s);
	  }
	  else throw invalid_message_structure("Pas un score, "
					       + joueur->print());
	}
      }
      else throw invalid_message_structure("Liste (de nombres) attendue, et non "
					   + i->second.print());
    }
    i = table.find("doit_priser");
    if(i != table.end()){
      if(!(i->second.to_bool(msg.doit_priser))){
	throw invalid_message_structure("Expected bool for field doit_priser, got "
					+ i->second.print());
      }
    } else throw invalid_message_structure("Il manque doit_priser, " + v.print());
    i = table.find("doit_appeler");
    if(i != table.end()){
      if(!(i->second.to_bool(msg.doit_appeler))){
	throw invalid_message_structure("Expected bool for field doit_appeler, got "
					+ i->second.print());
      }
    } else throw invalid_message_structure("Il manque doit_appeler, " + v.print());
    i = table.find("doit_ecarter");
    if(i != table.end()){
      if(!(i->second.to_bool(msg.doit_ecarter))){
	throw invalid_message_structure("Expected bool for field doit_ecarter, got "
					+ i->second.print());
      }
    } else throw invalid_message_structure("Il manque doit_ecarter, " + v.print());
    i = table.find("doit_decider_chelem");
    if(i != table.end()){
      if(!(i->second.to_bool(msg.doit_decider_chelem))){
	throw invalid_message_structure("Expected bool for field doit_decider_chelem, got "
					+ i->second.print());
      }
    } else throw invalid_message_structure("Il manque doit_decider_chelem, " + v.print());
    i = table.find("peut_montrer_poignee");
    if(i != table.end()){
      if(!(i->second.to_bool(msg.peut_montrer_poignee))){
	throw invalid_message_structure("Expected bool for field peut_montrer_poignee, got "
					+ i->second.print());
      }
    } else throw invalid_message_structure("Il manque peut_montrer_poignee, " + v.print());
    i = table.find("doit_jouer");
    if(i != table.end()){
      if(!(i->second.to_bool(msg.doit_jouer))){
	throw invalid_message_structure("Expected bool for field doit_jouer, got "
					+ i->second.print());
      }
    } else throw invalid_message_structure("Il manque doit_jouer, " + v.print());
  }
  else throw invalid_message_structure("No game message arguments in " + v.print());
  return msg;
}
