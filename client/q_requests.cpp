#include "q_requests.hpp"
#include <QString>

using namespace tarotv;
using namespace protocol;
using namespace client;
using namespace std;

request::request(QObject * parent):
  QObject(parent), sock(0){
}

void request::do_request(value_socket * sock, const value & v){
  this->sock = sock;
     QObject::connect(sock, SIGNAL(value(tarotv::protocol::value)),
			this, SIGNAL(response(tarotv::protocol::value)));
     QObject::connect(sock, SIGNAL(error(QString)),
			this, SIGNAL(error(QString)));
     QObject::connect(sock, SIGNAL(disconnected()),
			this, SLOT(send_disconnection_error()));
     QObject::connect(this, SIGNAL(response(tarotv::protocol::value)),
			this, SLOT(disconnect_from_socket()));
     QObject::connect(this, SIGNAL(error(QString)),
			this, SLOT(disconnect_from_socket()));
  sock->send(v);
}

void request::disconnect_from_socket(){
  if(sock){
    disconnect(sock, 0, this, 0);
    sock = 0;
  }
}

void request::send_disconnection_error(){
  qDebug()<<"The server closed the connection.";
  emit error("The server closed the connection.");
}

tarotv_request::tarotv_request(QObject * parent):
  request(parent){
  QObject::connect(this, SIGNAL(response(tarotv::protocol::value)),
		   this, SLOT(get_response(tarotv::protocol::value)));
}

void tarotv_request::do_request(value_socket * sock, QString name,
				std::vector<tarotv::protocol::value> args){
  value table(args);
  value v = value::of_labelled(name.toStdString(), table);
  request::do_request(sock, v);
}

void tarotv_request::get_response(value v){
  value res;
  string code;
  if(v.to_labelled(code, res)){
    if(code == "OK"){
      emit tarotv_response(res);
    }
    else if(code == "ERR"){
      qDebug()<<"ERR received : " << QString::fromStdString(v.print());
      emit tarotv_refused(res);
    }
    else{
      QString err = "The server didn't understand a request: " +
	QString::fromStdString(v.print());
      qDebug()<<err;
      emit error(err);
    }
  }
  else{
    QString err = "The server can't answer the request: " +
      QString::fromStdString(v.print());
    qDebug()<<err;
    emit error(err);
  }
}

config_request::config_request(QObject * parent):
  tarotv_request(parent){
  QObject::connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
		   this, SLOT(transform(tarotv::protocol::value)));
  QObject::connect(this, SIGNAL(tarotv_refused(tarotv::protocol::value)),
		   this, SLOT(has_refused(tarotv::protocol::value)));
}

void config_request::do_request(value_socket * sock){
  std::vector<value> args;
  tarotv_request::do_request(sock, "configuration", args);
}

void config_request::transform(tarotv::protocol::value v){
  value c;
  string nom;
  if(v.to_labelled(nom, c) && nom == "config"){
    try{
      config cfg(c);
      emit config_response(cfg);
    }
    catch(invalid_config_structure i){
      QString err = "Cannot parse config response from "
	+ QString::fromStdString(c.print()) + ". "
	+ QString::fromStdString(i.what());
      qDebug()<<err;
      emit error(err);
    }
  }
  else{
    QString err = "Cannot parse config response from "
      + QString::fromStdString(v.print()) + ".";
    qDebug()<<err;
    emit error(err);
  }
}

void config_request::has_refused(tarotv::protocol::value v){
  QString err = "Configuration request has been refused: "
    + QString::fromStdString(v.print());
  emit error(err);
}

id_request::id_request(QObject * parent): tarotv_request(parent){
  connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
	  this, SLOT(id_transform(tarotv::protocol::value)));
  connect(this, SIGNAL(tarotv_refused(tarotv::protocol::value)),
	  this, SLOT(id_refused(tarotv::protocol::value)));
}
void id_request::do_request(value_socket * sock, QString name){
  std::vector<value> args;
  args.push_back(value::of_labelled("nom", value(name.toStdString())));
  tarotv_request::do_request(sock, "identifier", args);
}
void id_request::id_transform(value v){
  value id; string n;
  if(!v.to_labelled(n, id) || id.type() != value::is_string){
    QString err = "Cannot parse id response from "
      + QString::fromStdString(v.print()) + ".";
    qDebug()<<err;
    emit error(err);
  }
  else if(n != "id"){
    QString err = "Cannot parse id response from "
      + QString::fromStdString(v.print()) + ": unexpected argument '"
      + QString::fromStdString(n) + "', expected 'id'.";
    qDebug()<<err;
    emit error(err);    
  }
  else{
    emit id_accepted(QString::fromStdString(id.to_string()));
  }
}
void id_request::id_refused(tarotv::protocol::value){
  emit id_refused();
}

