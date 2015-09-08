#ifndef DOCK_CONNEXION_DEFINI
#define DOCK_CONNEXION_DEFINI

#include <QWidget>
#include <QHostAddress>
#include "config.hpp"

namespace Ui{
  class dock_connexion;
};

namespace tarotv{
  namespace ui{
    class dock_connexion: public QWidget{
      Q_OBJECT
    public:
      explicit dock_connexion(QWidget * parent = 0);
      virtual ~dock_connexion();
    public slots:
      void autoriser_changement(bool);
      void interdire_changement(bool);
      void est_connecte(bool);
      void connexion_reussie(tarotv::protocol::config);
      void echec_connexion(QString);
    private slots:
      void on_bouton_connexion_clicked();
      void on_bouton_deconnexion_clicked();
    signals:
      void connexion_demandee(QHostAddress);
      void deconnexion_demandee();
    private:
      Ui::dock_connexion * m_ui;
    };
  };
};

#endif
