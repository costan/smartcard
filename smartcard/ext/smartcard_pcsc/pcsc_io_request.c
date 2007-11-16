#include "pcsc.h"

VALUE cPcscIoRequest;

/* Custom free for Smartcard::PCSC::IoRequest. */
static void PCSC_IoRequest_free(SCARD_IO_REQUEST *_request) {
	if(_request != NULL)
		xfree(_request);
}

/* Custom allocation for Smartcard::PCSC::Card. Wraps a SCARD_IO_REQUEST. */
static VALUE PCSC_IoRequest_alloc(VALUE klass) {
	SCARD_IO_REQUEST *request;
	
	VALUE rbIoRequest = Data_Make_Struct(klass, SCARD_IO_REQUEST, NULL, PCSC_IoRequest_free, request);
	return rbIoRequest;
}

/* :Document-method: protocol
 * call-seq:
 *      io_request.protocol --> protocol
 * 
 * The protocol of this instance.
 * 
 * The returned protocol is a number, and should be checked against one of the Smartcard::PCSC::PROTOCOL_ constants.
 */
static VALUE PCSC_IoRequest_get_protocol(VALUE self) {
	SCARD_IO_REQUEST *request;
	Data_Get_Struct(self, SCARD_IO_REQUEST, request);
	if(request == NULL) return Qnil;
	
	return UINT2NUM(request->dwProtocol);
}

/* :Document-method: protocol=
 * call-seq:
 *      io_request.protocol = protocol
 * 
 * Sets the protocol of this instance.
 * 
 * +protocol+:: use one of the Smartcard::PCSC::PROTOCOL_ constants
 */
static VALUE PCSC_IoRequest_set_protocol(VALUE self, VALUE rbProtocol) {
	SCARD_IO_REQUEST *request;
	Data_Get_Struct(self, SCARD_IO_REQUEST, request);
	if(request == NULL) return self;
	
	request->dwProtocol = NUM2UINT(rbProtocol);
	return self;
}

#ifdef MAKE_RDOC_HAPPY
	mSmartcard = rb_define_module("Smartcard");
	mPcsc = rb_define_module_under(mSmartcard, "PCSC");
#endif

/* :Document-class: Smartcard::PCSC::IoRequest
 * Protocol information used in Smartcard::PCSC::Card#transmit.
 * Wraps a _SCARD_IO_REQUEST_ structure.
 * 
 * I know the name is retarded, but it reflects the PC/SC name well. The choice makes sense given that this
 * is an API meant for people familiar with the PC/SC specification.
 */
void Init_PCSC_IoRequest() {
	cPcscIoRequest = rb_define_class_under(mPcsc, "IoRequest", rb_cObject);
	rb_define_alloc_func(cPcscIoRequest, PCSC_IoRequest_alloc);
	rb_define_method(cPcscIoRequest, "protocol", PCSC_IoRequest_get_protocol, 0);	
	rb_define_method(cPcscIoRequest, "protocol=", PCSC_IoRequest_set_protocol, 1);	
}

/* Retrieves the SCARD_IO_REQUEST wrapped into a Smartcard::PCSC::IoRequest instance. */
int _PCSC_IoRequest_lowlevel_get(VALUE rbIoRequest, SCARD_IO_REQUEST **io_request) {
	if(TYPE(rbIoRequest) == T_NIL || TYPE(rbIoRequest) == T_FALSE) {
		*io_request = NULL;
		return 1;
	}
	if(TYPE(rbIoRequest) != T_DATA || RDATA(rbIoRequest)->dfree != (void (*)(void *))PCSC_IoRequest_free)
		return 0;
	
	SCARD_IO_REQUEST *request;	
	Data_Get_Struct(rbIoRequest, SCARD_IO_REQUEST, request);
	*io_request = request;
	return 1;
}
