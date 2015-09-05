#include "q_requests.hpp"
#include <QString>

using namespace tarotv;
using namespace protocol;
using namespace client;
using namespace std;

request::request(QObject * parent):
  QObject(parent){
}

void request::do_request(value_socket * sock, const value & v){
  connections
    << QObject::connect(sock, SIGNAL(value(tarotv::protocol::value)),
			this, SIGNAL(response(tarotv::protocol::value)))
    << QObject::connect(sock, SIGNAL(error(QString)),
			this, SIGNAL(error(QString)))
    << QObject::connect(sock, SIGNAL(disconnected()),
			this, SLOT(send_disconnection_error()))
    << QObject::connect(this, SIGNAL(response(tarotv::protocol::value)),
			this, SLOT(disconnect_from_socket()))
    << QObject::connect(this, SIGNAL(error(QString)),
			this, SLOT(disconnect_from_socket()));
  sock->send(v);
}

void request::disconnect_from_socket(){
  while(!connections.empty()){
     QObject::disconnect(connections.takeFirst());
  }
}

void request::send_disconnection_error(){
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
      emit tarotv_refused(res);
    }
    else{
      QString err = "The server didn't understand a request: " +
	QString::fromStdString(v.print());
      emit error(err);
    }
  }
  else{
    QString err = "The server can't answer the request: " +
      QString::fromStdString(v.print());
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
      emit error(err);
    }
  }
  else{
    QString err = "Cannot parse config response from "
      + QString::fromStdString(v.print()) + ".";
    emit error(err);
  }
}

void config_request::has_refused(tarotv::protocol::value v){
  QString err = "Configuration request has been refused: "
    + QString::fromStdString(v.print());
  emit error(err);
}
