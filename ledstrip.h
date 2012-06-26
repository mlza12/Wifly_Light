#ifndef _LEDSTRIP_H_
#define _LEDSTRIP_H_

//Nils Wei� 
//20.04.2012
//Compiler CC5x

#include "commandstorage.h"
#include "spi.h"
#include "eeprom.h"

#define NUM_OF_LED 32

struct LedBuffer{
	uns8 led_array[NUM_OF_LED*3];			// contains the current colorvalue for each led
	uns8 led_destination[NUM_OF_LED*3];  	// contains the destination colorvalue for fade operations for each led 
	uns8 led_changevalue[NUM_OF_LED*3]; 	// contains the steps for dec or inc by fadeoperations REASON: if you change the color for one LED you have different ranges for RED, GREEN and BLUE
											// if you change all colors with the same steps ( always inc 1 oder dec 1) one LED reaches the destination value faster than a other led and the
											// mixed color during the fade operation is not so nice
	char led_fade_operation:1;
	char led_run_operation:1;
	};

extern struct LedBuffer gLedBuf;

void ledstrip_init(void);
void ledstrip_set_color(struct cmd_set_color *pCmd);
void ledstrip_set_fade(struct cmd_set_fade *pCmd);
void ledstrip_do_fade();
#endif
