#include "pcsc.h"

VALUE cPcscCard;

/* Wraps a SCARDHANDLE, tracking whether it was released or not, together with the last error that occured on it. */
struct SCardHandleEx {
	SCARDHANDLE card_handle;
	DWORD pcsc_error;
	int released;
};

/* Custom free for Smartcard::PCSC::Card. Releases the card handle via a disconnect if that was not already done. */
static void PCSC_Card_free(struct SCardHandleEx *_card) {
	if(_card != NULL) {
		if(!_card->released)
			SCardDisconnect(_card->card_handle, SCARD_LEAVE_CARD);
		xfree(_card);
	}
}

/* Custom allocation for Smartcard::PCSC::Card. Wraps a SCardHandleEx. */
static VALUE PCSC_Card_alloc(VALUE klass) {
	struct SCardHandleEx *card;
	
	VALUE rbCard = Data_Make_Struct(klass, struct SCardHandleEx, NULL, PCSC_Card_free, card);
	card->pcsc_error = SCARD_S_SUCCESS;
	card->released = 1;
	return rbCard;
}

/* :Document-method: new
 * call-seq:
 *      new(context, reader_name, share_mode, preferred_protocols) --> card
 * 
 * Establishes a connection to the card in the reader whose friendly name is +reader_name+.
 * The first connection will power up and perform a reset on the card.
 * Wraps _SCardConnect_ in PC/SC.
 * 
 * +context+:: the Smartcard::PCSC::Context to use to connect to the PC/SC resource manager
 * +reader_name+:: friendly name of the reader to connect to; get using Smartcard::PCSC::Context#list_readers 
 * +share_mode+:: whether a shared or exclusive lock will be requested on the reader; use one of the Smartcard::PCSC::SHARE_ constants 
 * +preferred_protocols+:: desired protocol; use one of the Smartcard::PCSC::PROTOCOL_ constants
 */
