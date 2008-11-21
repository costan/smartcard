#include <string.h>
#include "pcsc.h"

/* Converts a multi-string "str1\0str_2\0str3\0\0" into a Ruby array of Ruby strings. */
VALUE PCSC_Internal_multistring_to_ruby_array(char *mstr, size_t mstr_len) {
	VALUE rbArray, rbString;
	size_t i, start_offset;
	
	rbArray = rb_ary_new();
	for(i = 0; i < mstr_len; i++) {
		if(mstr[i] == '\0') break;
		start_offset = i;
		for(; i < mstr_len; i++)
			if(mstr[i] == '\0') break;
		rbString = rb_str_new(mstr + start_offset, i - start_offset);
		rb_ary_push(rbArray, rbString);
	}
	return rbArray;
}

/* Constructs a multi-string "str1\0str_2\0str3\0\0". Takes nil, a string, or an array of strings.
 * The returned buffer must be released with xfree.
 * If false is returned, something went wrong and the method did not return a buffer. 
 */
int PCSC_Internal_ruby_strings_to_multistring(VALUE rbStrings, char **strings) {
	VALUE *array_elements;
	char *buffer;
	size_t string_length, array_length, buffer_length, i;
	
	/* nil -> NULL */ 
	if(TYPE(rbStrings) == T_NIL || TYPE(rbStrings) == T_FALSE) {
		*strings = NULL;
		return 1;
	}
	/* string -> [string] */
	if(TYPE(rbStrings) == T_STRING) {
		string_length = RSTRING(rbStrings)->len; 
		buffer = ALLOC_N(char, string_length + 2);
		memcpy(buffer, RSTRING(rbStrings)->ptr, string_length);
		buffer[string_length] = buffer[string_length + 1] = '\0';
		*strings = buffer;
		return 1;
	}
	/* array -> array */
	if(TYPE(rbStrings) == T_ARRAY) {
		/* compute buffer length */
		array_length = RARRAY(rbStrings)->len;
		array_elements = RARRAY(rbStrings)->ptr;
		buffer_length = 1; /* for the trailing '\0' */
		for(i = 0; i < array_length; i++) {
			if(TYPE(array_elements[i]) != T_STRING)
				return 0;
			buffer_length += RSTRING(array_elements[i])->len + 1; 
		}
		
		/* concatenate strings into buffer */
		buffer = ALLOC_N(char, buffer_length);
		for(buffer_length = 0, i = 0; i < array_length; i++) {
			string_length = RSTRING(array_elements[i])->len;
			memcpy(buffer + buffer_length, RSTRING(array_elements[i])->ptr, string_length);
			buffer[buffer_length] = '\0';
			buffer_length += string_length + 1;
		}
		buffer[buffer_length] = '\0';
		*strings = buffer;
		return 1;
	}
	
	return 0;
}
