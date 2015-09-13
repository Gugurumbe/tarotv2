#include "dock_invitation.hpp"
#include "ui_dock_invitation.h"

using namespace tarotv::protocol;
using namespace tarotv::client;
using namespace tarotv::ui;

incr_spinbox::incr_spinbox(QWidget * parent):
  QSpinBox(parent), m_lastok(0), m_step(1){
  connect(this, SIGNAL(valueChanged(int)), this, SLOT(value_changed(int)));
}

void incr_spinbox::start(int value, int step){
  m_lastok = value;
  m_step = step;
  setValue(value);
  setSingleStep(step);
}

void incr_spinbox::value_changed(int v){
  if((v - m_lastok) % m_step == 0){
    m_lastok = v;
  }
}

int incr_spinbox::value() const{
  return m_lastok;
}

form_widget::form_widget(QWidget * parent): QWidget(parent), m_layout(new QFormLayout(this)){
}

QStringValueMap form_widget::contents() const{
  QStringValueMap ret;
  for(QMap<QString, QWidget *>::const_iterator i = m_widgets.begin();
      i != m_widgets.end(); i++){
    const QWidget * raw = i.value();
    const QSpinBox * as_int = qobject_cast<const QSpinBox *>(raw);
    if(as_int){
      ret.insert(i.key(), value::of_int(as_int->value()));
    }
  }
  return ret;
}

void form_widget::set_types(tarotv::protocol::config cfg){
  for(QMap<QString, QWidget *>::const_iterator i = m_widgets.begin();
      i != m_widgets.end(); i++){
    m_layout->removeWidget(i.value());
    i.value()->deleteLater();
  }
  for(std::map<std::string, config::elt>::const_iterator i = cfg.elts.begin();
      i != cfg.elts.end(); i++){
    if(i->first != "nplayers"){
      incr_spinbox * sb = 0;
      switch(i->second.t){
      case config::is_int:
	sb = new incr_spinbox;
	sb->start(i->second.u.as_int.min, i->second.u.as_int.incr);
	sb->setMinimum(i->second.u.as_int.min);
	sb->setMaximum(i->second.u.as_int.max);
      m_layout->addRow(QString::fromStdString(i->second.nom), sb);
      m_widgets.insert(QString::fromStdString(i->first), sb);
      break;
      }
    }
  }
}

void form_widget::set_values(QMap<QString, value> values){
  for(QMap<QString, QWidget *>::const_iterator i = m_widgets.begin();
      i != m_widgets.end(); i++){
    QSpinBox * as_int = qobject_cast<QSpinBox *>(i.value());
    if(as_int){
      QMap<QString, value>::const_iterator j = values.find(i.key());
      if(j != values.end() && j.value().type() == value::is_string){
	as_int->setValue(QString::fromStdString(j.value().to_string()).toInt());
      }
    }
  }
}

string_list_model::string_list_model(QObject * parent):
  QStringListModel(parent), m_sl(0), m_m(0){
}

string_list_model::string_list_model(const QStringList & strings, QObject * parent):
  QStringListModel(strings, parent), m_sl(0), m_m(0){
}

void string_list_model::set_string_list(const QStringList * sl){
  m_sl = sl;
}

void string_list_model::set_invit_list(const QMap<QString, QPair<QStringList, QStringValueMap> > * m){
  m_m = m;
}

void string_list_model::maj(){
  if(m_sl){
    setStringList(*m_sl);
  }
  else if(m_m){
    QStringList items;
    for(QMap<QString, QPair<QStringList, QStringValueMap> >::const_iterator i = m_m->begin();
	i != m_m->end(); i++){
      items << tr("Invitation de ") + i.key();
    }
    setStringList(items);
  }
}

