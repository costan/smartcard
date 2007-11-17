#include "pcsc.h"

VALUE cPcscReaderStates;

/* Wraps an array of SCARD_READERSTATE elements. */
struct PCSCReaderStates {
	size_t states_count; 
	SCARD_READERSTATE *states;
};

/* Custom free for Smartcard::PCSC::ReaderStates. Also releases the referenced buffers (for the reader names). */
static void PCSC_ReaderStates_free(struct PCSCReaderStates *_states) {
	size_t i;
	if(_states != NULL) {
		if(_states->states != NULL) {
			for(i = 0; i < _states->states_count; i++) {
				if(_states->states[i].szReader != NULL)
					xfree((char *)_states->states[i].szReader);
			}
			xfree(_states->states);
		}
		xfree(_states);
	}
}

/* Custom allocation for Smartcard::PCSC::ReaderStates. Wraps a reference to an array of SCARD_READERSTATE. */
static VALUE PCSC_ReaderStates_alloc(VALUE klass) {
	struct PCSCReaderStates *states;
	
	VALUE rbReaderStates = Data_Make_Struct(klass, struct PCSCReaderStates, NULL, PCSC_ReaderStates_free, states);
	states->states_count = 0;
	states->states = NULL;
	return rbReaderStates;
}

/* :Document-method: new
 * call-seq:
 *      new(num_states) --> reader_states
 * 
 * Creates an array of +num_states+ reader state elements.
 * The states are unusable until they are assigned reader names by calling ReaderStates#set_reader_name_of.
 */
static VALUE PCSC_ReaderStates_initialize(VALUE self, VALUE rbNumStates) {
	struct PCSCReaderStates *states;	
	size_t states_count, i;
	
	Data_Get_Struct(self, struct PCSCReaderStates, states);
	
	states_count = NUM2UINT(rbNumStates);
	if(states_count > 0) {
		states->states = ALLOC_N(SCARD_READERSTATE, states_count);
		if(states->states != NULL) {
			states->states_count = states_count;
			for(i = 0; i < states_count; i++) {
				states->states[i].szReader = NULL;
				states->states[i].dwCurrentState = SCARD_STATE_UNAWARE;
			}
		}
	}
	return self;
}

static int _validate_readerstates_args(VALUE rbReaderStates, VALUE rbIndex, struct PCSCReaderStates **states, size_t *index) {
	Data_Get_Struct(rbReaderStates, struct PCSCReaderStates, *states);
	if(*states == NULL) return 0;

	*index = NUM2UINT(rbIndex);
	if(*index >= (*states)->states_count) {
		rb_raise(rb_eIndexError, "index %u is invalid (states array has %u elements)", *index, (*states)->states_count);
		return 0;
	}
	
	return 1;
}

/* :Document-method: current_state_of
 * call-seq:
 *      current_state_of(index) --> current_state
 * 
 * The current state (_dwCurrentState_ in PC/SC) in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change blocks as long as the reader state equals this value. 
 * 
 * The returned state is a bitfield; the bits are defined in the Smartcard::PCSC::STATE_ constants. 
 * 
 * +index+:: the 0-based index of the reader state element to be queried
 */
static VALUE PCSC_ReaderStates_current_state_of(VALUE self, VALUE rbIndex) {
	struct PCSCReaderStates *states;
	size_t index;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return Qnil;
	
	return UINT2NUM(states->states[index].dwCurrentState);
}

/* :Document-method: event_state_of
 * call-seq:
 *      event_state_of(index) --> event_state
 * 
 * The event state (_dwEventState_ in PC/SC) in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change stores the updated reader state in this value. 
 * 
 * The returned state is a bitfield; the bits are defined in the Smartcard::PCSC::STATE_ constants. 
 * 
 * +index+:: the 0-based index of the reader state element to be queried
 */
static VALUE PCSC_ReaderStates_event_state_of(VALUE self, VALUE rbIndex) {
	struct PCSCReaderStates *states;
	size_t index;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return Qnil;
	
	return UINT2NUM(states->states[index].dwEventState);
}

/* :Document-method: set_current_state_of!
 * call-seq:
 *      set_current_state_of!(index, current_state) --> self 
 * 
 * Sets the current state (_dwCurrentState_ in PC/SC) in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change blocks as long as the reader state equals this value. 
 * 
 * 
 * +index+:: the 0-based index of the reader state element to be modified
 * +current_state+:: a bitfield; the bits are defined in the Smartcard::PCSC::STATE_ constants. 
 */
