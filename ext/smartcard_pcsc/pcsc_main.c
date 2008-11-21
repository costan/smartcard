#include "pcsc.h"

void Init_pcsc() {
	Init_PCSC_Namespace();
	Init_PCSC_ReaderStates();
	Init_PCSC_IoRequest();
	Init_PCSC_Context();
	Init_PCSC_Card();
	Init_PCSC_Consts();
	Init_PCSC_Exception();
}
