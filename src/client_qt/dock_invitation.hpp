// -*- compile-command: "cd ../../ && make -j 5" -*-
#ifndef DOCK_INVITATION_DEFINI

#define DOCK_INVITATION_DEFINI

#include <QWidget>
#include "config.hpp"
#include "tarotv.hpp" // pour le QStringValueMap
#include <QStringList>
#include <QFormLayout>
#include <QSpinBox>

namespace Ui{
  class dock_invitation;
};

namespace tarotv{
  namespace ui{
    class incr_spinbox: public QSpinBox{
      Q_OBJECT
    public:
      explicit incr_spinbox(QWidget * parent = 0);
      void start(int value, int step);
      int value() const;
    private slots:
      void value_changed(int);
    private:
      int m_lastok;
      int m_step;
    };
    class form_widget: public QWidget{
      Q_OBJECT
    public:
      explicit form_widget(QWidget * parent = 0);
      QStringValueMap contents() const;
    public slots:
      void set_types(tarotv::protocol::config);
      void set_values(QStringValueMap);
    private:
      QFormLayout * m_layout;
      QMap<QString, QWidget *> m_widgets;
    };
    class string_list_model: public QStringListModel{
      Q_OBJECT
    public:
      explicit string_list_model(QObject * parent = 0);
      explicit string_list_model(const QStringList & strings, QObject * parent = 0);
      void set_string_list(const QStringList * m_sl);
      void set_invit_list(const QMap<QString, QPair<QStringList, QStringValueMap> > * m_sl);
    public slots:
      void maj();
    private:
      const QStringList * m_sl;
      const QMap<QString, QPair<QStringList, QStringValueMap> > * m_m;
    };
    class dock_invitation: public QWidget{
      Q_OBJECT
    public:
      explicit dock_invitation(QWidget * parent = 0);
      virtual ~dock_invitation();
    public slots:
      void set_config(tarotv::protocol::config);
      void autoriser_invitation(bool);
      void interdire_invitation(bool);
      void nouveau_joueur(QString);
      void depart_joueur(QString);
      void moi(QString);
      void nouvelle_invitation(QString, QStringList, QStringValueMap);
      void invitation_annulee(QString);
    private slots:
      void on_choix_invitation_activated(const QModelIndex &);
      void on_liste_invites_indexesMoved(const QModelIndexList &);
      void on_liste_invites_activated(const QModelIndex &);
      void on_bouton_enlever_clicked();
      void on_bouton_monter_clicked();
      void on_bouton_descendre_clicked();
      void on_choix_joueurs_editTextChanged(QString);
      void on_bouton_ajouter_clicked();
      void on_bouton_inviter_clicked();
      void on_bouton_annuler_clicked();
      void check();
    signals:
      void demander_invitation(QStringList, QStringValueMap);
      void demander_annulation();
      void joueurs_maj();
    private:
      QMap<QString, QPair<QStringList, QStringValueMap> > m_invitations;
      QStringList m_joueurs;
      QString m_moi;
      QStringList m_mes_invites;
      QStringValueMap m_mes_parametres;
      Ui::dock_invitation * m_ui;
      tarotv::protocol::config m_cfg;
      string_list_model * m_modele_invitations;
      string_list_model * m_modele_invites;
      string_list_model * m_modele_joueurs;
    };
  };
};

#endif
