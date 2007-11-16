#include "pcsc.h"

VALUE mSmartcard;
VALUE mPcsc;

/* :Document-class: Smartcard::PCSC
 * Bindings to the PC/SC Smartcard API.
 * 
 */
static void Init_PCSC() {
	mPcsc = rb_define_module_under(mSmartcard, "PCSC");
}

void Init_PCSC_Namespace() {
	mSmartcard = rb_define_module("Smartcard");
	Init_PCSC();
}

