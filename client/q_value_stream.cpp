#include "q_value_stream.hpp"

using namespace tarotv;
using namespace client;
using namespace protocol;
using namespace std;

value_socket::value_socket(QObject * parent):
  QTcpSocket(parent), m_parser(new superparser(this)){
  QObject::connect(this, SIGNAL(readyRead()), this, SLOT(on_readyRead()));
  QObject::connect(this, SIGNAL(error(QAbstractSocket::SocketError)),
		   this, SLOT(send_tcpsocket_error()));
  connect(this, SIGNAL(connected()), this, SLOT(on_connected()));
}

value_socket::~value_socket(){
  delete m_parser;
}

void value_socket::on_connected(){
  write(m_queue);
  m_queue.clear();
}

void value_socket::send(const tarotv::protocol::value & v){
  std::string representation = v.print();
  QByteArray paquet(QString::fromStdString(representation).toUtf8());
  if(state() == QAbstractSocket::ConnectedState){
    write(paquet);
  }
  else m_queue.append(paquet);
}

void value_socket::on_readyRead(){
  char c;
  while(read(&c, 1) == 1){
    m_parser->read(c);
  }
}

void value_socket::send_value(const tarotv::protocol::value & v){
  emit value(v);
}

void value_socket::send_error(const QString & err){
  emit error(err);
}

void value_socket::send_tcpsocket_error(){
  emit error(errorString());
}
