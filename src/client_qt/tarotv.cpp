// -*- compile-command: "cd ../../ && make -j 5" -*-
#include "tarotv.hpp"
#include "tarotv_ui.h"
#include "q_requests.hpp"
#include "dock_connexion.hpp"
#include "dock_login.hpp"
#include "dock_discussion.hpp"
#include <iostream>
#include <QDebug>

using namespace tarotv::protocol;
using namespace tarotv::client;
using namespace tarotv::ui;

fenetre::fenetre(QWidget * parent):
  QMainWindow(parent),
  m_ui(new Ui::main_window),
  m_liste(new liste_jhj(this)),
  m_bus(0){
  m_ui->setupUi(this);
  //m_ui->liste_jhj->setModel(m_liste);  
  emit server_ok(false); emit auth_ok(false); emit message("Bienvenue.");
}

fenetre::~fenetre(){
  delete m_ui;
}

void fenetre::do_update_model(){
  m_liste->setStringList(m_liste_jhj);
}

void fenetre::ask_server_config(QHostAddress host){
  value_socket * sock = new value_socket();
  QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
  sock->connectToHost(host, 45678);
  config_request * req = new config_request(sock);
  QObject::connect(req, SIGNAL(config_response(tarotv::protocol::config)),
		   this, SLOT(set_config(tarotv::protocol::config)));
  QObject::connect(req, SIGNAL(error(QString)),
		   this, SLOT(error_while_getting_config(QString)));
  QObject::connect(req, SIGNAL(config_response(tarotv::protocol::config)),
		   m_ui->contenu_dock_connexion, SLOT(connexion_reussie(tarotv::protocol::config)));
  QObject::connect(req, SIGNAL(error(QString)),
		   m_ui->contenu_dock_connexion, SLOT(echec_connexion(QString)));
  m_adresse = host;
  req->do_request(sock);
}

void fenetre::login(QString nom){
  value_socket * sock = new value_socket();
  QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
  sock->connectToHost(m_adresse, 45678);
  id_request * req = new id_request(sock);
  QObject::connect(req, SIGNAL(id_accepted(QString)),
  		   this, SLOT(set_id(QString)));
  QObject::connect(req, SIGNAL(id_refused()),
  		   this, SLOT(auth_refused()));
  QObject::connect(req, SIGNAL(error(QString)),
  		   this, SLOT(error_while_getting_id(QString)));
  QObject::connect(req, SIGNAL(id_accepted(QString)),
  		   m_ui->contenu_dock_login, SLOT(login_reussi(QString)));
  QObject::connect(req, SIGNAL(id_refused()),
  		   m_ui->contenu_dock_login, SLOT(echec_login()));
  QObject::connect(req, SIGNAL(error(QString)),
  		   m_ui->contenu_dock_login, SLOT(erreur(QString)));
  req->do_request(sock, nom);
  emit message(tr("Identification en tant que ") + nom + "...");
}

void fenetre::error_while_getting_config(QString err){
  QString msg = tr("Impossible d'interroger le serveur : ") + err;
  emit message(msg);
  emit server_ok(false);
}

void fenetre::error_while_getting_id(QString err){
  QString msg = tr("Impossible de s'authentifier : ") + err;
  emit message(msg);
  emit server_ok(false);
}

void fenetre::set_config(config cfg){
  game_config = cfg;
  emit message(tr("Le serveur est disponible."));
  emit server_ok(true);
}

bool fenetre::valider_invitation(int nombre_invites) const{
  std::map<std::string, config::elt>::const_iterator i;
  const config & cfg = game_config;
  i = cfg.elts.find("nplayers");
  return
    i != cfg.elts.end()
    &&(i->second.t == config::is_int
       && nombre_invites >= i->second.u.as_int.min
       && nombre_invites <= i->second.u.as_int.max
       && ((nombre_invites - i->second.u.as_int.min)
	   % i->second.u.as_int.incr == 0));
}

