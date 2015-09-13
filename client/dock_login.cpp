#include <climits>
#include "dock_login.hpp"
#include "ui_dock_login.h"

using namespace tarotv::protocol;
using namespace tarotv::ui;
using namespace std;

dock_login::dock_login(QWidget * parent):
  QWidget(parent), m_ui(new Ui::dock_login){
  m_ui->setupUi(this);
}

dock_login::~dock_login(){
  delete m_ui;
}

void dock_login::autoriser_changement(bool accepte){
  m_ui->champ_login->setEnabled(accepte);
}

void dock_login::interdire_changement(bool interdit){
  m_ui->champ_login->setEnabled(!interdit);
}

static void add_string(QTextEdit * edt, QString txt){
  edt->setHtml(edt->toHtml() + txt);
}

#define add_string(str) add_string(m_ui->historique, str)

void dock_login::login_reussi(QString id){
  QString texte = tr("<p><span class=\"goodnews\">Login réussi : ") + id
    + tr("</span>.</p>");
  add_string(texte);
}

void dock_login::echec_login(){
  add_string(tr("<p class=\"erreur\">Ce nom n'est pas disponible.</p>"));
}

void dock_login::erreur(QString err){
  add_string(tr("<p class=\"erreur\">Erreur lors de la tentative de login : ") + err + tr(" .</p>"));
}

void dock_login::on_bouton_login_clicked(){
  m_ui->historique->setText("");
  emit login_demande(m_ui->champ_login->text());
}

void dock_login::on_bouton_logout_clicked(){
  add_string(tr("<p>Logout.</p>"));
  emit logout_demande();
}

void dock_login::est_connecte(bool connecte){
  if(!connecte){
    m_ui->historique->setText("");
  }
  setEnabled(connecte);
}

void dock_login::est_identifie(bool connecte){
  if(connecte){
    m_ui->bouton_login->hide();
    m_ui->bouton_logout->show();
  }
  else{
    m_ui->bouton_login->show();
    m_ui->bouton_logout->hide();
  }
}