out_request::logout_request(QObject * parent): tarotv_request(parent){
  connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
	  this, SIGNAL(logged_out()));
}
void logout_request::do_request(value_socket * sock, QString id){
  std::vector<value> args;
  args.push_back(value::of_labelled("id", value(id.toStdString())));
  tarotv_request::do_request(sock, "deconnecter", args);
}

peek_request::peek_request(QObject * parent): tarotv_request(parent){
  connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
	  this, SLOT(peek_transform(tarotv::protocol::value)));
  connect(this, SIGNAL(tarotv_refused(tarotv::protocol::value)),
	  this, SLOT(peek_refused(tarotv::protocol::value)));
}
void peek_request::do_request(value_socket * sock, QString id){
  std::vector<value> args;
  args.push_back(value::of_labelled("id", value(id.toStdString())));
  tarotv_request::do_request(sock, "peek_message", args);
}
void peek_request::peek_transform(tarotv::protocol::value v){
  string label; value rep;
  if(!v.to_labelled(label, rep)){
    QString err = "Cannot parse peek response from "
      + QString::fromStdString(v.print()) + ".";
    qDebug()<<err;
    emit error(err);
  }
  else{
    try{
      message msg = get_message(v);
      emit has_message(msg);
    }
    catch(invalid_message_structure i){
      QString err = "Cannot parse peek response from "
	+ QString::fromStdString(v.print()) + ". "
	+ QString::fromStdString(i.what());
      qDebug()<<err;
      emit error(err);
    }
  }
}
void peek_request::peek_refused(tarotv::protocol::value v){
  QString err = "Peek request has been refused: "
    + QString::fromStdString(v.print());
  qDebug()<<err;
  emit error(err);
}

pop_request::pop_request(QObject * parent): tarotv_request(parent){
  connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
	  this, SIGNAL(ok()));
}
void pop_request::do_request(value_socket * sock, QString id){
  std::vector<value> args;
  args.push_back(value::of_labelled("id", value(id.toStdString())));
  tarotv_request::do_request(sock, "next_message", args);
}

msg_request::msg_request(QObject * parent): tarotv_request(parent){
  connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
	  this, SIGNAL(ok()));
  connect(this, SIGNAL(tarotv_refused(tarotv::protocol::value)),
	  this, SIGNAL(too_chatty()));
}
void msg_request::do_request(value_socket * sock, QString id, QString message){
  std::vector<value> args;
  args.push_back(value::of_labelled("id", value(id.toStdString())));
  args.push_back(value::of_labelled("message", value(message.toStdString())));
  tarotv_request::do_request(sock, "dire", args);
}

inv_request::inv_request(QObject * parent): tarotv_request(parent){
  connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
	  this, SIGNAL(ok()));
  connect(this, SIGNAL(tarotv_refused(tarotv::protocol::value)),
	  this, SIGNAL(invalid()));
}
void inv_request::do_request(value_socket * sock, QString id, QStringList invites,
			     QMap<QString, value> parametres){
  std::vector<value> args;
  std::map<std::string, value> p;
  for(QMap<QString, value>::Iterator i = parametres.begin();
      i != parametres.end(); i++){
    p.insert(std::pair<std::string, value>(i.key().toStdString(), i.value()));
  }
  std::vector<value> i;
  for(QStringList::Iterator j = invites.begin(); j != invites.end(); j++){
    i.push_back(value(j->toStdString()));
  }
  args.push_back(value::of_labelled("invites", value(i)));
  args.push_back(value::of_labelled("id", value(id.toStdString())));
  args.push_back(value::of_labelled("parametre", value::of_table(p)));
  tarotv_request::do_request(sock, "inviter", args);
}

cancel_inv_request::cancel_inv_request(QObject * parent): tarotv_request(parent){
  connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
	  this, SIGNAL(ok()));
  connect(this, SIGNAL(tarotv_refused(tarotv::protocol::value)),
	  this, SIGNAL(invalid()));
}
void cancel_inv_request::do_request(value_socket * sock, QString id){
  std::vector<value> args;
  args.push_back(value::of_labelled("id", value(id.toStdString())));
  tarotv_request::do_request(sock, "annuler_invitation", args);
}

msg_bus::msg_bus(const QHostAddress & addr, const QString & id, QObject * parent):
  QObject(parent),
  m_running(false),
  m_addr(addr),
  m_id(id){
}

