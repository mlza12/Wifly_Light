/**
		Copyright (C) 2012 Nils Weiss, Patrick Brünn.

    This file is part of Wifly_Light.

    Wifly_Light is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Wifly_Light is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Wifly_Light.  If not, see <http://www.gnu.org/licenses/>. */

#include "WiflyControlCli.h"
#include <iostream>

using namespace std;

WiflyControlCli::WiflyControlCli(void)
: mRunning(true)
{
}

void WiflyControlCli::run(void)
{
	string nextCmd;
	cout << "Usage:" << endl;
	cout << "'exit' - terminate cli" << endl;
	cout << "'setcolor <addr> <rgb>'" << endl;
	cout << "    <addr> hex bitmask, which leds should be set to the new color" << endl;
	cout << "    <rgb> hex rgb value of the new color f.e. red: ff0000" << endl;
	cout << "'setfade <addr> <rgb> <time>'" << endl;
	cout << "    <addr> hex bitmask, which leds should be set to the new color" << endl;
	cout << "    <rgb> hex rgb value of the new color f.e. red: ff0000" << endl;
	cout << "    <time> the number of milliseconds the fade should take" << endl;
	while(mRunning)
	{
		cout << "WiflyControlCli: ";
		cin >> nextCmd;

		if("exit" == nextCmd) {
			return;
		}
		if ("setcolor" == nextCmd) {
			string addr, color;
			cin >> addr;
			cin >> color;
			mControl.SetColor(addr, color);
		}	else if ("setfade" == nextCmd) {
			string addr, color;
			unsigned long timevalue;
			cin >> addr;
			cin >> color;
			cin >> timevalue;
			mControl.SetFade(addr, color, (unsigned short)timevalue * 1000);
		}	else if ("addcolor" == nextCmd) {
			string addr, color;
			unsigned long hour, minute, second;
			cin >> addr;
			cin >> color;
			cin >> hour;
			cin >> minute;
			cin >> second;
			cout << addr << " " << color << " " << hour << " " << minute << " " << second << endl; 
			mControl.AddColor(addr, color, hour, minute, second);
		}
	}
}

#ifdef ANDROID
#include <jni.h>
extern "C" {
void Java_biz_bruenn_WiflyLight_WiflyLightActivity_runClient(JNIEnv* env, jobject ref)
{
	WiflyControl control;
	colorLoop(control);
}
}
#endif

int main(int argc, const char* argv[])
{
	WiflyControlCli cli;
	cli.run();
	return 0;
}
