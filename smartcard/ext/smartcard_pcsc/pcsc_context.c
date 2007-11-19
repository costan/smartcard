#include "pcsc.h"

VALUE cPcscContext;

/* Wraps a SCARDHANDLE, tracking whether it was released or not, together with the last error that occured on it. */
struct SCardContextEx {
	SCARDCONTEXT pcsc_context;
	DWORD pcsc_error;
	int released; 
};


/* Custom free for Smartcard::PCSC::Context. Releases the PC/SC context if that was not already done. */
static void PCSC_Context_free(struct SCardContextEx *_context) {
	if(_context != NULL) {
		if(!_context->released)
			SCardReleaseContext(_context->pcsc_context);
		xfree(_context);
	}
}

/* Custom allocation for Smartcard::PCSC::Context. Wraps a SCardContextEx structure. */
static VALUE PCSC_Context_alloc(VALUE klass) {
	struct SCardContextEx *context;
	
	VALUE rbContext = Data_Make_Struct(klass, struct SCardContextEx, NULL, PCSC_Context_free, context);
	context->released = 1;
	return rbContext;
}

/* :Document-method: new
 * call-seq:
 *      new(scope) --> context
 * 
 * Creates an application context connecting to the PC/SC resource manager.
 * A context is required to access every piece of PC/SC functionality.
 * Wraps _SCardEstablishContext_ in PC/SC.
 * 
 * +scope+:: scope of the context; use one of the Smartcard::PCSC::SCOPE_ constants
 */
