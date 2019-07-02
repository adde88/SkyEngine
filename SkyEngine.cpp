#include <iostream>
#include <string>

#include <Windows.h>
//#include "Console.h"
#include "Memory.h"

int main()
{
	//Console.Initialize("Skeleton Key", 1000, 600);
	//Console.Log("Developed by - Skyflakes#4006 (August 2018)\n", Color.Green);

	Memory memory;
	if (memory.GetProcess("Wow.exe"))
	{
		printf("WoW Process Id       : %i\n", memory.TargetId);
		auto mod = memory.GetModule("Wow.exe");

		printf("WoW Module Id        : %i\n", mod.BaseAddress);

		auto address = memory.FindSignature(mod.BaseAddress, mod.Size, "\x4C\x8B\x0D\x00\x00\x00\x00\x45\x33\xC0\x48\x8B\xCE", "xxx????xxxxxx");
	    auto TaintedAddress = address + memory.ReadMemory<DWORD>(address + 0x3) + 0x7;
		printf("Lua_TaintedPtrOffset         : 0x%X\n", TaintedAddress - mod.BaseAddress);  // will be values close to: 0x2CB8B88; //0x2C93B48; //0x2C94BA8;	

	//	auto address2 = memory.FindSignature(mod.BaseAddress, mod.Size, "\x48\x89\x7C\x24\x20\x41\x56\x48\x83\xEC\x70\x00\x00\x00\x00\x00\x00\x00\x48\x8B\xEA", "xxxxxxxxxxx???????xxx");
	//	auto FrameScript_Execute = address2 - 0xF;
	//	printf("FrameScript_Execute          : 0x%lX\n", FrameScript_Execute - mod.BaseAddress);

	//	auto address3 = memory.FindSignature(mod.BaseAddress, mod.Size, "\x48\x8B\x05\x00\x00\x00\x00\x48\x8B\xDF\xE9\x00\x00\x00\x00\x48\x8B\x7C\x24\x20", "xxx????xxxx????xxxxx");
	//	auto EntityListAddress = address3 + memory.ReadMemory<DWORD>(address3 + 0x3) + 0x7;
	//	printf("EntityList                   : 0x%X\n", EntityListAddress - mod.BaseAddress);

	//	auto address4 = memory.FindSignature(mod.BaseAddress, mod.Size, "\x44\x89\x05\x00\x00\x00\x00\x48\x8B\x82\x00", "xxx????xxx?");
	//	auto LastHardwareAction = address4 + memory.ReadMemory<DWORD>(address4 + 0x3) + 0x7;
	//	printf("LastHardwareAction           : 0x%X\n", LastHardwareAction - mod.BaseAddress);

	//	auto address5 = memory.FindSignature(mod.BaseAddress, mod.Size, "\x48\x8B\x0D\x00\x00\x00\x00\x48\x8B\x74\x24\x48\x48", "xxx????xxxxxx");
	//	auto CameraBase = address5 + memory.ReadMemory<DWORD>(address5 + 0x3) + 0x7;
	//	printf("CameraBase                   : 0x%X\n", CameraBase - mod.BaseAddress);

	//	auto address6 = memory.FindSignature(mod.BaseAddress, mod.Size, "\x48\x8D\x05\x00\x00\x00\x00\xBA\x00\x00\x00\x00\x48\x83\xC8\x01\x48\x8D\x0D\x00\x00\x00\x00\x48\x89\x05\x00\x00\x00\x00\xE8\x00\x00\x00\x00\x33\xC9", "xxx????x????xxxxxxx????xxx????x????xx");
	//	auto NameCacheBase = address6 + memory.ReadMemory<DWORD>(address6 + 0x3) + 0x7;
	//	printf("NameCacheBase                : 0x%X\n", NameCacheBase - mod.BaseAddress);

	//	auto address7 = memory.FindSignature(mod.BaseAddress, mod.Size, "\xE8\x00\x00\x00\x00\x48\x8B\x94\x24\x00\x00\x00\x00\x48\x85\xD2\x74\x2F", "x????xxxx????xxxxx");
	//	auto FrameScript_GetLocalizedText = address7 + memory.ReadMemory<DWORD>(address7 + 0x1) + 0x5;
	//	printf("FrameScript_GetLocalizedText : 0x%X\n", FrameScript_GetLocalizedText - mod.BaseAddress);

	system("pause");

	//	DWORD_PTR lastLuaTaintedPtr = 0;
	//	long count = 0;

	//	while (true)
	//	{
	//		auto luaTaintedPtr = memory.ReadMemory<DWORD_PTR>(TaintedAddress);
	//		if (luaTaintedPtr) // If luaTaintedPtr is pointing so a valid address (not 0)
	//		{
	//			count++;
	//			if (luaTaintedPtr != lastLuaTaintedPtr)
	//			{
	//				printf("Securing Address     : 0x%llX\n", luaTaintedPtr);
	//				lastLuaTaintedPtr = luaTaintedPtr;
	//				count = 1;
	//			}
	//			if (count % 50 == 0)
	//			{
	//				printf("Address has been secured %i times.\n", count);
	//			}
	//			memory.WriteMemory<DWORD_PTR>(TaintedAddress, 0);
	//		}
	//	}
	}

	printf("Please launch wow then re-open this unlocker\n");

	for (auto c = 5; c > 0; c--)
	{
		printf("Closing in %i\n", c);
		Sleep(1000);
	}
}

