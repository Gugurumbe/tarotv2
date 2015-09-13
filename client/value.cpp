#include "value.hpp"
#include <iomanip>
#include <cstdlib>

using namespace std;
using namespace tarotv::protocol;

value::value():
  m_list(), m_string(""), m_type(is_list){
}
value::value(const string & str):
  m_list(), m_string(str), m_type(is_string){
}
value::value(const vector<value> & content):
  m_list(content), m_string(""), m_type(is_list){
}
value::value(const value & v):
  m_list(v.m_list), m_string(v.m_string), m_type(v.m_type){
}
value & value::operator=(const value & s){
  m_list = s.m_list;
  m_string = s.m_string;
  m_type = s.m_type;
  return *this;
}
value & value::operator=(const string & str){
  m_list.clear();
  m_string = str;
  m_type = is_string;
  return *this;
}
value & value::operator=(const vector<value> & lst){
  m_list = lst;
  m_string = "";
  m_type = is_list;
  return *this;
}
const vector<value> & value::to_list() const{
  return m_list;
}
const string & value::to_string() const{
  return m_string;
}
bool value::to_labelled(string & label, value & v) const{
  bool ok = false;
  if(m_type == is_list && m_list.size() == 2
     && m_list[0].m_type == is_string){
    label = m_list[0].to_string();
    v = m_list[1];
    ok = true;
  }
  return ok;
}
bool value::to_int(int & i) const{
  bool ok = false;
  if(m_type == is_string){
    const char * src = m_string.c_str();
    char * reste = NULL;
    int resultat = strtol(src, &reste, 0);
    if(reste - src == static_cast<int>(m_string.size())){
      i = resultat;
      ok = true;
    }
  }
  return ok;
}
bool value::to_float(double & d) const{
  bool ok = false;
  if(m_type == is_string){
    const char * src = m_string.c_str();
    char * reste = NULL;
    double resultat = strtod(src, &reste);
    if(reste - src == static_cast<int>(m_string.size())){
      d = resultat;
      ok = true;
    }
  }
  return ok;
}
bool value::to_table(map<string, value> & table) const{
  bool ok = false;
  std::string cle;
  value val;
  vector<value>::const_iterator i;
  if(m_type == is_list){
    for(i = m_list.begin();
	i != m_list.end() && i->to_labelled(cle, val); i++){
      table.insert(pair<string, value>(cle, val));
    }
    ok = i == m_list.end();
  }
  return ok;
}
bool value::to_bool(bool & b) const{
  if(m_type == is_string){
    if(m_string == "true" || m_string == "false")
      b = m_string == "true";
  }
  return m_type == is_string
    && (m_string == "true" || m_string == "false");
}
value value::of_labelled(const std::string & n, const value & v){
  std::vector<value> pair;
  pair.push_back(value(n));
  pair.push_back(v);
  return value(pair);
}
value value::of_int(int i){
  std::stringstream ss;
  ss<<i;
  return value(ss.str());
}
value value::of_float(double f){
  std::stringstream ss;
  ss<<f;
  return value(ss.str());
}
value value::of_table(const map<string, value> & table){
  std::vector<value> elements;
  elements.reserve(table.size());
  for(map<string, value>::const_iterator i = table.begin();
      i != table.end(); i++){
    elements.push_back(of_labelled(i->first, i->second));
  }
  return value(elements);
}
value value::of_bool(bool b){
  return value(b ? "true" : "false");
}
enum value::type value::type() const{
  return m_type;
}
static string escape(const string & str){
  stringstream ss;
  ss << "\"";
  for(string::const_iterator i = str.begin(); i != str.end(); i++){
    if(*i == '\n'){
      ss << "\\n";
    }
    else if(*i == '\t'){
      ss << "\\t";
    }
    if(*i == '\r'){
      ss << "\\r";
    }
    else if(*i == '\b'){
      ss << "\\b";
    }
    else if(*i == '\"' || *i == '\\'){
      ss<<"\\"<<*i;
    }
    else if(*i < 32 || *i >= 127){
      ss << "\\" << setfill('0') << setw(3)
	 << static_cast<unsigned int>(static_cast<unsigned char>(*i));
    }
    else{
      ss << *i;
    }
  }
  ss << "\"";
  return ss.str();
}
string value::print() const{
  stack<value> to_print;
  stack<int> remaining;
  stringstream ss;
  to_print.push(*this);
  while(!to_print.empty() || !remaining.empty()){
    if(!remaining.empty() && remaining.top() == 0){
      remaining.pop();
      ss<<")";
    }
    else if(to_print.top().type() == is_string){
      ss<<escape(to_print.top().to_string());
      to_print.pop();
      if(!remaining.empty()){
	--remaining.top();
      }
    }
    else{
      vector<value> job = to_print.top().to_list();
      ss<<"(";
      to_print.pop();
      for(vector<value>::const_reverse_iterator i = job.rbegin();
	  i != job.rend(); i++){
	to_print.push(*i);
      }
      if(!remaining.empty()){
	--remaining.top();
      }
      remaining.push(job.size());
    }
  }
  return ss.str();
}

parser::parser():
  m_token_reader(this){
}

void parser::read(char c){
  m_token_reader.read(c);
}

