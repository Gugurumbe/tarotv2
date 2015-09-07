#ifndef TAROTV_UI_DEFINI

#define TAROTV_UI_DEFINI

#include <QMainWindow>
#include <QStringList>
#include <QHostAddress>

#include "config.hpp"

#define on_triggered(action) on_##action##_triggered()

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
      void ask_server_config(QHostAddress host, quint16 port);
      void on_liste_jhj_selection_changed();
    private slots:
      void error_while_getting_config(QString);
      void set_config(tarotv::protocol::config cfg);
      void on_triggered(action_win_listejoueurs);
      void on_triggered(action_win_discussion);
      void on_triggered(action_win_connexion);
    private:
      Ui::main_window * m_ui;
      QStringList m_liste_jhj;
      tarotv::protocol::config game_config;
    signals:
      void auth_ok(bool);      
    };
  };
};

#endif