static VALUE PCSC_Card_initialize(VALUE self, VALUE rbContext, VALUE rbReaderName, VALUE rbShareMode, VALUE rbPreferredProtocols) {
	struct SCardHandleEx *card;
	Data_Get_Struct(self, struct SCardHandleEx, card);
	
	SCARDCONTEXT context;
	if(_PCSC_Context_lowlevel_get(rbContext, &context) == 0) {
		rb_raise(rb_eArgError, "first argument is not a Context instance");
		return self;
	}
	
	VALUE rbFinalReaderName = rb_check_string_type(rbReaderName);
	if(NIL_P(rbFinalReaderName)) {
		rb_raise(rb_eArgError, "second argument (should be reader name) does not convert to a String");
		return self;
	}
	
	DWORD share_mode = NUM2UINT(rbShareMode);
	DWORD preferred_protocols = NUM2UINT(rbPreferredProtocols);
	
	DWORD active_protocol;
	card->pcsc_error = SCardConnect(context, RSTRING(rbFinalReaderName)->ptr, share_mode, preferred_protocols, &card->card_handle, &active_protocol);	
	if(card->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardConnect: %s", pcsc_stringify_error(card->pcsc_error));
	else
		card->released = 0;
	return self;
}

/* :Document-method: reconnect
 * call-seq:
 *      card.reconnect(share_mode, preferred_protocols, initialization) --> self
 * 
 * Reestablishes a connection to a reader that was previously connected to using Card#new.
 * Wraps _SCardReconnect_ in PC/SC.
 * 
 * +share_mode+:: whether a shared or exclusive lock will be requested on the reader; use one of the Smartcard::PCSC::SHARE_ constants 
 * +preferred_protocols+:: desired protocol; use one of the Smartcard::PCSC::PROTOCOL_ constants
 * +initialization+:: action to be taken on the card inside the reader; use one of the Smartcard::PCSC::INITIALIZE_ constants
 */
static VALUE PCSC_Card_reconnect(VALUE self, VALUE rbShareMode, VALUE rbPreferredProtocols, VALUE rbInitialization) {
	struct SCardHandleEx *card;
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return self;

	DWORD share_mode = NUM2UINT(rbShareMode);
	DWORD preferred_protocols = NUM2UINT(rbPreferredProtocols);
	DWORD initialization = NUM2UINT(rbInitialization);
	
	uint32_t active_protocol;
	card->pcsc_error = SCardReconnect(card->card_handle, share_mode, preferred_protocols, initialization, &active_protocol);
	if(card->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardReconnect: %s", pcsc_stringify_error(card->pcsc_error));

	return self;
}

/* :Document-method: disconnect
 * call-seq:
 *      context.disconnect(disposition) --> self
 * 
 * Terminates the connection made using Card#new. The Card object is invalid afterwards.
 * Wraps _SCardDisconnect_ in PC/SC.
 * 
 * +disposition+:: action to be taken on the card inside the reader; use one of the Smartcard::PCSC::DISPOSITION_ constants
 */
static VALUE PCSC_Card_disconnect(VALUE self, VALUE rbDisposition) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return self;

	DWORD disposition = NUM2UINT(rbDisposition);
	if(!card->released) {
		card->pcsc_error = SCardDisconnect(card->card_handle, disposition);		
		card->released = 1;
		if(card->pcsc_error != SCARD_S_SUCCESS)
			rb_raise(rb_eRuntimeError, "SCardDisconnect: %s", pcsc_stringify_error(card->pcsc_error));
	}
	return self;
}

/* :Document-method: begin_transaction
 * call-seq:
 *      card.begin_transaction() --> self
 * 
 * Establishes a temporary exclusive access mode for doing a series of commands or transaction. 
 * Wraps _SCardBeginTransaction_ in PC/SC.
 */
static VALUE PCSC_Card_begin_transaction(VALUE self) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return self;
	
	card->pcsc_error = SCardBeginTransaction(card->card_handle);
	if(card->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardBeginTransaction: %s", pcsc_stringify_error(card->pcsc_error));	
	return self;
}

/* :Document-method: end_transaction
 * call-seq:
 *      context.end_transaction(disposition) --> attribute_value
 * 
 * Ends a previously begun transaction. The calling application must be the owner of the previously begun transaction or an error will occur. 
 * Wraps _SCardEndTransaction_ in PC/SC.
 * 
 * +disposition+:: action to be taken on the card inside the reader; use one of the Smartcard::PCSC::DISPOSITION_ constants
 */
static VALUE PCSC_Card_end_transaction(VALUE self, VALUE rbDisposition) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return self;
	
	DWORD disposition = NUM2UINT(rbDisposition);
	card->pcsc_error = SCardEndTransaction(card->card_handle, disposition);
	if(card->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardEndTransaction: %s", pcsc_stringify_error(card->pcsc_error));	
	return self;
}

/* :Document-method: get_attribute
 * call-seq:
 *      card.get_attribute(attribute_id) --> attribute_value
 * 
 * Reads the value of an attribute from the interface driver.
 * Remember that the IFD may not implement some of the attributes specified in Smartcard::PCSC, and it may implement some attributes that
 * are not included in Smartcard::PCSC.
 * Wraps _SCardGetAttrib_ in PC/SC.
 * 
 * The returned value has the bytes in the attribute, wrapped in a string. (don't complain, it's a low-level API)
 * 
 * +attribute_id+:: identifies the attribute to be read; use one of the Smartcard::PCSC::ATTR_ constants
 */
static VALUE PCSC_Card_get_attribute(VALUE self, VALUE rbAttributeId) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return Qnil;
	
	DWORD attribute_id = NUM2UINT(rbAttributeId);
	DWORD attribute_length;
	card->pcsc_error = SCardGetAttrib(card->card_handle, attribute_id, NULL, &attribute_length);
	if(card->pcsc_error == SCARD_S_SUCCESS) {
		char *attribute_buffer = ALLOC_N(char, attribute_length);
		if(attribute_buffer != NULL) {
			card->pcsc_error = SCardGetAttrib(card->card_handle, attribute_id, (LPSTR)attribute_buffer, &attribute_length);
			if(card->pcsc_error == SCARD_S_SUCCESS) {
				VALUE rbAttribute = rb_str_new(attribute_buffer, attribute_length);
				xfree(attribute_buffer);
				return rbAttribute;
			}
		}
	}
	if(card->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardGetAttrib: %s", pcsc_stringify_error(card->pcsc_error));	
	return Qnil;
}

/* :Document-method: set_attribute
 * call-seq:
 *      context.set_attribute(attribute_id, attribute_value) --> self
 * 
 * Sets the value of an attribute in the interface driver.
 * Remember that the IFD may not implement some of the attributes specified in Smartcard::PCSC, and it may implement some attributes that
 * are not included in Smartcard::PCSC.
 * Wraps _SCardSetAttrib_ in PC/SC.
 * 
 * +attribute_id+:: identifies the attribute to be set; use one of the Smartcard::PCSC::ATTR_ constants
 * +attribute_value+:: the value to be assigned to the attribute; wrap the bytes in a string-like object (low-level API, remember?)
 */
static VALUE PCSC_Card_set_attribute(VALUE self, VALUE rbAttributeId, VALUE rbAttributeValue) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return self;
	
	DWORD attribute_id = NUM2UINT(rbAttributeId);

	VALUE rbFinalAttributeValue = rb_check_string_type(rbAttributeValue);
	if(NIL_P(rbFinalAttributeValue)) {
		rb_raise(rb_eArgError, "second argument (attribute buffer) does not convert to a String");
		return self;
	}
	
	card->pcsc_error = SCardSetAttrib(card->card_handle, attribute_id, (LPSTR)RSTRING(rbFinalAttributeValue)->ptr, RSTRING(rbFinalAttributeValue)->len);	
	if(card->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardSetAttrib: %s", pcsc_stringify_error(card->pcsc_error));	
	return self;
}

/* :Document-method: transmit
 * call-seq:
 *      card.transmit(send_data, send_io_request, recv_io_request) --> recv_data
 * 
 * Sends an APDU to the smart card, and returns the card's response to the APDU.
 * Wraps _SCardTransmit_ in PC/SC.
 * 
 * The bytes in the card's response are returned wrapped in a string. (don't complain, it's a low-level API)
 * 
 * +send_data+:: the APDU to be send to the card; wrap the bytes in a string-like object (low-level API, remember?)
 * +send_io_request+:: Smartcard::PCSC::IoRequest instance indicating the send protocol; you can use one of the Smartcard::PCSC::PCI_ constants
 * +recv_io_request+:: Smartcard::PCSC::IoRequest instance receving information about the recv protocol; you can use the result of Smartcard::PCSC::IoRequest#new
 */
static VALUE PCSC_Card_transmit(VALUE self, VALUE rbSendData, VALUE rbSendIoRequest, VALUE rbRecvIoRequest) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return Qnil;
	
	VALUE rbFinalSendData = rb_check_string_type(rbSendData);
	if(NIL_P(rbFinalSendData)) {
		rb_raise(rb_eArgError, "first argument (send buffer) does not convert to a String");
		return Qnil;
	}
	
	SCARD_IO_REQUEST *send_io_request;
	if(_PCSC_IoRequest_lowlevel_get(rbSendIoRequest, &send_io_request) == 0) {
		rb_raise(rb_eArgError, "second argument (send io request) is not an IoRequest instance");
		return Qnil;	
	}	
	SCARD_IO_REQUEST *recv_io_request;
	if(_PCSC_IoRequest_lowlevel_get(rbRecvIoRequest, &recv_io_request) == 0) {
		rb_raise(rb_eArgError, "second argument (recv io request) is not an IoRequest instance");
		return Qnil;	
	}
	
#if defined(PCSCLITE_MAX_MESSAGE_SIZE)
	DWORD recv_length = PCSCLITE_MAX_MESSAGE_SIZE;
#elif defined(MAX_BUFFER_SIZE_EXTENDED)
	DWORD recv_length = MAX_BUFFER_SIZE_EXTENDED;
#else
	DWORD recv_length = 65536;
#endif
	char *recv_buffer = ALLOC_N(char, recv_length);
	if(recv_buffer == NULL) return Qnil;
	
	card->pcsc_error = SCardTransmit(card->card_handle, send_io_request,
			(LPSTR)RSTRING(rbFinalSendData)->ptr, RSTRING(rbFinalSendData)->len,
			recv_io_request, (LPSTR)recv_buffer, &recv_length);	
	if(card->pcsc_error != SCARD_S_SUCCESS) {
		xfree(recv_buffer);
		rb_raise(rb_eRuntimeError, "SCardTransmit: %s", pcsc_stringify_error(card->pcsc_error));
		return Qnil;
	}

	VALUE rbRecvData = rb_str_new(recv_buffer, recv_length);
	xfree(recv_buffer);
	return rbRecvData;			
}

