#include "pcsc.h"

VALUE cPcscIoRequest;

/* Wraps a SCARD_IO_REQUEST, tracking its allocation etc. */
struct SCardIoRequestEx {
	SCARD_IO_REQUEST *pcsc_request;
	int mallocd; 
};

/* Custom free for Smartcard::PCSC::IoRequest. */
static void PCSC_IoRequest_free(struct SCardIoRequestEx *_request) {
	if(_request != NULL) {
		if(_request->mallocd)
			xfree(_request->pcsc_request);
		xfree(_request);
	}
}

/* Custom allocation for Smartcard::PCSC::Card. Wraps a SCardIoRequestEx. */
static VALUE PCSC_IoRequest_alloc(VALUE klass) {
	struct SCardIoRequestEx *request;
	
	VALUE rbIoRequest = Data_Make_Struct(klass, struct SCardIoRequestEx, NULL, PCSC_IoRequest_free, request);
	request->pcsc_request = NULL;
	request->mallocd = 0;
	return rbIoRequest;
}

/* :Document-method: new
 * call-seq:
 *      new() --> io_request
 * 
 * Creates an uninitialized IoRequest. 
 * The request can be used as a receiving IoRequest in Smartcard::PCSC::Card#transmit.
 */
static VALUE PCSC_IoRequest_initialize(VALUE self) {
	struct SCardIoRequestEx *request;	
	
	Data_Get_Struct(self, struct SCardIoRequestEx, request);
	request->pcsc_request = ALLOC(SCARD_IO_REQUEST);
	request->mallocd = 1;
	
	return self;
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
	struct SCardIoRequestEx *request;
	
	Data_Get_Struct(self, struct SCardIoRequestEx, request);
	if(request == NULL) return Qnil;
	
	return UINT2NUM(request->pcsc_request->dwProtocol);
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
	struct SCardIoRequestEx *request;
	
	Data_Get_Struct(self, struct SCardIoRequestEx, request);
	if(request == NULL) return self;
	
	if(request->mallocd == 0)
		rb_raise(rb_eSecurityError, "cannot modify PC/SC-global (read-only) IO_REQUEST");
	else
		request->pcsc_request->dwProtocol = NUM2UINT(rbProtocol);
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
	rb_define_method(cPcscIoRequest, "initialize", PCSC_IoRequest_initialize, 0);	
	rb_define_method(cPcscIoRequest, "protocol", PCSC_IoRequest_get_protocol, 0);	
	rb_define_method(cPcscIoRequest, "protocol=", PCSC_IoRequest_set_protocol, 1);	
}

/* Retrieves the SCARD_IO_REQUEST wrapped into a Smartcard::PCSC::IoRequest instance. */
int _PCSC_IoRequest_lowlevel_get(VALUE rbIoRequest, SCARD_IO_REQUEST **io_request) {
	struct SCardIoRequestEx *request;	

	if(!RTEST(rbIoRequest)) {
		*io_request = NULL;
		return 1;
	}
	if(TYPE(rbIoRequest) != T_DATA || RDATA(rbIoRequest)->dfree != (void (*)(void *))PCSC_IoRequest_free)
		return 0;
	
	Data_Get_Struct(rbIoRequest, struct SCardIoRequestEx, request);
	*io_request = request->pcsc_request;
	return 1;
}

/* Creates a Smartcard::PCSC::IoRequest instance wrapping a given SCARD_IO_REQUEST. */
VALUE _PCSC_IoRequest_lowlevel_new(SCARD_IO_REQUEST *io_request) {
	struct SCardIoRequestEx *request;
	
	VALUE rbIoRequest = Data_Make_Struct(cPcscIoRequest, struct SCardIoRequestEx, NULL, PCSC_IoRequest_free, request);
	request->pcsc_request = io_request;
	request->mallocd = 0;
	return rbIoRequest;
}