static VALUE PCSC_ReaderStates_set_current_state_of(VALUE self, VALUE rbIndex, VALUE rbCurrentState) {
	struct PCSCReaderStates *states;
	size_t index;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return self;

	states->states[index].dwCurrentState = NUM2UINT(rbCurrentState);
	return self;
}

/* :Document-method: set_event_state_of!
 * call-seq:
 *      set_event_state_of!(index, event_state) --> self 
 * 
 * Sets the event state (_dwEventState_ in PC/SC) in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change stores the updated reader state in this value. 
 * 
 * +index+:: the 0-based index of the reader state element to be modified
 * +event_state+:: a bitfield; the bits are defined in the Smartcard::PCSC::STATE_ constants. 
 */
static VALUE PCSC_ReaderStates_set_event_state_of(VALUE self, VALUE rbIndex, VALUE rbEventState) {
	struct PCSCReaderStates *states;
	size_t index;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return self;

	states->states[index].dwEventState = NUM2UINT(rbEventState);
	return self;
}

/* :Document-method: atr_of
 * call-seq:
 *      atr_of(index) --> atr
 * 
 * The card ATR string in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change stores the updated ATR string in this value. 
 * 
 * The returned ATR bytes are wrapped into a string. (don't complain, it's a low-level API)
 * 
 * +index+:: the 0-based index of the reader state element to be queried
 */
static VALUE PCSC_ReaderStates_atr_of(VALUE self, VALUE rbIndex) {
	struct PCSCReaderStates *states;
	size_t index;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return Qnil;
	
	return rb_str_new((char *)states->states[index].rgbAtr, states->states[index].cbAtr);
}

/* :Document-method: set_atr_of!
 * call-seq:
 *      set_atr_of!(index, atr) --> self
 * 
 * Sets the card ATR string in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change stores the updated ATR string in this value. 
 * 
 * +index+:: the 0-based index of the reader state element to be modified
 * +atr+:: ATR bytes wrapped into a string (low-level API, remember?)
 */
static VALUE PCSC_ReaderStates_set_atr_of(VALUE self, VALUE rbIndex, VALUE rbAtr) {
	struct PCSCReaderStates *states;
	size_t index;
	VALUE rbFinalAtr;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return self;
	
	rbFinalAtr = rb_check_string_type(rbAtr);
	if(NIL_P(rbFinalAtr))
		return self;

	if(RSTRING(rbFinalAtr)->len > MAX_ATR_SIZE) {
		rb_raise(rb_eArgError, "given ATR is too long (%d characters given; can do at most MAX_ATR_SIZE = %d)", RSTRING(rbFinalAtr)->len, MAX_ATR_SIZE);
		return self;		
	}
	
	states->states[index].cbAtr = RSTRING(rbAtr)->len; 
	memcpy(states->states[index].rgbAtr, RSTRING(rbAtr)->ptr, states->states[index].cbAtr);
	return self;
}

/* :Document-method: reader_name_of
 * call-seq:
 *      reader_name_of(index) --> reader_name
 * 
 * The name of the reader whose status is represented in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change reads this value, and never updates it. 
 * 
 * +index+:: the 0-based index of the reader state element to be queried
 */
static VALUE PCSC_ReaderStates_reader_name_of(VALUE self, VALUE rbIndex) {
	struct PCSCReaderStates *states;
	size_t index;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return Qnil;
	
	return rb_str_new2(states->states[index].szReader);
}

/* :Document-method: set_reader_name_of!
 * call-seq:
 *      set_reader_name_of!(index, reader_name) --> self
 * 
 * The name of the reader whose status is represented in the <tt>index</tt>th reader state element.
 * Smartcard::PCSC::Context#get_status_change reads this value, and never updates it. 
 * 
 * +index+:: the 0-based index of the reader state element to be modified
 * +reader_name+:: a string-like object containing the reader name to be associated with the state element
 */