/* :Document-method: control
 * call-seq:
 *      card.control(control_code, send_data, max_recv_bytes) --> recv_data
 * 
 * Sends a command directly to the interface driver to be processed by the reader.
 * Useful for creating client side reader drivers for functions like PIN pads, biometrics, or other smart card reader
 * extensions that are not normally handled by PC/SC. 
 * Wraps _SCardControl_ in PC/SC.
 * 
 * The bytes in the response are returned wrapped in a string. (don't complain, it's a low-level API)
 * 
 * +control_code+:: control code for the operation; it's an integer, and it's IFD-specific
 * +send_data+:: the data bytes to be send to the driver; wrap the bytes in a string-like object (low-level API, remember?)
 * +max_recv_bytes+:: the maximum number of bytes that can be received
 * 
 * In general, I tried to avoid having you specify receive buffer sizes. This is the only case where that is impossible to achieve,
 * because there is no well-known maximum buffer size, and the _SCardControl_ call is not guaranteed to be idempotent, so it's not OK to
 * re-issue it until the buffer size works out.
 */
static VALUE PCSC_Card_control(VALUE self, VALUE rbControlCode, VALUE rbSendData, VALUE rbMaxRecvBytes) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return Qnil;
	
	VALUE rbFinalSendData = rb_check_string_type(rbSendData);
	if(NIL_P(rbFinalSendData)) {
		rb_raise(rb_eArgError, "second argument (send buffer) does not convert to a String");
		return Qnil;
	}
	
	DWORD control_code = NUM2UINT(rbControlCode);
	DWORD recv_length = NUM2UINT(rbMaxRecvBytes);
	char *recv_buffer = ALLOC_N(char, recv_length);
	if(recv_buffer == NULL) return Qnil;
	
	card->pcsc_error = SCardControl(card->card_handle, control_code,
			(LPSTR)RSTRING(rbFinalSendData)->ptr, RSTRING(rbFinalSendData)->len,
			recv_buffer, recv_length, &recv_length);
	if(card->pcsc_error != SCARD_S_SUCCESS) {
		xfree(recv_buffer);
		rb_raise(rb_eRuntimeError, "SCardControl: %s", pcsc_stringify_error(card->pcsc_error));
		return Qnil;
	}

	VALUE rbRecvData = rb_str_new(recv_buffer, recv_length);
	xfree(recv_buffer);
	return rbRecvData;			
}