void parser::read_unused(char c){
  if(c == ' ' || c == '\t' || c == '\r' || c == '\n'){
  }
  else if(c == '('){
    m_nitems.push(0);
  }
  else if(c == ')'){
    if(m_nitems.empty()){
      on_error("Parenthesis mismatch");
    }
    else{
      int n_items = m_nitems.top();
      vector<value> souselem;
      m_nitems.pop();
      souselem.resize(n_items);
      for(int i = n_items - 1; i >= 0; i--){
	value to_push(m_stack.top());
	m_stack.pop();
	souselem[i] = to_push;
      }
      value res(souselem);
      if(m_nitems.empty()){
	on_value(res);
      }
      else{
	m_stack.push(res);
	++m_nitems.top();
      }
    }
  }
  else{
    std::stringstream ss;
    ss << "Invalid_nonstring_char " << static_cast<int>(c);
    on_error(ss.str());
  }
}

void parser::add_string(const string & unescaped){
  value res(unescaped);
  if(m_nitems.empty()){
    on_value(res);
  }
  else{
    m_stack.push(res);
    ++m_nitems.top();
  }
}

parser::string_parser::string_parser():
  m_quote(false){
}

void parser::string_parser::read(char c){
  if(m_quote){
    m_escape_sequence.push_back(c);
    resolve_escape_sequence();
  }
  else{
    if(c == '\"'){
      m_quote = true;
    }
    else{
      on_skipped(c);
    }
  }
}

#define push(c) m_resultat << c; m_escape_sequence.clear();
#define error(err) m_escape_sequence.pop_back(); on_error(err);
#define est_chiffre_hex(c)			\
  ((c >= '0' && c <= '9')			\
   || (c >= 'A' && c <= 'F')			\
   || (c >= 'a' && c <= 'f'))
#define est_chiffre(c) (c >= '0' && c <= '9')
#define chiffre(c) \
  ((c >= '0' && c <= '9') ? c - '0' :			\
   ((c >= 'A' && c <= 'F') ? c - 'A' + 10 :		\
    ((c >= 'a' && c <= 'f') ? c - 'a' + 10 : 0)))

void parser::string_parser::resolve_escape_sequence(){
  if(m_escape_sequence.size() > 0){
    switch(m_escape_sequence[0]){
    case '\\':
      if(m_escape_sequence.size() > 1)
	switch(m_escape_sequence[1]){
	case 'n': push('\n'); break;
	case 't': push('\t'); break;
	case 'r': push('\r'); break;
	case 'b': push('\b'); break;
	case '\\':
	case '\"':
	case '\'':
	case ' ': push(m_escape_sequence[1]); break;
	case 'x':
	  if(m_escape_sequence.size() == 4
	     && est_chiffre_hex(m_escape_sequence[2])
	     && est_chiffre_hex(m_escape_sequence[3])){
	    push(chiffre(m_escape_sequence[2]) * 16 + chiffre(m_escape_sequence[3]));
	  }
	  else if(m_escape_sequence.size() == 4){
	    stringstream ss;
	    ss << "Invalid_hex_digit " << m_escape_sequence[3];
	    error(ss.str());
	  }
	  else if(m_escape_sequence.size() == 3
		  && !est_chiffre(m_escape_sequence[2])){
	    stringstream ss;
	    ss << "Invalid_hex_digit " << m_escape_sequence[2];
	    error(ss.str());
	  }
	  break;
	case '0':
	case '1':
	case '2':
	  if(m_escape_sequence.size() == 4
	     && est_chiffre(m_escape_sequence[2])
	     && est_chiffre(m_escape_sequence[3])){
	    int res = chiffre(m_escape_sequence[1]) * 100
	      + chiffre(m_escape_sequence[2]) * 10
	      + chiffre(m_escape_sequence[3]);
	    if(res < 256){
	      push(static_cast<char>(res));
	    }
	    else{
	      stringstream ss;
	      ss<<"Invalid_escaped_number "<< res;
	      error(ss.str());
	    }
	  }
	  else if(m_escape_sequence.size() == 4){
	    stringstream ss;
	    ss << "Invalid_digit " << m_escape_sequence[3];
	    error(ss.str());
	  }
	  else if(m_escape_sequence.size() == 3
		  && est_chiffre(m_escape_sequence[2])){
	    int res = chiffre(m_escape_sequence[1]) * 100
	      + chiffre(m_escape_sequence[2]) * 10;
	    if(res >= 256){
	      stringstream ss;
	      ss<<"Invalid_escaped_number "<< res;
	      error(ss.str());
	    }
	  }
	  else if(m_escape_sequence.size() == 3
		  && !est_chiffre(m_escape_sequence[2])){
	    stringstream ss;
	    ss << "Invalid_digit " << m_escape_sequence[2];
	    error(ss.str());
	  }
	  break;
	default:
	  if(est_chiffre(m_escape_sequence[1])){
	    int c = chiffre(m_escape_sequence[1]);
	    stringstream ss;
	    ss<<"Invalid_escaped_number "<< (c * 100);
	    error(ss.str());
	  }
	  else if(m_escape_sequence[1] < 32
		  || m_escape_sequence[1] >= 127){
	    stringstream ss;
	    ss<<"Invalid_character "<< static_cast<int>(m_escape_sequence[1]);
	    error(ss.str());
	  }
	  else{
	    push(m_escape_sequence[1]);
	  }
	}
      break;
    case '\"':
      m_quote = false;
      m_escape_sequence.clear();
      on_string(m_resultat.str());
      m_resultat.str("");
      break;
    default:
      push(m_escape_sequence[0]);
    }
  }
}

parser::my_parser::my_parser(parser * parent):
  parser::string_parser(), m_parent(parent){
}

void parser::my_parser::on_error(const string & err){
  m_parent->on_error(err);
}

void parser::my_parser::on_string(const std::string & str){
  m_parent->add_string(str);
}

void parser::my_parser::on_skipped(char c){
  m_parent->read_unused(c);
}
  