dock_invitation::dock_invitation(QWidget * parent):
  QWidget(parent),
  m_ui(new Ui::dock_invitation),
  m_modele_invitations(new string_list_model(this)),
  m_modele_invites(new string_list_model(this)),
  m_modele_joueurs(new string_list_model(this)){
  m_modele_invitations->set_invit_list(&m_invitations);
  m_modele_invites->set_string_list(&m_mes_invites);
  m_modele_joueurs->set_string_list(&m_joueurs);
  m_ui->setupUi(this);
  m_ui->choix_invitation->setModel(m_modele_invitations);
  m_ui->liste_invites->setModel(m_modele_invites);
  m_ui->choix_joueurs->setModel(m_modele_joueurs);
  m_ui->bouton_annuler->hide();
  m_ui->bouton_inviter->setEnabled(false);
  QObject::connect(this, SIGNAL(joueurs_maj()), m_modele_invitations, SLOT(maj()));
  QObject::connect(this, SIGNAL(joueurs_maj()), m_modele_invites, SLOT(maj()));
  QObject::connect(this, SIGNAL(joueurs_maj()), m_modele_joueurs, SLOT(maj()));
  emit joueurs_maj();
  m_ui->bouton_ajouter->setEnabled(false);
  check();
}

dock_invitation::~dock_invitation(){
  delete m_ui;
}

void dock_invitation::set_config(config cfg){
  m_cfg = cfg;
  m_ui->formulaire->set_types(cfg);
}

void dock_invitation::autoriser_invitation(bool ok){
  setEnabled(ok);
}

void dock_invitation::interdire_invitation(bool ok){
  autoriser_invitation(!ok);
}

void dock_invitation::nouveau_joueur(QString nouveau){
  if(!m_joueurs.contains(nouveau) && m_moi != nouveau){
    m_joueurs.append(nouveau);
    m_joueurs.sort();
    emit joueurs_maj();
  }
  check();
}

void dock_invitation::depart_joueur(QString joueur){
  if(m_joueurs.contains(joueur)){
    m_joueurs.removeAll(joueur);
    emit joueurs_maj();
  }
  if(m_mes_invites.contains(joueur)){
    m_mes_invites.removeAll(joueur);
    emit joueurs_maj();
  }
  if(m_invitations.contains(joueur)){
    m_invitations.remove(joueur);
    emit joueurs_maj();
  }
  check();
}

void dock_invitation::moi(QString superchampion){
  if(!m_mes_invites.contains(superchampion)){
    m_mes_invites << superchampion;
  }
  m_moi = superchampion;
  emit joueurs_maj();
  check();
}

void dock_invitation::nouvelle_invitation(QString joueur, QStringList invites, QStringValueMap parametres){
  m_invitations.remove(joueur);
  m_invitations.insert(joueur, QPair<QStringList, QStringValueMap>(invites, parametres));
  emit joueurs_maj();
  check();
}

void dock_invitation::invitation_annulee(QString joueur){
  if(m_invitations.contains(joueur)){
    m_invitations.remove(joueur);
    emit joueurs_maj();
  }
  check();
}

void dock_invitation::on_choix_invitation_activated(const QModelIndex & numero){
  QMap<QString, QPair<QStringList, QStringValueMap> >::iterator i = m_invitations.begin() + numero.row();
  m_ui->formulaire->set_values(i.value().second);
  m_mes_invites = i.value().first;
  for(int i = 0; i < m_joueurs.size(); i++){
    if(m_mes_invites.contains(m_joueurs[i])){
      m_joueurs.removeAt(i);
      i--;
    }
  }
  emit joueurs_maj();
  check();
}

void dock_invitation::on_liste_invites_indexesMoved(const QModelIndexList &){
  QStringList nouveau_modele = m_modele_invites->stringList();
  m_mes_invites = nouveau_modele;
  emit joueurs_maj();
  int i = m_ui->liste_invites->currentIndex().row();
  m_ui->bouton_enlever->setEnabled(i >= 0 && i < m_mes_invites.size() && m_mes_invites[i] != m_moi);
  check();
}

void dock_invitation::on_liste_invites_activated(const QModelIndex & index){
  int i = index.row();
  m_ui->bouton_enlever->setEnabled(i >= 0 && i < m_mes_invites.size() && m_mes_invites[i] != m_moi);
  check();
}

