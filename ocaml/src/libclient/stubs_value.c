#include "stubs_private.h"

struct tarotv_value_parser{
  value caml_closure_parse;
};

void init(char * argv[]){
  caml_startup(argv);
}

struct tarotv_value * alloc_value_string(size_t strsize,
					 const char * str){
  struct tarotv_value * res = NULL;
  res = malloc(sizeof(struct tarotv_value));
  res->t = is_string;
  res->u.as_string.strsize = strsize;
  res->u.as_string.str = malloc(strsize);
  memcpy(res->u.as_string.str, str, strsize);
  return res;
}

struct tarotv_value * alloc_value_list(size_t nleaves,
				       struct tarotv_value ** leaves){
  struct tarotv_value * res = NULL;
  res = malloc(sizeof(struct tarotv_value));
  res->t = is_list;
  res->u.as_list.nleaves = nleaves;
  res->u.as_list.leaves = malloc(nleaves * sizeof(struct tarotv_value *));
  memcpy(res->u.as_list.leaves, leaves,
	 nleaves * sizeof(struct tarotv_value *));
  return res;
}

struct tarotv_value * alloc_value_int(int i){
  char buffer[10] = "";
  sprintf(buffer, "%d", i);
  return alloc_value_string(strlen(buffer), buffer);
}

struct tarotv_value * alloc_value_float(float f){
  char buffer[51];
  sprintf(buffer, "%f", f);
  return alloc_value_string(strlen(buffer), buffer);
}

struct tarotv_value * alloc_value_bool(int b){
  return b ? alloc_value_string(4, "true")
    : alloc_value_string(5, "false");
}

struct tarotv_value * alloc_value_labelled(size_t labelsize,
					   const char * label,
					   struct tarotv_value * x){
  struct tarotv_value * liste[] = {alloc_value_string(labelsize, label), x};
  return alloc_value_list(2, liste);
}

struct tarotv_value_parser * alloc_parser(){
  static value * closure_read = NULL;
  struct tarotv_value_parser * p = NULL;
  if(closure_read == NULL){
    closure_read = caml_named_value("caml_create_parser");
  }
  p = malloc(sizeof(struct tarotv_value_parser *));
  p->caml_closure_parse = caml_callback(*closure_read, Val_unit);
  caml_register_global_root(&(p->caml_closure_parse));
  return p;
}

struct tarotv_value * copy_value_from_caml(value value_tarotv){
  CAMLparam1(value_tarotv);
  CAMLlocal1(i);
  int n = 0;
  struct tarotv_value ** buffer = NULL;
  struct tarotv_value * resultat = NULL;
  switch(Tag_val(value_tarotv)){
  case 0: // String
    resultat = alloc_value_string(caml_string_length(Field(value_tarotv, 0)),
				  String_val(Field(value_tarotv, 0)));
    break;
  case 1: // List
    for(n = 0, i = Field(value_tarotv, 0); Is_block(i);
	n++, i = Field(i, 1));
    buffer = malloc(n * sizeof(struct tarotv_value *));
    for(n = 0, i = Field(value_tarotv, 0); Is_block(i);
	n++, i = Field(i, 1)){
      buffer[n] = copy_value_from_caml(Field(i, 0));
    }
    resultat = alloc_value_list(n, buffer);
    free(buffer);
    break;
  default:
    break;
  }
  return resultat;
}

value copy_value_to_caml(struct tarotv_value * v){
  CAMLparam0();
  CAMLlocal4(caml_v, i_parent, i, caml_string);
  int j = 0;
  switch(v->t){
  case is_string:
    caml_string = caml_alloc_string(v->u.as_string.strsize);
    caml_v = caml_alloc(1, 0); // 1 argument, type String
    for(j = 0; j < v->u.as_string.strsize; j++){
      Byte(caml_string, j) = v->u.as_string.str[j];
    }
    Store_field(caml_v, 0, caml_string);
    break;
  case is_list:
    caml_v = caml_alloc(1, 1);
    Store_field(caml_v, 0, Val_int(0));
    j = v->u.as_list.nleaves - 1;;
    i_parent = Val_int(0);
    i = Val_int(0);
    while(j >= 0){
      i_parent = caml_alloc(2, 0);
      Store_field(i_parent, 1, i);
      Store_field(i_parent, 0, copy_value_to_caml(v->u.as_list.leaves[j]));
      i = i_parent;
      j--;
    }
    Store_field(caml_v, 0, i);
    break;
  }
  CAMLreturn(caml_v);
}

int parser_read(char c, struct tarotv_value_parser * p,
		struct tarotv_value ** dest){
  CAMLlocal1(resultat);
  int retour = 2;
  resultat = caml_callback_exn(p->caml_closure_parse, Val_int(c));
  if(Is_exception_result(resultat)){
    resultat = Extract_exception(resultat);
    retour = -1;
  }
  else if(Is_block(resultat)){
    *(dest) = copy_value_from_caml(Field(resultat, 0));
    retour = 1;
  }
  else retour = 0;
  return retour;
}

char * print_value(struct tarotv_value * v, int pretty){
  CAMLlocal1(retour);
  char * buff = NULL;
  static value * closure_print = NULL;
  if(closure_print == NULL){
    closure_print = caml_named_value("caml_print_value");
  }
  retour = caml_callback2(*closure_print, (pretty ? Val_true : Val_false),
			  copy_value_to_caml(v));
  buff = strdup(String_val(retour));
  return buff;
}

void free_value(struct tarotv_value * v){
  int i = 0;
  switch(v->t){
  case is_string:
    free(v->u.as_string.str);
    break;
  case is_list:
    for(i = 0; i < v->u.as_list.nleaves; i++){
      free_value(v->u.as_list.leaves[i]);
    }
    free(v->u.as_list.leaves);
    break;
  }
  free(v);
}

void free_parser(struct tarotv_value_parser * p){
  caml_remove_global_root(&(p->caml_closure_parse));
  free(p);
}
