#ifndef JOUEUR_HORS_JEU_DEFINI

#define JOUEUR_HORS_JEU_DEFINI

#include <QStringListModel>

namespace tarotv{
  namespace ui{
    class liste_jhj: public QStringListModel{
      Q_OBJECT;
    public:
      explicit liste_jhj(QObject * parent = 0);
    };
  };
};

#endif