void msg_bus::run(){
  qDebug()<<"Running the bus.";
  if(!m_running){    
    m_running = true;
    value_socket * sock = new value_socket();
    QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
    sock->connectToHost(m_addr, 45678);
    peek_request * req = new peek_request(sock);

    QObject::connect(req, SIGNAL(has_message(tarotv::protocol::message)),
		     this, SIGNAL(has_message(tarotv::protocol::message)));
    QObject::connect(req, SIGNAL(has_message(tarotv::protocol::message)),
		     this, SLOT(check(tarotv::protocol::message)));
    QObject::connect(req, SIGNAL(error(QString)), this, SLOT(set_idle(QString)));
    
    req->do_request(sock, m_id);
    qDebug()<<"Peek request done.";
  }
}

void msg_bus::check(tarotv::protocol::message message){
  qDebug()<<"Peek response type : " << (int)(message.t);
  if(message.t == tarotv::protocol::is_en_jeu){
    m_running = false;
    emit end();
    qDebug()<<"End of the bus.";
  }
  else {
    qDebug()<<"Should pop.";
    should_pop();
  }
}

void msg_bus::should_pop(){
  qDebug()<<"Requesting pop.";
  if(m_running){
    qDebug()<<"Bus running : ok";
    m_running = false;
    value_socket * sock = new value_socket();
    QObject::connect(sock, SIGNAL(disconnected()), sock, SLOT(deleteLater()));
    sock->connectToHost(m_addr, 45678);
    pop_request * req = new pop_request(sock);

    QObject::connect(req, SIGNAL(response(tarotv::protocol::value)), this, SLOT(run()));
    QObject::connect(req, SIGNAL(error(QString)), this, SLOT(run()));
    // I could care less #xkcd
    
    req->do_request(sock, m_id);
    qDebug()<<"Pop done.";
  }
}

void msg_bus::set_idle(QString why){
  qDebug()<<"Bus idle : "<<why;
  m_running = false;
  if(why == "The remote host closed the connection"){
    qDebug()<<"NP.";
    run();
  }
  else {
    qDebug() << "Bus error.";
    emit error(why);
  }
}

tarotv_game_request::tarotv_game_request(QObject * parent):
  tarotv_request(parent){
  QObject::connect(this, SIGNAL(tarotv_response(tarotv::protocol::value)),
		   this, SLOT(tarotv_accepted(tarotv::protocol::value)));
}

void tarotv_game_request::do_request(value_socket * sock,
				     QString id,
				     QString commande,
				     QStringValueMap q_sous_args){
  std::vector<value> args;
  std::map<std::string, tarotv::protocol::value> sous_args;
  for(QStringValueMap::const_iterator i = q_sous_args.begin();
      i != q_sous_args.end(); i++){
    sous_args.insert
      (std::pair<std::string, tarotv::protocol::value>
       (i.key().toStdString(), i.value()));
  }
  value v = value::of_labelled(commande.toStdString(), value::of_table(sous_args));
  args.push_back(value::of_labelled("id", value(id.toStdString())));
  args.push_back(value::of_labelled("arguments", v));
  tarotv_request::do_request(sock, "jeu", args);
}

void tarotv_game_request::tarotv_accepted(tarotv::protocol::value accepte){
  value res;
  string code;
  if(accepte.to_labelled(code, res)){
    if(code == "OK"){
      emit tarotv_game_response(res);
    }
    else if(code == "ERR"){
      emit tarotv_game_refused(res);
    }
    else{
      QString err = "The game server didn't understand a request: " +
	QString::fromStdString(accepte.print());
      emit error(err);
    }
  }
  else{
    QString err = "The game server can't answer the request: " +
      QString::fromStdString(accepte.print());
    emit error(err);
  }  
}

game_peek_message::game_peek_message(QObject * parent):
  tarotv_game_request(parent){
  QObject::connect(this, SIGNAL(tarotv_game_response(tarotv::protocol::value)),
		   this, SLOT(decrypter(tarotv::protocol::value)));
}

void game_peek_message::do_request(value_socket * sock, QString id){
  tarotv_game_request::do_request(sock, id, "peek_message", QStringValueMap());
}

void game_peek_message::decrypter(value v){
  try{
    message_jeu msg = get_message_jeu(v);
    emit has_message(msg);
  }
  catch(invalid_message_structure i){
    QString err = "Cannot parse peek response from "
      + QString::fromStdString(v.print()) + ". "
      + QString::fromStdString(i.what());
    emit error(err);
  }
}