static VALUE _rbStateKey, _rbProtocolKey, _rbAtrKey, _rbReaderNamesKey;

/* :Document-method: status
 * call-seq:
 *      card.status() --> card_status
 * 
 * Retrieves the current status of the smartcard, and packages it up in a nice hash for you.
 * Wraps _SCardStatus_ in PC/SC.
 * 
 * The response hash contains the following keys:
 * <tt>:state</tt> :: reader/card status; bitfield, with bits defined as Smartcard::PCSC::STATUS_ constants
 * <tt>:protocol</tt> :: the protocol established with the card; check against Smartcard::PCSC::PROTOCOL_ constants
 * <tt>:atr</tt> :: the card's ATR bytes, wrapped in a string
 * <tt>:reader_names</tt> :: array of strings containing all the names of the reader containing the smartcard
 */
static VALUE PCSC_Card_status(VALUE self) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return Qnil;

	DWORD atr_length = MAX_ATR_SIZE;
	char *atr_buffer = ALLOC_N(char, atr_length);	
	DWORD reader_names_length = 4096;
	char *reader_names_buffer = ALLOC_N(char, reader_names_length);
	if(atr_buffer == NULL || reader_names_buffer == NULL) {
		if(reader_names_buffer != NULL) xfree(reader_names_buffer);
		if(atr_buffer != NULL) xfree(atr_buffer);
		return Qnil;
	}
	
	DWORD state, protocol;
	card->pcsc_error = SCardStatus(card->card_handle, reader_names_buffer, &reader_names_length, &state, &protocol, (LPSTR)atr_buffer, &atr_length);
	if(card->pcsc_error != SCARD_S_SUCCESS) {
		xfree(reader_names_buffer); xfree(atr_buffer);
		rb_raise(rb_eRuntimeError, "SCardStatus: %s", pcsc_stringify_error(card->pcsc_error));
		return Qnil;
	}
	
	VALUE rbStateVal = UINT2NUM(state);
	VALUE rbProtocolVal = UINT2NUM(protocol);
	VALUE rbAtrVal = rb_str_new(atr_buffer, atr_length);
	VALUE rbReaderNamesVal = PCSC_Internal_multistring_to_ruby_array(reader_names_buffer, reader_names_length);
	
	VALUE rbReturnHash = rb_hash_new();
	rb_hash_aset(rbReturnHash, _rbStateKey, rbStateVal);
	rb_hash_aset(rbReturnHash, _rbProtocolKey, rbProtocolVal);
	rb_hash_aset(rbReturnHash, _rbAtrKey, rbAtrVal);
	rb_hash_aset(rbReturnHash, _rbReaderNamesKey, rbReaderNamesVal);
	return rbReturnHash;
}

