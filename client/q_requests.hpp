#ifndef Q_REQUESTS_DEFINI
#define Q_REQUESTS_DEFINI

#include "q_value_stream.hpp"
#include "config.hpp"
#include "messages.hpp"
#include <QStringList>
#include <QHostAddress>

typedef QMap<QString, tarotv::protocol::value> QStringValueMap;

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
    class id_request: public tarotv_request{
      Q_OBJECT
    public:
      id_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString name);
    signals:
      void id_accepted(QString);
      void id_refused();
    private slots:
      void id_transform(tarotv::protocol::value);
      void id_refused(tarotv::protocol::value);
    };
    class logout_request: public tarotv_request{
      Q_OBJECT
    public:
      logout_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id);
    signals:
      void logged_out();
    };
    class peek_request: public tarotv_request{
      Q_OBJECT
    public:
      peek_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id);
    private slots:
      void peek_transform(tarotv::protocol::value);
      void peek_refused(tarotv::protocol::value);
    signals:
      void has_message(tarotv::protocol::message);
    };
    class pop_request: public tarotv_request{
      Q_OBJECT
    public:
      pop_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id);
    signals:
      void ok();
    };
    class msg_request: public tarotv_request{
      Q_OBJECT
    public:
      msg_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id, QString message);
    signals:
      void ok();
      void too_chatty();
    };
    class inv_request: public tarotv_request{
      Q_OBJECT
    public:
      inv_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id, QStringList invites,
		      QMap<QString, tarotv::protocol::value> parametres);
    signals:
      void ok();
      void invalid();
    };
    class cancel_inv_request: public tarotv_request{
      Q_OBJECT
    public:
      cancel_inv_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id);
    signals:
      void ok();
      void invalid();
    };
    class msg_bus: public QObject{
      Q_OBJECT
    public:
      msg_bus(const QHostAddress & add, const QString & id, QObject * parent = 0);
    public slots:
      void run();
    signals:
      void has_message(tarotv::protocol::message);
      void end();
      void error(QString err);
    private slots:
      void should_pop();
      void set_idle(QString);
      void check(tarotv::protocol::message);
    private: bool m_running; const QHostAddress m_addr; const QString m_id;
    };
    class tarotv_game_request: public tarotv_request{
      Q_OBJECT
    public:
      tarotv_game_request(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id,
		      QString commande, QStringValueMap args);
    signals:
      void tarotv_game_response(tarotv::protocol::value);
      void tarotv_game_refused(tarotv::protocol::value);
    private slots:
      void tarotv_accepted(tarotv::protocol::value);
    };
    class game_peek_message: public tarotv_game_request{
      Q_OBJECT
    public:
      game_peek_message(QObject * parent = 0);
    public slots:
      void do_request(value_socket * sock, QString id);
    signals:
      void has_message(tarotv::protocol::message_jeu);
    private slots:
      void decrypter(tarotv::protocol::value);
    };
  };
};

#endif
