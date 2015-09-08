#include "tarotv.hpp"
#include "tarotv_ui.h"
#include "q_requests.hpp"
#include "dock_connexion.hpp"
#include "dock_login.hpp"
#include <iostream>
#include <QDebug>

using namespace tarotv::protocol;
using namespace tarotv::client;
using namespace tarotv::ui;

fenetre::fenetre(QWidget * parent):
  QMainWindow(parent),
  m_ui(new Ui::main_window),
  m_liste(new liste_jhj(this)){
  m_ui->setupUi(this);
  m_ui->liste_jhj->setModel(m_liste);
  QObject::connect(this, SIGNAL(update_model()), this, SLOT(do_update_model()));
  
  QObject::connect(this, SIGNAL(server_ok(bool)),
		   m_ui->contenu_dock_connexion, SLOT(interdire_changement(bool)));
  QObject::connect(this, SIGNAL(server_ok(bool)),
		   m_ui->contenu_dock_connexion, SLOT(est_connecte(bool)));
  QObject::connect(m_ui->contenu_dock_connexion, SIGNAL(connexion_demandee(QHostAddress)),
		   this, SLOT(ask_server_config(QHostAddress)));
  QObject::connect(m_ui->contenu_dock_connexion, SIGNAL(deconnexion_demandee()),
		   this, SLOT(disconnect_from_sgsj()));
  
  QObject::connect(this, SIGNAL(auth_ok(bool)),
		   m_ui->contenu_dock_login, SLOT(interdire_changement(bool)));
  QObject::connect(this, SIGNAL(server_ok(bool)),
		   m_ui->contenu_dock_login, SLOT(est_connecte(bool)));
  QObject::connect(this, SIGNAL(auth_ok(bool)),
		   m_ui->contenu_dock_login, SLOT(est_identifie(bool)));
  QObject::connect(m_ui->contenu_dock_login, SIGNAL(login_demande(QString)),
		   this, SLOT(login(QString)));
  QObject::connect(m_ui->contenu_dock_login, SIGNAL(logout_demande()),
		   this, SLOT(logout()));
  
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
void fenetre::on_liste_jhj_selection_changed(){
  int nombre_invites = m_ui->liste_jhj->selectionModel()->selectedIndexes().size();
  bool ok = valider_invitation(nombre_invites);
  if(ok){
    emit message(tr("Vous pouvez inviter ces personnes."));
  }
  else{
    emit message(tr("Vous ne pouvez pas inviter ces personnes."));
  }
  m_ui->bouton_inviter->setEnabled(ok);
}

#define raise_dock(action, dock)			\
  void fenetre::on_triggered(action){	\
    m_ui->dock->raise();			\
  }

raise_dock(action_win_listejoueurs, dock_liste_joueurs);
raise_dock(action_win_connexion, dock_connexion);
raise_dock(action_win_discussion, dock_discussion);
raise_dock(action_win_login, dock_login);

void fenetre::set_id(QString id){
  m_id = id;
  emit message(tr("Vous êtes authentifié : ") + id);
  emit auth_ok(true);
}
void fenetre::auth_refused(){
  emit message(tr("Authentification échouée."));
  emit auth_ok(false);
}
void fenetre::logout(){
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
