; OS-style code that runs in shadow mode
;
; This includes the markers necessary to relocate it from normal memory to shadow memory
;
; It lives at $f800, like the Tube's OS does, provides the CPU's interrupt and reset 
; vectors when in shadow mode, and also owns $0090-$00ff and $0200-$03ff.

shadow_os_source_start:

shadow_os_low_source:
	*=$f800
shadow_os_low_dest:

.(

#include "shadow/shadow_constants.s"
#include "shadow/shadow_command.s"
#include "shadow/shadow_init.s"
#include "shadow/shadow_interrupts.s"
#include "shadow/shadow_commands_simple.s"
#include "shadow/shadow_osword.s"
#include "shadow/copytonormal.s"
#include "common/utils.s"
;#include "shadow/shadow_test.s"
#include "shadow/shadow_oscli.s"
#include "shadow/shadow_osfile.s"
#include "shadow/shadow_osfind.s"
#include "shadow/shadow_osargs.s"
#include "shadow/shadow_osgbpb.s"
#include "shadow/shadow_event.s"
#include "shadow/shadow_entercode.s"

&shadow_os_low_end:
&shadow_os_low_size = * - shadow_os_low_dest
* = shadow_os_low_source + shadow_os_low_size

&shadow_os_high_source:
	* = $ff00
&shadow_os_high_dest:

#include "shadow/shadow_osbyte.s"
#include "shadow/shadow_utils.s"

; The vectors file must be last
#include "shadow/shadow_vectors.s"

.)

shadow_os_high_end:
shadow_os_high_size = *-shadow_os_high_dest
* = shadow_os_high_source + shadow_os_high_size

shadow_os_source_end:

