/* Ruby extension API. */
#include <ruby.h>
/* Generated by 'extconf.rb' to point to the PC/SC header. */
#include "pcsc_include.h"

/* Namespace structure. */
extern VALUE mSmartcard; /* Smartcard module / namespace */
extern VALUE mPcsc; /* Smartcard::PCSC module / namespace */

/* Class Smartcard::PCSC::ReaderStates */
extern VALUE cPcscReaderStates;
void Init_PCSC_ReaderStates();
int _PCSC_ReaderStates_lowlevel_get(VALUE rbReaderStates, SCARD_READERSTATE **reader_states, size_t *reader_states_count);

/* Class Smartcard::PCSC::IoRequest */
extern VALUE cPcscIoRequest;
void Init_PCSC_IoRequest();
int _PCSC_IoRequest_lowlevel_get(VALUE rbIoRequest, SCARD_IO_REQUEST **io_request);

/* Class Smartcard::PCSC::Context */
extern VALUE cPcscContext;
void Init_PCSC_Context();
int _PCSC_Context_lowlevel_get(VALUE rbContext, SCARDCONTEXT *pcsc_context);

/* Class Smartcard::PCSC::Card */
extern VALUE cPcscCard;
void Init_PCSC_Card();
int _PCSC_Card_lowlevel_get(VALUE rbCard, SCARDHANDLE *card_handle);

/* Constants in Smartcard::PCSC */
void Init_PCSC_Consts();

/* Multi-string (win32 abomination) tools. */
VALUE PCSC_Internal_multistring_to_ruby_array(char *mstr, size_t mstr_len);
int PCSC_Internal_ruby_strings_to_multistring(VALUE rbStrings, char **strings);
