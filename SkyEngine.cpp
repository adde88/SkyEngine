#include <iostream>
#include <string>
#include <Windows.h>
#include "Memory.h"

int main()
{	
	SetConsoleTitle(L"SkyEngine");
	printf("Developed by - WiNiFiX#0204 (Jul 2019)\n");

	Memory memory;
	if (memory.GetProcess("Wow.exe"))
	{
		printf("WoW Process Id       : %i\n", memory.TargetId);

		auto mod = memory.GetModule("Wow.exe");
		printf("WoW Base Address     : 0x%llX\n", mod.BaseAddress);

		auto address = memory.FindSignature(mod.BaseAddress, mod.Size, "\x4C\x8B\x0D\x00\x00\x00\x00\x45\x33\xC0\x48\x8B\xCE", "xxx????xxxxxx");
		printf("WoW Sig Address      : 0x%llX\n", address);

	    auto TaintedAddress = address + memory.ReadMemory<DWORD>(address + 0x3) + 0x7;
		printf("Lua_TaintedPtrOffset : 0x%llX\n", TaintedAddress - mod.BaseAddress);  // will be values close to: 0x2CB8B88; //0x2C93B48; //0x2C94BA8;	

		DWORD_PTR lastLuaTaintedPtr = 0;
		long count = 0;

		printf("Lua is now unlocked...\n");

		while (true)
		{
			memory.WriteMemory<DWORD_PTR>(TaintedAddress, 0);
			Sleep(1);
		}
	}

	printf("Please launch wow then re-open this unlocker\n");

	for (auto c = 5; c > 0; c--)
	{
		printf("Closing in %i\n", c);
		Sleep(1000);
	}
}
