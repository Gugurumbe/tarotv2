#ifndef Q_VALUE_STREAM_DEFINI
#define Q_VALUE_STREAM_DEFINI

#include <QTcpSocket>

#include "value.hpp"

namespace tarotv{
  namespace client{
    class value_socket: public QTcpSocket{
      Q_OBJECT
    public: value_socket(QObject * parent = 0);
      virtual ~value_socket();
    public slots:
      void send(const tarotv::protocol::value & v);
    private slots:
      void on_readyRead();
      void send_tcpsocket_error();
    signals:
      void value(tarotv::protocol::value);
      void error(QString);
    private:
      class superparser;
      superparser * m_parser;
      void send_value(const tarotv::protocol::value & v);
      void send_error(const QString & err);
      class superparser: public tarotv::protocol::parser{
      public:
	superparser(value_socket * parent):
	  tarotv::protocol::parser(), m_parent(parent){}
	virtual ~superparser(){}
      protected:
	void on_error(const std::string & err){
	  m_parent->send_error(QString::fromStdString(err));
	}
	void on_value(const tarotv::protocol::value & v){
	  m_parent->send_value(v);
	}
      private:
	value_socket * m_parent;
      };
    };
  };
};

#endif
