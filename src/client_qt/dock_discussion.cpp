// -*- compile-command: "cd ../../ && make -j 5" -*-
#include "dock_discussion.hpp"
#include "dock_discussion_ui.h"

using namespace tarotv::protocol;
using namespace tarotv::ui;
using namespace std;

dock_discussion::dock_discussion(QWidget * parent):
  QWidget(parent), m_ui(new Ui::dock_discussion){
  m_ui->setupUi(this);
}

dock_discussion::~dock_discussion(){
  delete m_ui;
}

void dock_discussion::autoriser_discussion(bool accepte){
  m_ui->historique->setText("");
  setEnabled(accepte);
}

void dock_discussion::interdire_discussion(bool interdit){
  setEnabled(!interdit);
}

static void add_string(QTextEdit * edt, QString txt){
  edt->setHtml(edt->toHtml() + txt);
}

#define add_string(str) add_string(m_ui->historique, str)

void dock_discussion::message(QString nom, QString message){
  QString texte = tr("<p><span class=\"player\">") + nom.toHtmlEscaped() + tr("</span> : ")
    + message.toHtmlEscaped() + tr("</p>");
  add_string(texte);
}

void dock_discussion::trop_bavard(){
  add_string(tr("<p class=\"erreur\">Vous parlez trop. Attendez quelques temps avant de reparler (au pire 10 minutes).</p>"));
}

void dock_discussion::nouveau_joueur(QString nom){
  add_string(tr("<p class=\"nouveau\">Nouveau joueur : ")
	     + nom.toHtmlEscaped() + tr("</p>"));
}

void dock_discussion::depart_joueur(QString nom){
  add_string(tr("<p class=\"depart\">Départ du joueur : ")
	     + nom.toHtmlEscaped() + tr("</p>"));
}

void dock_discussion::on_bouton_envoyer_clicked(){
  if(m_ui->champ_discussion->text() != ""){
    emit message_demande(m_ui->champ_discussion->text());
    m_ui->champ_discussion->setText("");
  }
}
