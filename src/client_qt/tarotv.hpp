#ifndef TAROTV_UI_DEFINI

#define TAROTV_UI_DEFINI

#include <QMainWindow>
#include <QStringList>
#include <QHostAddress>

#include "config.hpp"
#include "joueur_hors_jeu.hpp"

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
      void error_while_getting_id(QString);
      void set_config(tarotv::protocol::config cfg);
      void set_id(QString id);
      void auth_refused();
      void on_triggered(action_win_listejoueurs);
      void on_triggered(action_win_discussion);
      void on_triggered(action_win_connexion);
      void on_bouton_changer_serveur_toggled(bool);
      void on_bouton_connexion_clicked();
      void on_bouton_deconnexion_clicked();
      void do_update_model();
    private:
      Ui::main_window * m_ui;
      QStringList m_liste_jhj;
      tarotv::protocol::config game_config;
      QString m_id;
      liste_jhj * m_liste;
    signals:
      void server_ok(bool);
      void auth_ok(bool);
      void message(QString);
      void update_model();
    };
  };
};

#endif
