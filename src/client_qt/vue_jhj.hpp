#ifndef VUE_JHJ_DEFINIE
#define VUE_JHJ_DEFINIE

#include <QListView>

namespace tarotv{
  namespace ui{
    class vue_jhj: public QListView{
      Q_OBJECT
    public:
      vue_jhj(QWidget * parent);
    signals:
      void selection_changed();
    protected:
      virtual void selectionChanged(const QItemSelection &, const QItemSelection &);
    };
  };
};

#endif