static VALUE PCSC_ReaderStates_set_reader_name_of(VALUE self, VALUE rbIndex, VALUE rbReaderName) {
	struct PCSCReaderStates *states;
	size_t index, reader_name_length;
	VALUE rbFinalReaderName;
	
	if(_validate_readerstates_args(self, rbIndex, &states, &index) == 0)
		return self;
	
	rbFinalReaderName = rb_check_string_type(rbReaderName);
	if(NIL_P(rbFinalReaderName))
		return self;

	reader_name_length = RSTRING(rbFinalReaderName)->len;
	if(states->states[index].szReader != NULL)
		xfree((char *)states->states[index].szReader);
	states->states[index].szReader = ALLOC_N(char, reader_name_length + 1);
	if(states->states[index].szReader != NULL) {
		memcpy((char *)states->states[index].szReader, RSTRING(rbFinalReaderName)->ptr, reader_name_length);
		((char *)states->states[index].szReader)[reader_name_length] = '\0';
	}	
	return self;
}

/* :Document-method: acknowledge_events!
 * call-seq:
 *      acknowledge_events!() --> self
 * 
 * Mass-assigns +current_state+ to +event_state+ for each reader state element.
 * Useful to acknowledge all the status changed communicated after a call to Smartcard::PCSC::Context#get_status_change
 * (and thus prepare for a new call). 
 */
static VALUE PCSC_ReaderStates_acknowledge_events(VALUE self) {
	struct PCSCReaderStates *states;
	size_t i;
	
	Data_Get_Struct(self, struct PCSCReaderStates, states);
	if(states != NULL) {
		for(i = 0; i < states->states_count; i++)
			states->states[i].dwCurrentState = states->states[i].dwEventState; 
	}
	return self;
}

#ifdef MAKE_RDOC_HAPPY
	mSmartcard = rb_define_module("Smartcard");
	mPcsc = rb_define_module_under(mSmartcard, "PCSC");
#endif

/* :Document-class: Smartcard::PCSC::ReaderStates
 * Tracks reader status information, and is used in Smartcard::PCSC::Context#get_status_change.
 * Wraps an array of <i>SCARD_READERSTATE</i> structures.
 */
void Init_PCSC_ReaderStates() {
	cPcscReaderStates = rb_define_class_under(mPcsc, "ReaderStates", rb_cObject);
	rb_define_alloc_func(cPcscReaderStates, PCSC_ReaderStates_alloc);
	rb_define_method(cPcscReaderStates, "initialize", PCSC_ReaderStates_initialize, 1);	
	rb_define_method(cPcscReaderStates, "current_state_of", PCSC_ReaderStates_current_state_of, 1);	
	rb_define_method(cPcscReaderStates, "set_current_state_of!", PCSC_ReaderStates_set_current_state_of, 2);	
	rb_define_method(cPcscReaderStates, "event_state_of", PCSC_ReaderStates_event_state_of, 1);	
	rb_define_method(cPcscReaderStates, "set_event_state_of!", PCSC_ReaderStates_set_event_state_of, 2);	
	rb_define_method(cPcscReaderStates, "reader_name_of", PCSC_ReaderStates_reader_name_of, 1);	
	rb_define_method(cPcscReaderStates, "set_reader_name_of!", PCSC_ReaderStates_set_reader_name_of, 2);	
	rb_define_method(cPcscReaderStates, "atr_of", PCSC_ReaderStates_atr_of, 1);	
	rb_define_method(cPcscReaderStates, "set_atr_of!", PCSC_ReaderStates_set_atr_of, 2);	
	rb_define_method(cPcscReaderStates, "acknowledge_events!", PCSC_ReaderStates_acknowledge_events, 0);	
}

/* Retrieves the SCARD_READERSTATE array wrapped into a Smartcard::PCSC::ReaderStates instance. */
int _PCSC_ReaderStates_lowlevel_get(VALUE rbReaderStates, SCARD_READERSTATE **reader_states, size_t *reader_states_count) {
	struct PCSCReaderStates *states;	

	if(TYPE(rbReaderStates) == T_NIL || TYPE(rbReaderStates) == T_FALSE) {
		*reader_states = NULL;
		*reader_states_count = 0;
		return 1;
	}
	if(TYPE(rbReaderStates) != T_DATA || RDATA(rbReaderStates)->dfree != (void (*)(void *))PCSC_ReaderStates_free)
		return 0;
	
	Data_Get_Struct(rbReaderStates, struct PCSCReaderStates, states);
	*reader_states = states->states;
	*reader_states_count = states->states_count;
	return 1;
}
