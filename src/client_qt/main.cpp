#include <QApplication>
#include "tarotv.hpp"

int main(int argc, char * argv[]){
  QApplication app(argc, argv);
  tarotv::ui::fenetre f;
  f.show();
  return app.exec();
}