void dock_invitation::on_bouton_enlever_clicked(){
  int i = m_ui->liste_invites->currentIndex().row();
  bool ok = i >= 0 && i < m_mes_invites.size() && m_mes_invites[i] != m_moi;
  if(ok){
    m_joueurs << m_mes_invites[i];
    m_joueurs.sort();
    m_mes_invites.removeAt(i);
    emit joueurs_maj();
  }
  m_ui->bouton_enlever->setEnabled(ok);
  check();
}

void dock_invitation::on_bouton_monter_clicked(){
  int i = m_ui->liste_invites->currentIndex().row();
  bool ok = i >= 1 && i < m_mes_invites.size() && m_mes_invites[i] != m_moi;
  if(ok){
    QString tmp = m_mes_invites[i - 1];
    m_mes_invites[i - 1] = m_mes_invites[i];
    m_mes_invites[i] = tmp;
    emit joueurs_maj();
    m_ui->bouton_enlever->setEnabled(m_mes_invites[i - 1] != m_moi);
  }
  check();
}

void dock_invitation::on_bouton_descendre_clicked(){
  int i = m_ui->liste_invites->currentIndex().row();
  bool ok = i >= 0 && i < m_mes_invites.size() - 1 && m_mes_invites[i] != m_moi;
  if(ok){
    QString tmp = m_mes_invites[i];
    m_mes_invites[i] = m_mes_invites[i + 1];
    m_mes_invites[i + 1] = tmp;
    emit joueurs_maj();
    m_ui->bouton_enlever->setEnabled(m_mes_invites[i + 1] != m_moi);
  }
  check();
}

void dock_invitation::on_choix_joueurs_editTextChanged(QString joueur){
  m_ui->bouton_ajouter->setEnabled(m_joueurs.contains(joueur));
  check();
}

void dock_invitation::on_bouton_ajouter_clicked(){
  QString j = m_ui->choix_joueurs->currentText();
  for(int i = 0; i < m_joueurs.size(); i++){
    if(m_joueurs[i] == j){
      m_joueurs.removeAt(i);
      m_mes_invites << j;
      i = m_joueurs.size();
      emit joueurs_maj();
    }
  }
  check();
}

void dock_invitation::on_bouton_inviter_clicked(){
  emit demander_invitation(m_mes_invites, m_ui->formulaire->contents());
  m_ui->choix_invitation->setEnabled(false);
  m_ui->liste_invites->setEnabled(false);
  m_ui->bouton_enlever->setEnabled(false);
  m_ui->bouton_monter->setEnabled(false);
  m_ui->bouton_descendre->setEnabled(false);
  m_ui->bouton_ajouter->setEnabled(false);
  m_ui->choix_joueurs->setEnabled(false);
  m_ui->formulaire->setEnabled(false);
  m_ui->bouton_inviter->hide();
  m_ui->bouton_annuler->show();
}

void dock_invitation::on_bouton_annuler_clicked(){
  emit demander_annulation();
  m_ui->choix_invitation->setEnabled(true);
  m_ui->liste_invites->setEnabled(true);
  m_ui->bouton_enlever->setEnabled(true);
  m_ui->bouton_monter->setEnabled(true);
  m_ui->bouton_descendre->setEnabled(true);
  m_ui->bouton_ajouter->setEnabled(true);
  m_ui->choix_joueurs->setEnabled(true);
  m_ui->formulaire->setEnabled(true);
  m_ui->bouton_inviter->show();
  m_ui->bouton_annuler->hide();  
}

void dock_invitation::check(){
  std::map<std::string, config::elt>::const_iterator i;
  const config & cfg = m_cfg;
  i = cfg.elts.find("nplayers");
  int nombre_invites = m_mes_invites.size();
  bool ok =
    i != cfg.elts.end()
    &&(i->second.t == config::is_int
       && nombre_invites >= i->second.u.as_int.min
       && nombre_invites <= i->second.u.as_int.max
       && ((nombre_invites - i->second.u.as_int.min)
	   % i->second.u.as_int.incr == 0));
  m_ui->bouton_inviter->setEnabled(ok);
}
