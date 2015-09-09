// -*- compile-command: "cd ../../ && make -j 5" -*-
#ifndef DOCK_DISCUSSION_DEFINI
#define DOCK_DISCUSSION_DEFINI

#include <QWidget>
#include <QHostAddress>
#include "config.hpp"

namespace Ui{
  class dock_discussion;
};

namespace tarotv{
  namespace ui{
    class dock_discussion: public QWidget{
      Q_OBJECT
    public:
      explicit dock_discussion(QWidget * parent = 0);
      virtual ~dock_discussion();
    public slots:
      void autoriser_discussion(bool);
      void interdire_discussion(bool);
      void message(QString, QString);
      void trop_bavard();
      void nouveau_joueur(QString);
      void depart_joueur(QString);
    private slots:
      void on_bouton_envoyer_clicked();
    signals:
      void message_demande(QString);
    private:
      Ui::dock_discussion * m_ui;
    };
  };
};

#endif
