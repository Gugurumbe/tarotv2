// -*- compile-command: "cd ../../ && make -j 5" -*-
#ifndef TAROTV_UI_DEFINI

#define TAROTV_UI_DEFINI

#include <QMainWindow>
#include <QStringList>
#include <QHostAddress>

#include "config.hpp"
#include "messages.hpp"
#include "q_requests.hpp"
#include "joueur_hors_jeu.hpp"

#define on_triggered(action) on_##action##_triggered()

typedef QMap<QString, tarotv::protocol::value> QStringValueMap;

namespace Ui{
  class main_window;
};

namespace tarotv{
  namespace ui{
    class fenetre: public QMainWindow{
      Q_OBJECT
    public:
      explicit fenetre(QWidget * parent = 0);
      virtual ~fenetre();
      bool valider_invitation(int nombre_invites) const;
    public slots:
      void ask_server_config(QHostAddress host);
      void login(QString);
      void logout();
      void disconnect_from_sgsj();
      void send_message(QString);
      void inviter(QStringList, QStringValueMap);
      void annuler_invitation();
    private slots:
      void error_while_getting_config(QString);
      void error_while_getting_id(QString);
      void set_config(tarotv::protocol::config cfg);
      void set_id(QString id);
      void auth_refused();
      void do_update_model();
      void has_message(tarotv::protocol::message);
      void run_bus();
      void end_of_bus(QString);
    private:
      Ui::main_window * m_ui;
      QStringList m_liste_jhj;
      tarotv::protocol::config game_config;
      QString m_id;
      QString m_nom;
      liste_jhj * m_liste;
      QHostAddress m_adresse;
      client::msg_bus * m_bus;
    signals:
      void server_ok(bool);
      void auth_ok(bool);
      void mon_nom(QString);
      void message(QString);
      void update_model();
      void nouveau_message(QString, QString);
      void nouveau_joueur(QString);
      void depart_joueur(QString);
      void trop_bavard();
      void invitation_annulee(QString);
      void invitation(QString, QStringList, QStringValueMap);
      void config_recue(tarotv::protocol::config);
    };
  };
};

#endif
