#include "vue_jhj.hpp"

using namespace tarotv::ui;

vue_jhj::vue_jhj(QWidget * parent):
  QListView(parent){
}
void vue_jhj::selectionChanged(const QItemSelection &, const QItemSelection &){
  emit selection_changed();
}
