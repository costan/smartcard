#include "pcsc.h"

#ifdef MAKE_RDOC_HAPPY
	mSmartcard = rb_define_module("Smartcard");
	mPcsc = rb_define_module_under(mSmartcard, "PCSC");
#endif

void Init_PCSC_Consts() {
	/* MAX_ATR_SIZE : Maximum ATR size. */
	rb_define_const(mPcsc, "MAX_ATR_SIZE", INT2NUM(MAX_ATR_SIZE));

 	/* SCARD_S_SUCCESS : All is good. */
	rb_define_const(mPcsc, "SCARD_S_SUCCESS", INT2NUM(SCARD_S_SUCCESS));
 	/* SCARD_F_INTERNAL_ERROR : An internal consistency check failed. */
	rb_define_const(mPcsc, "SCARD_F_INTERNAL_ERROR", INT2NUM(SCARD_F_INTERNAL_ERROR));
 	/* SCARD_E_CANCELLED : The action was cancelled by an SCardCancel request. */
	rb_define_const(mPcsc, "SCARD_E_CANCELLED", INT2NUM(SCARD_E_CANCELLED));
	/* SCARD_E_INVALID_HANDLE : The supplied handle was invalid. */
	rb_define_const(mPcsc, "SCARD_E_INVALID_HANDLE", INT2NUM(SCARD_E_INVALID_HANDLE));
	/* MAX_ATR_SIZE : One or more of the supplied parameters could not be properly interpreted. */
	rb_define_const(mPcsc, "SCARD_E_INVALID_PARAMETER", INT2NUM(MAX_ATR_SIZE));
	/* SCARD_E_INVALID_TARGET : Registry startup information is missing or invalid. */
	rb_define_const(mPcsc, "SCARD_E_INVALID_TARGET", INT2NUM(SCARD_E_INVALID_TARGET));
	/* SCARD_E_NO_MEMORY : Not enough memory available to complete this command. */
	rb_define_const(mPcsc, "SCARD_E_NO_MEMORY", INT2NUM(SCARD_E_NO_MEMORY));
	/* SCARD_F_WAITED_TOO_LONG : An internal consistency timer has expired. */
	rb_define_const(mPcsc, "SCARD_F_WAITED_TOO_LONG", INT2NUM(SCARD_F_WAITED_TOO_LONG));
	/* SCARD_E_INSUFFICIENT_BUFFER : The data buffer to receive returned data is too small for the returned data. */
	rb_define_const(mPcsc, "SCARD_E_INSUFFICIENT_BUFFER", INT2NUM(SCARD_E_INSUFFICIENT_BUFFER));
	/* SCARD_E_UNKNOWN_READER : The specified reader name is not recognized. */
	rb_define_const(mPcsc, "SCARD_E_UNKNOWN_READER", INT2NUM(SCARD_E_UNKNOWN_READER));
	/* SCARD_E_SHARING_VIOLATION : The user-specified timeout value has expired. */
	rb_define_const(mPcsc, "SCARD_E_SHARING_VIOLATION", INT2NUM(SCARD_E_SHARING_VIOLATION));
	/* SCARD_E_NO_SMARTCARD : The smart card cannot be accessed because of other connections outstanding. */
	rb_define_const(mPcsc, "SCARD_E_NO_SMARTCARD", INT2NUM(SCARD_E_NO_SMARTCARD));
	/* SCARD_E_TIMEOUT : The operation requires a Smart Card, but no Smart Card is currently in the device. */
	rb_define_const(mPcsc, "SCARD_E_TIMEOUT", INT2NUM(SCARD_E_TIMEOUT));
	/* SCARD_E_UNKNOWN_CARD : The specified smart card name is not recognized. */
	rb_define_const(mPcsc, "SCARD_E_UNKNOWN_CARD", INT2NUM(SCARD_E_UNKNOWN_CARD));
	/* SCARD_E_CANT_DISPOSE : The system could not dispose of the media in the requested manner. */
	rb_define_const(mPcsc, "SCARD_E_CANT_DISPOSE", INT2NUM(SCARD_E_CANT_DISPOSE));
	/* SCARD_E_PROTO_MISMATCH : The requested protocols are incompatible with the protocol currently in use with the smart card. */
	rb_define_const(mPcsc, "SCARD_E_PROTO_MISMATCH", INT2NUM(SCARD_E_PROTO_MISMATCH));
	/* SCARD_E_NOT_READY : The reader or smart card is not ready to accept commands. */
	rb_define_const(mPcsc, "SCARD_E_NOT_READY", INT2NUM(SCARD_E_NOT_READY));
	/* SCARD_E_INVALID_VALUE : One or more of the supplied parameters values could not be properly interpreted. */
	rb_define_const(mPcsc, "SCARD_E_INVALID_VALUE", INT2NUM(SCARD_E_INVALID_VALUE));
	/* SCARD_E_SYSTEM_CANCELLED : The action was cancelled by the system, presumably to log off or shut down. */
	rb_define_const(mPcsc, "SCARD_E_SYSTEM_CANCELLED", INT2NUM(SCARD_E_SYSTEM_CANCELLED));
	/* SCARD_F_COMM_ERROR : An internal communications error has been detected. */
	rb_define_const(mPcsc, "SCARD_F_COMM_ERROR", INT2NUM(SCARD_F_COMM_ERROR));
	/* SCARD_F_UNKNOWN_ERROR : An internal error has been detected, but the source is unknown. */
	rb_define_const(mPcsc, "SCARD_F_UNKNOWN_ERROR", INT2NUM(SCARD_F_UNKNOWN_ERROR));
	/* SCARD_E_INVALID_ATR : An ATR obtained from the registry is not a valid ATR string. */
	rb_define_const(mPcsc, "SCARD_E_INVALID_ATR", INT2NUM(SCARD_E_INVALID_ATR));
	/* SCARD_E_NOT_TRANSACTED : An attempt was made to end a non-existent transaction. */
	rb_define_const(mPcsc, "SCARD_E_NOT_TRANSACTED", INT2NUM(SCARD_E_NOT_TRANSACTED));
	/* SCARD_E_READER_UNAVAILABLE : The specified reader is not currently available for use. */
	rb_define_const(mPcsc, "SCARD_E_READER_UNAVAILABLE", INT2NUM(SCARD_E_READER_UNAVAILABLE));
	/* SCARD_W_UNSUPPORTED_CARD : The reader cannot communicate with the card, due to ATR string configuration conflicts. */
	rb_define_const(mPcsc, "SCARD_W_UNSUPPORTED_CARD", INT2NUM(SCARD_W_UNSUPPORTED_CARD));
	/* SCARD_W_UNRESPONSIVE_CARD : The smart card is not responding to a reset. */
	rb_define_const(mPcsc, "SCARD_W_UNRESPONSIVE_CARD", INT2NUM(SCARD_W_UNRESPONSIVE_CARD));
	/* SCARD_W_UNPOWERED_CARD : Power has been removed from the smart card, so that further communication is not possible. */
	rb_define_const(mPcsc, "SCARD_W_UNPOWERED_CARD", INT2NUM(SCARD_W_UNPOWERED_CARD));
	/* SCARD_W_RESET_CARD : The smart card has been reset, so any shared state information is invalid. */
	rb_define_const(mPcsc, "SCARD_W_RESET_CARD", INT2NUM(SCARD_W_RESET_CARD));
	/* SCARD_W_REMOVED_CARD : The smart card has been removed, so further communication is not possible. */
	rb_define_const(mPcsc, "SCARD_W_REMOVED_CARD", INT2NUM(SCARD_W_REMOVED_CARD));
	/* SCARD_E_PCI_TOO_SMALL : The PCI Receive buffer was too small. */
	rb_define_const(mPcsc, "SCARD_E_PCI_TOO_SMALL", INT2NUM(SCARD_E_PCI_TOO_SMALL));
	/* SCARD_E_READER_UNSUPPORTED : The reader driver does not meet minimal requirements for support. */
	rb_define_const(mPcsc, "SCARD_E_READER_UNSUPPORTED", INT2NUM(SCARD_E_READER_UNSUPPORTED));
	/* SCARD_E_DUPLICATE_READER : The reader driver did not produce a unique reader name. */
	rb_define_const(mPcsc, "SCARD_E_DUPLICATE_READER", INT2NUM(SCARD_E_DUPLICATE_READER));
	/* SCARD_E_CARD_UNSUPPORTED : The smart card does not meet minimal requirements for support. */
	rb_define_const(mPcsc, "SCARD_E_CARD_UNSUPPORTED", INT2NUM(SCARD_E_CARD_UNSUPPORTED));
	/* SCARD_E_NO_SERVICE : The Smart card resource manager is not running. */
	rb_define_const(mPcsc, "SCARD_E_NO_SERVICE", INT2NUM(SCARD_E_NO_SERVICE));
	/* SCARD_E_SERVICE_STOPPED : The Smart card resource manager has shut down. */
	rb_define_const(mPcsc, "SCARD_E_SERVICE_STOPPED", INT2NUM(SCARD_E_SERVICE_STOPPED));
#if defined(SCARD_E_NO_READERS_AVAILABLE)
	/* SCARD_E_NO_READERS_AVAILABLE : Cannot find a smart card reader. */
	rb_define_const(mPcsc, "SCARD_E_NO_READERS_AVAILABLE", INT2NUM(SCARD_E_NO_READERS_AVAILABLE));
#endif /* SCARD_E_NO_READERS_AVAILABLE */
		
	/* SCARD_SCOPE_USER : Scope in user space. */
	rb_define_const(mPcsc, "SCOPE_USER", INT2NUM(SCARD_SCOPE_USER));
	/* SCARD_SCOPE_TERMINAL : Scope in terminal. */
	rb_define_const(mPcsc, "SCOPE_TERMINAL", INT2NUM(SCARD_SCOPE_TERMINAL));
	/* SCARD_SCOPE_SYSTEM : Scope in system. */
	rb_define_const(mPcsc, "SCOPE_SYSTEM", INT2NUM(SCARD_SCOPE_SYSTEM));
	
	/* SCARD_STATE_UNAWARE : App wants status. */
	rb_define_const(mPcsc, "STATE_UNAWARE", INT2NUM(SCARD_STATE_UNAWARE));
	/* SCARD_STATE_IGNORE : Ignore this reader. */
	rb_define_const(mPcsc, "STATE_IGNORE", INT2NUM(SCARD_STATE_IGNORE));
	/* SCARD_STATE_CHANGED : State has changed. */
	rb_define_const(mPcsc, "STATE_CHANGED", INT2NUM(SCARD_STATE_CHANGED));
	/* SCARD_STATE_UNKNOWN : Reader unknown. */
	rb_define_const(mPcsc, "STATE_UNKNOWN", INT2NUM(SCARD_STATE_UNKNOWN));
	/* SCARD_STATE_UNAVAILABLE : Status unavailable. */
	rb_define_const(mPcsc, "STATE_UNAVAILABLE", INT2NUM(SCARD_STATE_UNAVAILABLE));
	/* SCARD_STATE_EMPTY : Card removed. */
	rb_define_const(mPcsc, "STATE_EMPTY", INT2NUM(SCARD_STATE_EMPTY));
	/* SCARD_STATE_PRESENT : Card inserted. */
	rb_define_const(mPcsc, "STATE_PRESENT", INT2NUM(SCARD_STATE_PRESENT));
	/* SCARD_STATE_ATRMATCH : ATR matches card. */
	rb_define_const(mPcsc, "STATE_ATRMATCH", INT2NUM(SCARD_STATE_ATRMATCH));
	/* SCARD_STATE_EXCLUSIVE : Exclusive Mode. */
	rb_define_const(mPcsc, "STATE_EXCLUSIVE", INT2NUM(SCARD_STATE_EXCLUSIVE));
	/* SCARD_STATE_INUSE : Shared Mode. */
	rb_define_const(mPcsc, "STATE_INUSE", INT2NUM(SCARD_STATE_INUSE));
	/* SCARD_STATE_MUTE : Unresponsive card. */
	rb_define_const(mPcsc, "STATE_MUTE", INT2NUM(SCARD_STATE_MUTE));
#if defined(SCARD_STATE_UNPOWERED)
	/* SCARD_STATE_UNPOWERED : Unpowered card. */
	rb_define_const(mPcsc, "STATE_UNPOWERED", INT2NUM(SCARD_STATE_UNPOWERED));
#endif /* SCARD_STATE_UNPOWERED */
	
	/* INFINITE : Infinite timeout. */
	rb_define_const(mPcsc, "INFINITE_TIMEOUT", INT2NUM(INFINITE));
	
	
	/* SCARD_UNKNOWNU : Card is absent. */
	rb_define_const(mPcsc, "STATUS_ABSENT", INT2NUM(SCARD_ABSENT));
	/* SCARD_PRESENT : Card is present. */
	rb_define_const(mPcsc, "STATUS_PRESENT", INT2NUM(SCARD_PRESENT));
	/* SCARD_SWALLOWED : Card not powered. */
	rb_define_const(mPcsc, "STATUS_SWALLOWED", INT2NUM(SCARD_SWALLOWED));
	/* SCARD_POWERED : Card is powered. */
	rb_define_const(mPcsc, "STATUS_POWERED", INT2NUM(SCARD_POWERED));
	/* SCARD_NEGOTIABLE : Ready for PTS. */
	rb_define_const(mPcsc, "STATUS_NEGOTIABLE", INT2NUM(SCARD_NEGOTIABLE));
	/* SCARD_SPECIFIC : PTS has been set. */
	rb_define_const(mPcsc, "STATUS_SPECIFIC", INT2NUM(SCARD_SPECIFIC));
	
#if defined(SCARD_PROTOCOL_UNSET)
	/* SCARD_PROTOCOL_UNSET : Protocol not set. */
	rb_define_const(mPcsc, "PROTOCOL_UNSET", INT2NUM(SCARD_PROTOCOL_UNSET));
#endif /* SCARD_PROTOCOL_UNSET */
	/* SCARD_PROTOCOL_T0 : T=0 active protocol. */
	rb_define_const(mPcsc, "PROTOCOL_T0", INT2NUM(SCARD_PROTOCOL_T0));
	/* SCARD_PROTOCOL_T1 : T=1 active protocol. */
	rb_define_const(mPcsc, "PROTOCOL_T1", INT2NUM(SCARD_PROTOCOL_T1));
	/* SCARD_PROTOCOL_RAW : Raw active protocol. */
	rb_define_const(mPcsc, "PROTOCOL_RAW", INT2NUM(SCARD_PROTOCOL_RAW));
#if defined(SCARD_PROTOCOL_UNSET)
	/* SCARD_PROTOCOL_T15 : T=15 protocol. */
	rb_define_const(mPcsc, "PROTOCOL_T15", INT2NUM(SCARD_PROTOCOL_T15));
#endif /* SCARD_PROTOCOL_UNSET */
	/* SCARD_PROTOCOL_ANY : IFD determines protocol. */
	rb_define_const(mPcsc, "PROTOCOL_ANY", INT2NUM(SCARD_PROTOCOL_ANY));

	/* SCARD_SHARE_EXCLUSIVE : Exclusive mode only. */
	rb_define_const(mPcsc, "SHARE_EXCLUSIVE", INT2NUM(SCARD_SHARE_EXCLUSIVE));
	/* SCARD_SHARE_SHARED : Shared mode only. */
	rb_define_const(mPcsc, "SHARE_SHARED", INT2NUM(SCARD_SHARE_SHARED));
	/* SCARD_SHARE_DIRECT : Raw mode only. */
	rb_define_const(mPcsc, "SHARE_DIRECT", INT2NUM(SCARD_SHARE_DIRECT));

	/* SCARD_LEAVE_CARD : Do nothing on close. */
	rb_define_const(mPcsc, "DISPOSITION_LEAVE", INT2NUM(SCARD_LEAVE_CARD));
	/* SCARD_RESET_CARD : Reset on close. */
	rb_define_const(mPcsc, "DISPOSITION_RESET", INT2NUM(SCARD_RESET_CARD));
	/* SCARD_UNPOWER_CARD : Power down on close. */
	rb_define_const(mPcsc, "DISPOSITION_UNPOWER", INT2NUM(SCARD_UNPOWER_CARD));
	/* SCARD_EJECT_CARD : Eject on close. */
	rb_define_const(mPcsc, "DISPOSITION_EJECT", INT2NUM(SCARD_EJECT_CARD));

	/* SCARD_LEAVE_CARD : Do nothing. */
	rb_define_const(mPcsc, "INITIALIZATION_LEAVE", INT2NUM(SCARD_LEAVE_CARD));
	/* SCARD_RESET_CARD : Reset the card (warm reset). */
	rb_define_const(mPcsc, "INITIALIZATION_RESET", INT2NUM(SCARD_RESET_CARD));
	/* SCARD_UNPOWER_CARD : Power down the card (cold reset). */
	rb_define_const(mPcsc, "INITIALIZATION_UNPOWER", INT2NUM(SCARD_UNPOWER_CARD));
	/* SCARD_EJECT_CARD : Eject the card. */
	rb_define_const(mPcsc, "INITIALIZATION_EJECT", INT2NUM(SCARD_EJECT_CARD));
	
	/* SCARD_ATTR_ATR_STRING : ATR of the card. */
	rb_define_const(mPcsc, "ATTR_ATR_STRING", INT2NUM(SCARD_ATTR_ATR_STRING));
	/* SCARD_ATTR_VENDOR_IFD_VERSION : Vendor-supplied interface driver version. */
	rb_define_const(mPcsc, "ATTR_VENDOR_IFD_VERSION", INT2NUM(SCARD_ATTR_VENDOR_IFD_VERSION));
	/* SCARD_ATTR_VENDOR_NAME : Name of the interface driver version. */
	rb_define_const(mPcsc, "ATTR_VENDOR_NAME", INT2NUM(SCARD_ATTR_VENDOR_NAME));
	/* SCARD_ATTR_MAXINPUT : Maximum size of an APDU supported by the reader. */
	rb_define_const(mPcsc, "ATTR_MAXINPUT", INT2NUM(SCARD_ATTR_MAXINPUT));	
	
	/* SCARD_PCI_T0 : IoRequest for transmitting using the T=0 protocol. */
	rb_define_const(mPcsc, "IOREQUEST_T0", _PCSC_IoRequest_lowlevel_new(SCARD_PCI_T0));
	/* SCARD_PCI_T1 : IoRequest for transmitting using the T=1 protocol. */
	rb_define_const(mPcsc, "IOREQUEST_T1", _PCSC_IoRequest_lowlevel_new(SCARD_PCI_T1));
	/* SCARD_PCI_RAW : IoRequest for transmitting using the RAW protocol. */
	rb_define_const(mPcsc, "IOREQUEST_RAW", _PCSC_IoRequest_lowlevel_new(SCARD_PCI_RAW));
}