static VALUE PCSC_Context_initialize(VALUE self, VALUE scope) {
	struct SCardContextEx *context;	
	
	Data_Get_Struct(self, struct SCardContextEx, context);
	
	context->pcsc_error = SCardEstablishContext(NUM2INT(scope), NULL, NULL, &context->pcsc_context);
	if(context->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardEstablishContext: %s", pcsc_stringify_error(context->pcsc_error));
	else
		context->released = 0;
	return self;
}

/* :Document-method: release
 * call-seq:
 *      release() --> self
 * 
 * Destroys the communication context connecting to the PC/SC Resource Manager. 
 * Should be the last PC/SC function called, because a context is required to access every piece of PC/SC functionality.
 * Wraps _SCardReleaseContext_ in PC/SC.
 */
static VALUE PCSC_Context_release(VALUE self) {
	struct SCardContextEx *context;	
	
	Data_Get_Struct(self, struct SCardContextEx, context);
	if(context == NULL) return self;

	if(!context->released) {
		context->pcsc_error = SCardReleaseContext(context->pcsc_context);		
		context->released = 1;
		if(context->pcsc_error != SCARD_S_SUCCESS)
			rb_raise(rb_eRuntimeError, "SCardReleaseContext: %s", pcsc_stringify_error(context->pcsc_error));
	}
	return self;
}

/* :Document-method: is_valid
 * call-seq:
 *      is_valid() --> valid_boolean
 * 
 * Checks if the PC/SC context is still valid.
 * A context may become invalid if the resource manager service has been shut down.
 * Wraps _SCardIsValidContext_ in PC/SC.
 * 
 * Returns a boolean value with the obvious meaning.
 */
static VALUE PCSC_Context_is_valid(VALUE self) {
	struct SCardContextEx *context;	
	Data_Get_Struct(self, struct SCardContextEx, context);
	if(context == NULL) return self;

#if defined(RB_SMARTCARD_OSX_TIGER_HACK)	
	return Qtrue;
#else
	context->pcsc_error = SCardIsValidContext(context->pcsc_context);
	return (context->pcsc_error == SCARD_S_SUCCESS) ? Qtrue : Qfalse;
#endif
}

/* :Document-method: list_reader_groups
 * call-seq:
 *      list_reader_groups() --> reader_groups
 * 
 * Retrieves the currently available reader groups on the system. 
 * Wraps _SCardListReaderGroups_ in PC/SC.
 * 
 * Returns an array of strings containing the names of all the smart-card readers in the system.
 */
static VALUE PCSC_Context_list_reader_groups(VALUE self) {
	struct SCardContextEx *context;
	VALUE rbGroups;
	char *groups;
	DWORD groups_length;
	
	Data_Get_Struct(self, struct SCardContextEx, context);
	if(context == NULL) return Qnil;
		
	context->pcsc_error = SCardListReaderGroups(context->pcsc_context, NULL, &groups_length);
	if(context->pcsc_error == SCARD_S_SUCCESS) {
		groups = ALLOC_N(char, groups_length);
		if(groups != NULL) {
			context->pcsc_error = SCardListReaderGroups(context->pcsc_context, groups, &groups_length);
			if(context->pcsc_error == SCARD_S_SUCCESS) {
				rbGroups = PCSC_Internal_multistring_to_ruby_array(groups, groups_length);
				xfree(groups);
				return rbGroups;
			}
			else
				xfree(groups);
		}
	}
	if(context->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardListReaderGroups: %s", pcsc_stringify_error(context->pcsc_error));	
	return Qnil;
}

/* :Document-method: list_readers
 * call-seq:
 *      list_readers(reader_groups) --> readers
 * 
 * Retrieves a subset of the currently available card readers in the system. 
 * Wraps _SCardListReaders_ in PC/SC.
 * 
 * Returns an array of strings containing the names of the card readers in the given groups.
 * 
 * +reader_groups+:: array of strings indicating the reader groups to list; also accepts a string or +nil+ (meaning all readers)
 */
static VALUE PCSC_Context_list_readers(VALUE self, VALUE rbGroups) {
	struct SCardContextEx *context;
	VALUE rbReaders;
	char *groups;
	DWORD readers_length;
	
	Data_Get_Struct(self, struct SCardContextEx, context);
	if(context == NULL) return Qnil;

	if(PCSC_Internal_ruby_strings_to_multistring(rbGroups, &groups) == 0) {
		rb_raise(rb_eArgError, "invalid reader groups set (expecting nil or string or array of strings)");
		return Qnil;
	}
	
	context->pcsc_error = SCardListReaders(context->pcsc_context, groups, NULL, &readers_length);
	if(context->pcsc_error == SCARD_S_SUCCESS) {
		char *readers = ALLOC_N(char, readers_length);
		if(readers != NULL) {
			context->pcsc_error = SCardListReaders(context->pcsc_context, groups, readers, &readers_length);
			if(context->pcsc_error == SCARD_S_SUCCESS) {
				rbReaders = PCSC_Internal_multistring_to_ruby_array(readers, readers_length);
				xfree(readers);
				if(groups != NULL) xfree(groups);
				return rbReaders;
			}
			else
				xfree(readers);
		}
	}
	if(groups != NULL) xfree(groups);	
	if(context->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardListReaders: %s", pcsc_stringify_error(context->pcsc_error));	
	return Qnil;	
}

/* :Document-method: cancel
 * call-seq:
 *      cancel() --> self
 * 
 * Cancels all pending blocking requests on the Context#get_status_change function. 
 * Wraps _SCardCancel_ in PC/SC.
 */
static VALUE PCSC_Context_cancel(VALUE self) {
	struct SCardContextEx *context;
	
	Data_Get_Struct(self, struct SCardContextEx, context);
	if(context == NULL) return self;
	
	context->pcsc_error = SCardCancel(context->pcsc_context);
	if(context->pcsc_error != SCARD_S_SUCCESS)
		rb_raise(rb_eRuntimeError, "SCardCancel: %s", pcsc_stringify_error(context->pcsc_error));	
	return self;
}

/* :Document-method: get_status_change
 * call-seq:
 *      get_status_change(reader_states, timeout) --> self
 * 
 * Blocks until a status change occurs in one of the given readers. 
 * Wraps _SCardGetStatusChange_ in PC/SC.
 * 
 * +reader_states+:: Smartcard::PCSC::ReaderStates instance indicating the readers to be monitored, and the interesting state changes
 * +timeout+:: maximum ammount of time (in milliseconds) to block; use Smartcard::PCSC::INFINITE_TIMEOUT to block forever
 * 
 * The function blocks until the state of one of the readers in +reader_states+ becomes different from the +current_state+ (accessible via
 * ReaderStates#set_current_state_of and ReaderStates#current_state_of). The new state is stored in +event_state+ (accessible via
 * ReaderStates#set_event_state_of and ReaderStates#event_state_of)
 */
static VALUE PCSC_Context_get_status_change(VALUE self, VALUE rbReaderStates, VALUE rbTimeout) {
	struct SCardContextEx *context;
	SCARD_READERSTATE *reader_states;
	size_t reader_states_count;	
	DWORD timeout;
	
	Data_Get_Struct(self, struct SCardContextEx, context);
	if(context == NULL) return self;
	
	if(TYPE(rbTimeout) == T_NIL || TYPE(rbTimeout) == T_FALSE)
		timeout = INFINITE;
	else
		timeout = NUM2INT(rbTimeout);
	
	if(_PCSC_ReaderStates_lowlevel_get(rbReaderStates, &reader_states, &reader_states_count) == 0)
		rb_raise(rb_eArgError, "first parameter is not a ReaderStates instance or nil");
	else {
		context->pcsc_error = SCardGetStatusChange(context->pcsc_context, timeout, reader_states, reader_states_count);
		if(context->pcsc_error != SCARD_S_SUCCESS)
			rb_raise(rb_eRuntimeError, "SCardCancel: %s", pcsc_stringify_error(context->pcsc_error));
	}
	return self;
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
static VALUE PCSC_Context_last_error(VALUE self) {
	struct SCardContextEx *context;	
	
	Data_Get_Struct(self, struct SCardContextEx, context);
	if(context == NULL) return Qnil;

	return UINT2NUM(context->pcsc_error);
}

#ifdef MAKE_RDOC_HAPPY
	mSmartcard = rb_define_module("Smartcard");
	mPcsc = rb_define_module_under(mSmartcard, "PCSC");
#endif

/* :Document-class: Smartcard::PCSC::Context
 * Connects Ruby to the PC/SC resource manager.
 * Wraps a _SCARDCONTEXT_ structure.
 */
void Init_PCSC_Context() {
	cPcscContext = rb_define_class_under(mPcsc, "Context", rb_cObject);
	rb_define_alloc_func(cPcscContext, PCSC_Context_alloc);
	rb_define_method(cPcscContext, "initialize", PCSC_Context_initialize, 1);
	rb_define_method(cPcscContext, "release", PCSC_Context_release, 0);	
	rb_define_method(cPcscContext, "is_valid", PCSC_Context_is_valid, 0);
	rb_define_method(cPcscContext, "list_reader_groups", PCSC_Context_list_reader_groups, 0);	
	rb_define_method(cPcscContext, "list_readers", PCSC_Context_list_readers, 1);	
	rb_define_method(cPcscContext, "cancel", PCSC_Context_cancel, 0);	
	rb_define_method(cPcscContext, "get_status_change", PCSC_Context_get_status_change, 2);
	rb_define_method(cPcscContext, "last_error", PCSC_Context_last_error, 0);
}

/* Retrieves the SCARDCONTEXT wrapped into a Smartcard::PCSC::Context instance. */
int _PCSC_Context_lowlevel_get(VALUE rbContext, SCARDCONTEXT *pcsc_context) {
	struct SCardContextEx *context;	

	if(TYPE(rbContext) != T_DATA || RDATA(rbContext)->dfree != (void (*)(void *))PCSC_Context_free)
		return 0;	
	
	Data_Get_Struct(rbContext, struct SCardContextEx, context);
	*pcsc_context = context->pcsc_context;
	return 1;
}
