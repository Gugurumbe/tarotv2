#include "tarotv.hpp"
#include "ui_tarotv.h"
#include "joueur_hors_jeu.hpp"
#include "q_requests.hpp"
#include <iostream>
#include <QDebug>

using namespace tarotv::protocol;
using namespace tarotv::client;

tarotv::ui::fenetre::fenetre(QWidget * parent):
  QMainWindow(parent),
  m_ui(new Ui::main_window){
  m_ui->setupUi(this);
  tarotv::ui::liste_jhj * liste = new tarotv::ui::liste_jhj(this);
  m_ui->liste_jhj->setModel(liste);
  m_liste_jhj << "Toto" << "Machin" << "Bidule" << "Chose" << "Truc" << "Bloups" << "Grooo";
  liste->setStringList(m_liste_jhj);
}

tarotv::ui::fenetre::~fenetre(){
  delete m_ui;
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
  std::cerr<<"Error while getting config: "<<err.toStdString()<<"\n";
}

void tarotv::ui::fenetre::set_config(config cfg){
  std::cout<<"Gotten config.\n";
  game_config = cfg;
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
  m_ui->bouton_inviter->setEnabled(valider_invitation(nombre_invites));
}