/* :Document-method: last_error
 * call-seq:
 *      card.last_error() --> last_error
 * 
 * The error code returned by the last PC/SC call. Useful for recovering from exceptions.
 * 
 * The returned code is a number, and should be one of the Smartcard::PCSC::SCARD_ constants.
 * The code indicating correct operation is Smartcard::PCSC::SCARD_S_SUCCESS.
 */
static VALUE PCSC_Card_last_error(VALUE self) {
	struct SCardHandleEx *card;	
	Data_Get_Struct(self, struct SCardHandleEx, card);
	if(card == NULL) return Qnil;

	return UINT2NUM(card->pcsc_error);
}

#ifdef MAKE_RDOC_HAPPY
	mSmartcard = rb_define_module("Smartcard");
	mPcsc = rb_define_module_under(mSmartcard, "PCSC");
#endif

/* :Document-class: Smartcard::PCSC::Card
 * Connects a smart-card in a PC/SC reader to the Ruby world.
 * Wraps a _SCARDHANDLE_ structure.
 */
void Init_PCSC_Card() {
	ID state_id = rb_intern("status"); _rbStateKey = ID2SYM(state_id);
	ID protocol_id = rb_intern("protocol"); _rbProtocolKey = ID2SYM(protocol_id);
	ID atr_id = rb_intern("atr"); _rbAtrKey = ID2SYM(atr_id);
	ID reader_names_id = rb_intern("reader_names"); _rbReaderNamesKey = ID2SYM(reader_names_id);
	
	cPcscCard = rb_define_class_under(mPcsc, "Card", rb_cObject);
	rb_define_alloc_func(cPcscCard, PCSC_Card_alloc);
	rb_define_method(cPcscCard, "initialize", PCSC_Card_initialize, 4);
	rb_define_method(cPcscCard, "reconnect", PCSC_Card_reconnect, 3);	
	rb_define_method(cPcscCard, "disconnect", PCSC_Card_disconnect, 1);	
	rb_define_method(cPcscCard, "begin_transaction", PCSC_Card_begin_transaction, 0);	
	rb_define_method(cPcscCard, "end_transaction", PCSC_Card_end_transaction, 1);
	rb_define_method(cPcscCard, "get_attribute", PCSC_Card_get_attribute, 1);	
	rb_define_method(cPcscCard, "set_attribute", PCSC_Card_set_attribute, 2);
	rb_define_method(cPcscCard, "transmit", PCSC_Card_transmit, 3);	
	rb_define_method(cPcscCard, "control", PCSC_Card_control, 3);	
	rb_define_method(cPcscCard, "status", PCSC_Card_status, 0);
	rb_define_method(cPcscCard, "last_error", PCSC_Card_last_error, 0);
}

/* Retrieves the SCARDHANDLE wrapped into a Smartcard::PCSC::Card instance. */
int _PCSC_Card_lowlevel_get(VALUE rbCard, SCARDHANDLE *card_handle) {
	if(TYPE(rbCard) != T_DATA || RDATA(rbCard)->dfree != (void (*)(void *))PCSC_Card_free)
		return 0;
	
	struct SCardHandleEx *card;	
	Data_Get_Struct(rbCard, struct SCardHandleEx, card);
	*card_handle = card->card_handle;
	return 1;
}
