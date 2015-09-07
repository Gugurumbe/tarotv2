#ifndef Q_REQUESTS_DEFINI
#define Q_REQUESTS_DEFINI

#include "q_value_stream.hpp"
#include "config.hpp"

namespace tarotv{
  namespace client{
    class request: public QObject{
      Q_OBJECT
    public:
      request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, const tarotv::protocol::value & v);
    signals:
      void response(tarotv::protocol::value);
      void error(QString);
    private slots:
      void disconnect_from_socket();
      void send_disconnection_error();
    private: value_socket * sock;
    };
    class tarotv_request: public request{
      Q_OBJECT;
    public:
      tarotv_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString name,
		      std::vector<tarotv::protocol::value> args);
    signals:
      void tarotv_response(tarotv::protocol::value);
      void tarotv_refused(tarotv::protocol::value);
    private slots:
      void get_response(tarotv::protocol::value);
    };
    class config_request: public tarotv_request{
      Q_OBJECT
    public:
      config_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock);
    signals:
      void config_response(tarotv::protocol::config);
    private slots:
      void transform(tarotv::protocol::value);
      void has_refused(tarotv::protocol::value);
    };
  };
};

#endif
