#include <climits>
#include "config.hpp"

using namespace tarotv::protocol;
using namespace std;

config::u_elt::u_elt(){
  as_int.min = INT_MIN;
  as_int.max = INT_MAX;
  as_int.incr = 1;
}
config::u_elt::u_elt(config::int_elt i){
  as_int.min = i.min;
  as_int.max = i.max;
  as_int.incr = i.incr;
}
config::u_elt::u_elt(const u_elt & u){
  as_int.min = u.as_int.min;
  as_int.max = u.as_int.max;
  as_int.incr = u.as_int.incr;
}
config::elt::elt():
  t(is_int), u(), nom(""){
}
config::elt::elt(const string & arg_nom, int_elt i):
  t(is_int), u(i), nom(arg_nom){
}
config::elt::elt(const elt & e):
  t(e.t), u(e.u), nom(e.nom){
}
config::elt::elt(const value & v):
  u(){
  map<string, value> conf;
  if(v.to_table(conf)){
    map<string, value>::iterator i_t, i_n, i_min, i_max, i_incr;
    i_t = conf.find("type");
    i_n = conf.find("name");
    i_min = conf.find("min");
    i_max = conf.find("max");
    i_incr = conf.find("incr");
    if(i_t != conf.end() && i_n != conf.end()
       && i_t->second.type() == value::is_string
       && i_n->second.type() == value::is_string){
      if(i_t->second.to_string() == "int"){
	nom = i_n->second.to_string();
	t = is_int;
	if(i_min != conf.end()){
	  if(!i_min->second.to_int(u.as_int.min)){
	    throw invalid_config_structure("Could not convert min to int.");
	  }
	}
	if(i_max != conf.end()){
	  if(!i_max->second.to_int(u.as_int.max)){
	    throw invalid_config_structure("Could not convert max to int.");
	  }
	}
	if(i_incr != conf.end()){
	  if(!i_incr->second.to_int(u.as_int.incr)){
	    throw invalid_config_structure("Could not convert incr to int.");
	  }
	}	
      }
      else throw invalid_config_structure("Bad config option type. It must be int.");
    }
    else{
      if(i_t == conf.end()){
	throw invalid_config_structure("Missing \"type\" field.");
      }
      else if(i_n == conf.end()){
	throw invalid_config_structure("Missing \"name\" field.");
      }
      else if(i_t->second.type() == value::is_string){
	throw invalid_config_structure("Malformed \"name\" field.");
      }
      else throw invalid_config_structure("Malformed \"type\" field.");
    }
  }
  else throw invalid_config_structure("Bad config option. Not a table.");
}
config::config():
  elts(){
}
config::config(const config & c):
  elts(c.elts){
}
config::config(const value & v){
  map<string, value> table;
  if(!v.to_table(table)){
    throw invalid_config_structure("Not a table.");
  }
  for(map<string, value>::iterator i = table.begin();
      i != table.end(); i++){
    config::elt e(i->second);
    elts.insert(pair<string, config::elt>(i->first, e));
  }
}
