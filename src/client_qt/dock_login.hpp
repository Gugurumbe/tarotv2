// -*- compile-command: "cd ../../ && make -j 5" -*-
#ifndef DOCK_LOGIN_DEFINI
#define DOCK_LOGIN_DEFINI

#include <QWidget>
#include <QHostAddress>
#include "config.hpp"

namespace Ui{
  class dock_login;
};

namespace tarotv{
  namespace ui{
    class dock_login: public QWidget{
      Q_OBJECT
    public:
      explicit dock_login(QWidget * parent = 0);
      virtual ~dock_login();
    public slots:
      void autoriser_changement(bool);
      void interdire_changement(bool);
      void est_connecte(bool);
      void est_identifie(bool);
      void login_reussi(QString);
      void echec_login();
      void erreur(QString);
    private slots:
      void on_bouton_login_clicked();
      void on_bouton_logout_clicked();
    signals:
      void login_demande(QString);
      void logout_demande();
    private:
      Ui::dock_login * m_ui;
    };
  };
};

#endif
