#include <QApplication>
#include "tarotv.hpp"

int main(int argc, char * argv[]){
  QApplication app(argc, argv);
  tarotv::ui::fenetre f;
  f.show();
  f.ask_server_config(QHostAddress("127.0.0.1"), 45678);
  return app.exec();
}