void fenetre::set_id(QString id){
  m_id = id;
  emit message(tr("Vous êtes authentifié : ") + id);
  emit auth_ok(true);
  run_bus();
}
void fenetre::auth_refused(){
  emit message(tr("Authentification échouée."));
  emit auth_ok(false);
}
void fenetre::logout(){
  if(m_bus){
    delete m_bus;
    m_bus = 0;
  }
  value_socket * sock = new value_socket();
  QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
  sock->connectToHost(m_adresse, 45678);
  logout_request * req = new logout_request(sock);
  req->do_request(sock, m_id);
  emit message(tr("Requête de déconnexion envoyée."));
  emit auth_ok(false);
}
void fenetre::disconnect_from_sgsj(){
  logout();
  emit server_ok(false);
}
void fenetre::has_message(tarotv::protocol::message msg){
  std::map<std::string, tarotv::protocol::value>::const_iterator i;
  std::vector<std::string>::const_iterator j;
  QMap<QString, tarotv::protocol::value> inv;
  QStringList invites;
  switch(msg.t){
  case is_nouveau_joueur:
    emit message(tr("Entrée de ") + QString::fromStdString(msg.nouveau_joueur.nom) + tr(" !"));
    emit nouveau_joueur(QString::fromStdString(msg.nouveau_joueur.nom));
    break;
  case is_depart_joueur:
    emit message(tr("Départ de ") + QString::fromStdString(msg.depart_joueur.nom) + tr(" !"));
    emit depart_joueur(QString::fromStdString(msg.depart_joueur.nom));
    break;
  case is_invitation_annulee:
    emit message(QString::fromStdString(msg.invitation_annulee.responsable)
		 + tr(" annule son invitation !"));
    emit invitation_annulee(QString::fromStdString(msg.invitation_annulee.responsable));
    break;
  case is_invitation:
    for(i = msg.invitation.parametres.begin(); i != msg.invitation.parametres.end(); i++){
      inv[QString::fromStdString(i->first)] = i->second;
    }
    for(j = msg.invitation.invites.begin(); j != msg.invitation.invites.end(); j++){
      invites << QString::fromStdString(*j);
    }
    if(invites.contains(m_nom)){
      emit message(tr("Vous êtes invité par ") + QString::fromStdString(msg.invitation.joueur)
		   + tr(" !"));
    }
    emit invitation(QString::fromStdString(msg.invitation.joueur), invites, inv);
    break;
  case is_text:
    if(QString::fromStdString(msg.text.joueur) == m_nom){
      emit message(tr("Message envoyé !"));
    }
    else
      emit message(tr("Message de ") + QString::fromStdString(msg.text.joueur) + tr(" !"));
    emit nouveau_message(QString::fromStdString(msg.text.joueur),
			 QString::fromStdString(msg.text.contenu));
    break;
  }
}
void fenetre::run_bus(){
  if(m_bus){
    delete m_bus;
    m_bus = 0;
  }
  m_bus = new msg_bus(m_adresse, m_id, this);
  QObject::connect(m_bus, SIGNAL(has_message(tarotv::protocol::message)),
		   this, SLOT(has_message(tarotv::protocol::message)));
  QObject::connect(m_bus, SIGNAL(end(QString)),
		   this, SLOT(end_of_bus(QString)));
  m_bus->run();
}
void fenetre::end_of_bus(QString why){
  qDebug()<<"Le bus a terminé : "<<why;
}
void fenetre::send_message(QString msg){
  value_socket * sock = new value_socket();
  QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
  sock->connectToHost(m_adresse, 45678);
  msg_request * req = new msg_request(sock);
  QObject::connect(req, SIGNAL(too_chatty()),
  		   this, SIGNAL(trop_bavard()));
  QObject::connect(req, SIGNAL(error(QString)),
  		   this, SIGNAL(trop_bavard())); // Discutable.
  req->do_request(sock, m_id, msg);
  emit message(tr("Envoi d'un message..."));
}
