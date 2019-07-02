#pragma once
#include <iostream>
#include <string>
#include <Windows.h>
#include <TlHelp32.h>

using std::cout;
using std::endl;
using std::string;

// datatype for a module in memory (dll, regular exe) 
struct module
{
	DWORD_PTR BaseAddress;
	DWORD Size;
};

class Memory
{
public:
	module TargetModule;  // Hold target module
	HANDLE TargetProcess; // for target process
	DWORD  TargetId;      // for target process

	// For getting a handle to a process
	HANDLE GetProcess(const char* processName)
	{		
		WCHAR wProcessName[MAX_PATH] = { 0 };
		mbstowcs(wProcessName, processName, strlen(processName));

		HANDLE handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
		PROCESSENTRY32 entry;
		entry.dwSize = sizeof(entry);
		
		do
			if (!_wcsicmp(entry.szExeFile, wProcessName)) {
				TargetId = entry.th32ProcessID;
				CloseHandle(handle);
				TargetProcess = OpenProcess(PROCESS_ALL_ACCESS, false, TargetId);
				return TargetProcess;
			}
		while (Process32Next(handle, &entry));

		return false;
	}

	// For getting information about the executing module
	module GetModule(const char* moduleName) {
		WCHAR wModuleName[MAX_PATH] = { 0 };
		mbstowcs(wModuleName, moduleName, strlen(moduleName));

		HANDLE hmodule = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, TargetId);
		MODULEENTRY32 mEntry;
		mEntry.dwSize = sizeof(mEntry);

		do 
		{
			if (!_wcsicmp(mEntry.szModule, wModuleName)) {
				CloseHandle(hmodule);

				TargetModule = { (DWORD_PTR)mEntry.hModule, mEntry.modBaseSize };
				return TargetModule;
			}
		} while (Module32Next(hmodule, &mEntry));

		module mod = { (DWORD_PTR)false, (DWORD)false };
		return mod;
	}

	// Basic WPM wrapper, easier to use.
	template <typename var>
	bool WriteMemory(DWORD_PTR Address, var Value) {
		return WriteProcessMemory(TargetProcess, (LPVOID)Address, &Value, sizeof(var), 0);
	}

	// Basic RPM wrapper, easier to use.
	template <typename var>
	var ReadMemory(DWORD_PTR Address) {
		var value;
		ReadProcessMemory(TargetProcess, (LPCVOID)Address, &value, sizeof(var), NULL);
		return value;
	}

	// for comparing a region in memory, needed in finding a signature
	bool MemoryCompare(const BYTE* bData, const BYTE* bMask, const char* szMask) {
		for (; *szMask; ++szMask, ++bData, ++bMask) {
			if (*szMask == 'x' && *bData != *bMask) {
				return false;
			}
		}
		return (*szMask == NULL);
	}

	// for finding a signature/pattern in memory of another process
	DWORD_PTR FindSignature(DWORD_PTR start, DWORD size, const char* sig, const char* mask)
	{
		BYTE* data = new BYTE[size];
		SIZE_T bytesRead;

		ReadProcessMemory(TargetProcess, (LPVOID)start, data, size, &bytesRead);

		for (DWORD i = 0; i < size; i++)
		{
			if (MemoryCompare((const BYTE*)(data + i), (const BYTE*)sig, mask)) {
				return start + i;
			}
		}
		delete[] data;
		return NULL;
	}
};