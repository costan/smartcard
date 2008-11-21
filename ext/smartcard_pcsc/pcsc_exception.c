#include "pcsc.h"

VALUE ePcscException;

#if defined(WIN32)
static char scard_error_buffer[128];

/* Produces a string for an error code yielded by the SCard* PC/SC functions. Returns a static global buffer. */
static char *pcsc_stringify_error(DWORD scard_error) {
	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
		NULL, scard_error, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        scard_error_buffer, sizeof(scard_error_buffer), NULL );
	return scard_error_buffer;
}
#endif


#ifdef MAKE_RDOC_HAPPY
	mSmartcard = rb_define_module("Smartcard");
	mPcsc = rb_define_module_under(mSmartcard, "PCSC");
#endif

/* :Document-class: Smartcard::PCSC::Exception
 * Contains information about an exception at the PC/SC layer.
 */
void Init_PCSC_Exception() {
	ePcscException = rb_define_class_under(mPcsc, "PcscException", rb_eRuntimeError);
}

/* Raises a PC/SC error. */
void _PCSC_Exception_raise(DWORD pcsc_error, char *pcsc_function) {
	char buf[BUFSIZ];
	VALUE exception;
	
	sprintf(buf, "%s: %s", pcsc_function, pcsc_stringify_error(pcsc_error));
	exception = rb_exc_new2(ePcscException, buf);
	rb_iv_set(exception, "@errno", INT2NUM(pcsc_error));
	rb_exc_raise(exception);
}
