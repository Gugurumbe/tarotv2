#include <climits>
#include "dock_connexion.hpp"
#include "dock_connexion_ui.h"

using namespace tarotv::protocol;
using namespace tarotv::ui;
using namespace std;

dock_connexion::dock_connexion(QWidget * parent):
  QWidget(parent), m_ui(new Ui::dock_connexion){
  m_ui->setupUi(this);
}

dock_connexion::~dock_connexion(){
  delete m_ui;
}

void dock_connexion::autoriser_changement(bool accepte){
  m_ui->champ_adresse->setEnabled(accepte);
}

void dock_connexion::interdire_changement(bool interdit){
  m_ui->champ_adresse->setEnabled(!interdit);
}

static QString presenter_cfg(const pair<string, config::elt> & elt){
  QString intitule = QObject::tr("Attribut <span class=\"attr\">") + QString::fromStdString(elt.second.nom)
    + QObject::tr("</span> <span class=\"shortattr\">(")
    + QString::fromStdString(elt.first) + QObject::tr(")</span> : type <span class=\"type\">");
  switch(elt.second.t){
  case config::is_int:
    intitule += QObject::tr("int</span>");
    if(elt.second.u.as_int.min > INT_MIN){
      intitule += QObject::tr(", minimum <span class=\"min\">")
	+ QString::number(elt.second.u.as_int.min)
	+ QObject::tr("</span>");
    }
    if(elt.second.u.as_int.max < INT_MAX){
      intitule += QObject::tr(", maximum <span class=\"max\">")
	+ QString::number(elt.second.u.as_int.max)
	+ QObject::tr("</span>");
    }
    if(elt.second.u.as_int.incr > 1){
      intitule += QObject::tr(", <span class=\"incr\">")
	+ QString::number(elt.second.u.as_int.incr)
	+ QObject::tr(" par ")
	+ QString::number(elt.second.u.as_int.incr)
	+ QObject::tr("</span>");
    }
    intitule +=".";
    break;
  default:
    intitule += QObject::tr("inconnu</span>.");
  }
  return intitule;
}

static void add_string(QTextEdit * edt, QString txt){
  edt->setHtml(edt->toHtml() + txt);
}

#define add_string(str) add_string(m_ui->historique, str)

void dock_connexion::connexion_reussie(tarotv::protocol::config cfg){
  QString texte = tr("<p><span class=\"goodnews\">Connexion réussie.")
    + tr("</span> La configuration du serveur est la suivante :<ul>");
  for(map<string, config::elt>::const_iterator i = cfg.elts.begin(); i != cfg.elts.end(); i++){
    texte += tr("<li>") + presenter_cfg(*i) + tr("</li>");
  }
  texte += "</ul></p>";
  add_string(texte);
}

void dock_connexion::echec_connexion(QString err){
  add_string(tr("<p class=\"erreur\">Erreur pour ce serveur: ") + err + tr("</p>"));
}

void dock_connexion::on_bouton_connexion_clicked(){
  m_ui->historique->setText("");
  emit connexion_demandee(QHostAddress(m_ui->champ_adresse->text()));
}

void dock_connexion::on_bouton_deconnexion_clicked(){
  add_string(tr("<p>Déconnexion.</p>"));
  emit deconnexion_demandee();
}

void dock_connexion::est_connecte(bool connecte){
  if(connecte){
    m_ui->bouton_connexion->hide();
    m_ui->bouton_deconnexion->show();
  }
  else{
    m_ui->bouton_connexion->show();
    m_ui->bouton_deconnexion->hide();
  }
}
