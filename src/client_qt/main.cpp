// -*- compile-command: "cd ../../ && make -j 5" -*-
#include <QApplication>
#include "tarotv.hpp"
//#include "dock_invitation.hpp"

int main(int argc, char * argv[]){
  QApplication app(argc, argv);
  tarotv::ui::fenetre f;
  f.show();
  // tarotv::ui::dock_invitation f;
  // f.show();
  // tarotv::protocol::config cfg;
  // tarotv::protocol::config::int_elt nplayers, nlevees;
  // nplayers.min = 5;
  // nplayers.max = 5;
  // nlevees.min = 1;
  // nlevees.max = 24;
  // nlevees.incr = 5;
  // cfg.elts.insert(std::pair<std::string, tarotv::protocol::config::elt>("nplayers", tarotv::protocol::config::elt("Nombre de joueurs", nplayers)));
  // cfg.elts.insert(std::pair<std::string, tarotv::protocol::config::elt>("nlevees", tarotv::protocol::config::elt("Nombre de levées", nlevees)));
  // f.set_config(tarotv::protocol::config(cfg));
  // f.autoriser_invitation(true);
  // f.nouveau_joueur("A");
  // f.nouveau_joueur("B");
  // f.nouveau_joueur("C");
  // f.moi("Moi");
  // f.nouveau_joueur("D");
  // QMap<QString, tarotv::protocol::value> invitation;
  // invitation.insert("nlevees", tarotv::protocol::value::of_int(6));
  // f.nouvelle_invitation("A", QStringList() << "A" << "B" << "C" << "D" << "Moi", invitation);
  // f.invitation_annulee("A");
  // f.nouvelle_invitation("Moi", QStringList() << "A" << "B" << "C" << "D" << "Moi", invitation);
  return app.exec();
}
