#ifndef TAROTV_VALUE_DEFINIE

#define TAROTV_VALUE_DEFINIE

#include <stdlib.h>

enum tarotv_value_t{
  is_string, is_list
};

struct tarotv_value_string{
  size_t strsize;
  char * str;
};

struct tarotv_value_list{
  size_t nleaves;
  struct tarotv_value ** leaves;
};

union tarotv_value_u{
  struct tarotv_value_string as_string;
  struct tarotv_value_list as_list;
};

struct tarotv_value{
  enum tarotv_value_t t;
  union tarotv_value_u u;
};

struct tarotv_value_parser;

enum tarotv_config_type_t{
  type_is_int, type_is_bool
};

struct tarotv_config_type_int{
  int min; int max; int incr;
};

union tarotv_config_type_u{
  struct tarotv_config_type_int as_int;
  int as_bool;
};

struct tarotv_config_type{
  enum tarotv_config_type_t t;
  union tarotv_config_type_u u;
  size_t taille_nom_court;
  char * nom_court;
  size_t taille_nom_long;
  char * nom_long;
};

enum tarotv_config_value_t{
  value_is_int, value_is_bool
};

union tarotv_config_value_u{
  int as_int;
  int as_bool;
};

struct tarotv_config_value{
  enum tarotv_config_value_t t;
  union tarotv_config_value_u u;
  size_t taille_nom_court;
  char * nom_court;
};

enum tarotv_sockaddr_t{
  is_unix, is_inet
};

struct tarotv_sockaddr_inet{
  char * addr_string;
  unsigned int port;
};

union tarotv_sockaddr_u{
  char * as_unix;
  struct tarotv_sockaddr_inet as_inet;
};

struct tarotv_sockaddr{
  enum tarotv_sockaddr_t t;
  union tarotv_sockaddr_u u;
};

enum tarotv_decision{
  is_attente, is_refus, is_accord
};

struct tarotv_invitation{
  int nombre_joueurs;
  size_t * tailles_noms;
  char ** noms;
  struct tarotv_value * parametres;
  enum tarotv_decision * prets;
};

struct tarotv_interface_handler{
  void (*connecte)(void *, int, const struct tarotv_config_type *);
  void (*echec_connexion)(void *);
  void (*identifier)(void *, size_t, const char *);
  void (*echec_identification)(void *);
  void (*deconnecte)(void *);
  void (*message_envoye)(void *);
  void (*trop_bavard)(void *);
  void (*invitation_reussie)(void *);
  void (*echec_invitation)(void *);
  void (*invitation_annulee)(void *);
  void (*reponse_jeu)(void *, int, const struct tarotv_value *);
  void (*nouveau_joueur)(void *, size_t, const char *);
  void (*depart_joueur)(void *, size_t, const char *);
  void (*message_recu)(void *, size_t, const char *,
		       size_t, const char *);
  void (*en_jeu)(void *, size_t, const char *,
		 const struct tarotv_sockaddr *,
		 const struct tarotv_value *);
  void (*invitations_modifiees)(void *, int,
				const struct tarotv_invitation *);
  void (*about_to_delete)(void *);
  void * user_data;
};

void init(char * argv[]);

struct tarotv_value * alloc_value_string(size_t strsize,
					 const char * str);
struct tarotv_value * alloc_value_list(size_t nleaves,
				       struct tarotv_value ** leaves);
struct tarotv_value * alloc_value_int(int i);
struct tarotv_value * alloc_value_float(float f);
struct tarotv_value * alloc_value_bool(int b);
struct tarotv_value * alloc_value_labelled(size_t labelsize,
					   const char * label,
					   struct tarotv_value * x);
struct tarotv_value_parser * alloc_parser();
int alloc_interface(struct tarotv_interface_handler * ih);
// Retourne un numéro pour les opérations
int parser_read(char c, struct tarotv_value_parser * p,
		struct tarotv_value ** dest);
// 0: nothing to do, 1: OK, _: error
// Remember to free *dest !
char * print_value(struct tarotv_value * v, int pretty);
// Remember to free the chars !
void delete_interface(int i);
int verifier_invitation(int i, int njoueurs, int nparams,
			const struct tarotv_config_value * values);
void set_host(int i, const struct tarotv_sockaddr * addr);
void identifier(int i, size_t taille_nom, const char * nom);
void deconnecter(int i);
void message(int i, size_t taille, const char * message);
void inviter(int i, int nombre_joueurs, const size_t * tailles_noms,
	     int nombre_parametres,
	     const struct tarotv_config_value * parametres);
void annuler_invitation(int i);
void jeu(int i, const struct tarotv_value * req);

void free_value(struct tarotv_value * v);
void free_parser(struct tarotv_value_parser * p);

#endif
