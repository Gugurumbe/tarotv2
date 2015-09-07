#include "tarotv.hpp"
#include "tarotv_ui.h"
#include "q_requests.hpp"
#include <iostream>
#include <QDebug>

using namespace tarotv::protocol;
using namespace tarotv::client;

tarotv::ui::fenetre::fenetre(QWidget * parent):
  QMainWindow(parent),
  m_ui(new Ui::main_window),
  m_liste(new tarotv::ui::liste_jhj(this)){
  m_ui->setupUi(this);
  m_ui->liste_jhj->setModel(m_liste);
  QObject::connect(this, SIGNAL(update_model()), this, SLOT(do_update_model()));
  emit server_ok(false); emit auth_ok(false); emit message("Bienvenue.");
}

tarotv::ui::fenetre::~fenetre(){
  delete m_ui;
}

void tarotv::ui::fenetre::do_update_model(){
  m_liste->setStringList(m_liste_jhj);
}

void tarotv::ui::fenetre::ask_server_config(QHostAddress host, quint16 port){
  value_socket * sock = new value_socket();
  QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
  sock->connectToHost(host, port);
  config_request * req = new config_request(sock);
  QObject::connect(req, SIGNAL(config_response(tarotv::protocol::config)),
		   this, SLOT(set_config(tarotv::protocol::config)));
  QObject::connect(req, SIGNAL(error(QString)),
		   this, SLOT(error_while_getting_config(QString)));
  req->do_request(sock);
}

void tarotv::ui::fenetre::error_while_getting_config(QString err){
  QString msg = tr("Impossible d'interroger le serveur : ") + err;
  emit message(msg);
  emit server_ok(false);
}

void tarotv::ui::fenetre::error_while_getting_id(QString err){
  QString msg = tr("Impossible de s'authentifier : ") + err;
  emit message(msg);
  emit server_ok(false);
}

void tarotv::ui::fenetre::set_config(config cfg){
  game_config = cfg;
  emit message(tr("Le serveur est disponible."));
  emit server_ok(true);
}

bool tarotv::ui::fenetre::valider_invitation(int nombre_invites) const{
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
void tarotv::ui::fenetre::on_liste_jhj_selection_changed(){
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
  void tarotv::ui::fenetre::on_triggered(action){	\
    m_ui->dock->raise();			\
  }

raise_dock(action_win_listejoueurs, dock_liste_joueurs);
raise_dock(action_win_connexion, dock_connexion);
raise_dock(action_win_discussion, dock_discussion);

void tarotv::ui::fenetre::on_bouton_changer_serveur_toggled(bool ok){
  if(ok){
    ask_server_config(QHostAddress(m_ui->champ_adresse->text()), 45678);
    emit message(tr("Connexion à ") + m_ui->champ_adresse->text() + ":45678...");
  }
  else{
    /* Il faut se déconnecter ! */
    emit message(tr("Déconnexion de ") + m_ui->champ_adresse->text() + ".");
    on_bouton_deconnexion_clicked();
    emit server_ok(false);
  }
}
void tarotv::ui::fenetre::on_bouton_connexion_clicked(){
  value_socket * sock = new value_socket();
  QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
  sock->connectToHost(QHostAddress(m_ui->champ_adresse->text()), 45678);
  id_request * req = new id_request(sock);
  QObject::connect(req, SIGNAL(id_accepted(QString)),
  		   this, SLOT(set_id(QString)));
  QObject::connect(req, SIGNAL(id_refused()),
  		   this, SLOT(auth_refused()));
  QObject::connect(req, SIGNAL(error(QString)),
  		   this, SLOT(error_while_getting_id(QString)));
  req->do_request(sock, m_ui->champ_nom->text());
  emit message(tr("Identification en tant que ") + m_ui->champ_nom->text() + "...");
}
void tarotv::ui::fenetre::on_bouton_deconnexion_clicked(){
  value_socket * sock = new value_socket();
  QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
  sock->connectToHost(QHostAddress(m_ui->champ_adresse->text()), 45678);
  logout_request * req = new logout_request(sock);
  req->do_request(sock, m_id);
  emit message(tr("Requête de déconnexion envoyée."));
  emit auth_ok(false);
}
void tarotv::ui::fenetre::set_id(QString id){
  m_id = id;
  emit message(tr("Vous êtes authentifié : ") + id);
  emit auth_ok(true);
}
void tarotv::ui::fenetre::auth_refused(){
  emit message(tr("Authentification échouée."));
  emit auth_ok(false);
}
