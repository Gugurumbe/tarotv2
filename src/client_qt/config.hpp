#ifndef CONFIG_DEFINIE

#define CONFIG_DEFINIE

#include <map>
#include <string>
#include <stdexcept>

#include "value.hpp"

namespace tarotv{
  namespace protocol{
    class invalid_config_structure: public std::runtime_error{
    public: invalid_config_structure(const std::string & err):
      std::runtime_error("Invalid server game configuration. " + err){}
    };
    struct config{
      struct int_elt{
	int min;
	int max;
	int incr;
      };
      union u_elt{
	struct int_elt as_int;
	u_elt();
	u_elt(int_elt i);
	u_elt(const u_elt & u);
      };
      enum t_elt{
	is_int
      };
      struct elt{
	enum t_elt t;
	union u_elt u;
	std::string nom;
	elt();
	elt(const std::string & nom, int_elt);
	elt(const elt & e);
	elt(const value & v);
      };
      std::map<std::string, struct elt> elts;
      config();
      config(const config & c);
      config(const value & v);
    };
    inline struct config get_config(const value & v){
      struct config c(v);
      return c;
    }
  };
};

#endif
