#ifndef VALUE_DEFINED

#define VALUE_DEFINED

#include <vector>
#include <stack>

#include <string>
#include <sstream>
#include <map>

namespace tarotv{
  namespace protocol{
    class value{
    public:
      enum type{
	is_string,
	is_list
      };
      value();
      value(const std::string & str);
      value(const std::vector<value> & content);
      value(const value & v);
      value & operator=(const value & s);
      value & operator=(const std::string & str);
      value & operator=(const std::vector<value> & content);
      const std::vector<value> & to_list() const;
      const std::string & to_string() const;
      bool to_labelled(std::string & label, value & v) const;
      bool to_int(int & v) const;
      bool to_float(double & f) const;
      bool to_table(std::map<std::string, value> & table) const;
      bool to_bool(bool & b) const;
      static value of_labelled(const std::string & n, const value & v);
      static value of_int(int i);
      static value of_float(double f);
      static value of_table(const std::map<std::string, value> & table);
      static value of_bool(bool b);
      enum type type() const;
      std::string print() const;
    private:
      std::vector<value> m_list;
      std::string m_string;
      enum type m_type;
    };
    class parser{
    public:
      parser();
      void read(char c);
    protected:
      virtual void on_error(const std::string &) = 0;
      virtual void on_value(const value &) = 0;
    private:
      void read_unused(char c);
      void add_string(const std::string & unescaped);
      std::stack<value> m_stack;
      std::stack<int> m_nitems;
      class string_parser{
      public:
	string_parser();
	void read(char c);
      protected:
	virtual void on_error(const std::string &) = 0;
	virtual void on_string(const std::string &) = 0;
	virtual void on_skipped(char c) = 0;
      private:
	void resolve_escape_sequence();
	bool m_quote;
	std::vector<char> m_escape_sequence;
	std::stringstream m_resultat;
      };
      class my_parser: public string_parser{
      public: my_parser(parser * parent);
      protected:
	void on_error(const std::string &);
	void on_string(const std::string &);
	void on_skipped(char);
      private: parser * m_parent;
      };
      my_parser m_token_reader;
    };
  };
};

#endif
