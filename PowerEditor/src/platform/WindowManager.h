// This file is part of Notepad++ project
// Copyright (C)2023 Don HO <don.h@free.fr>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// at your option any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#pragma once

#include "PlatformTypes.h"
#include <string>

// Platform-agnostic window management interface
// This provides a common API for window operations across platforms

namespace Platform {

class WindowManager {
public:
    // Window creation and destruction
    static HWND createWindow(
        const wchar_t* className,
        const wchar_t* windowName,
        DWORD style,
        int x, int y,
        int width, int height,
        HWND parent,
        HMENU menu,
        HINSTANCE instance,
        void* param
    );
    
    static void destroyWindow(HWND hwnd);
    
    // Window visibility and state
    static void showWindow(HWND hwnd, int cmdShow);
    static void hideWindow(HWND hwnd);
    static BOOL isWindowVisible(HWND hwnd);
    static void updateWindow(HWND hwnd);
    
    // Window position and size
    static void moveWindow(HWND hwnd, int x, int y, int width, int height, BOOL repaint);
    static void getWindowRect(HWND hwnd, RECT* rect);
    static void getClientRect(HWND hwnd, RECT* rect);
    static void setWindowPos(HWND hwnd, HWND insertAfter, int x, int y, int cx, int cy, UINT flags);
    
    // Window properties
    static void setWindowText(HWND hwnd, const wchar_t* text);
    static int getWindowText(HWND hwnd, wchar_t* buffer, int maxCount);
    static LONG_PTR setWindowLongPtr(HWND hwnd, int index, LONG_PTR newValue);
    static LONG_PTR getWindowLongPtr(HWND hwnd, int index);
    
    // Window hierarchy
    static HWND getParent(HWND hwnd);
    static HWND setParent(HWND hwnd, HWND newParent);
    static HWND findWindow(const wchar_t* className, const wchar_t* windowName);
    
    // Focus and activation
    static HWND setFocus(HWND hwnd);
    static HWND getFocus();
    static void setForegroundWindow(HWND hwnd);
    static BOOL isZoomed(HWND hwnd);
    static BOOL isIconic(HWND hwnd);
    
    // Message handling
    static LRESULT sendMessage(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
    static BOOL postMessage(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
    
    // Invalidation and painting
    static void invalidateRect(HWND hwnd, const RECT* rect, BOOL erase);
    static void validateRect(HWND hwnd, const RECT* rect);
    
    // Cursor operations
    static void setCursor(HCURSOR cursor);
    static HCURSOR loadCursor(HINSTANCE instance, const wchar_t* cursorName);
    
    // Screen coordinates
    static void clientToScreen(HWND hwnd, POINT* point);
    static void screenToClient(HWND hwnd, POINT* point);
    
    // Window enable/disable
    static BOOL enableWindow(HWND hwnd, BOOL enable);
    static BOOL isWindowEnabled(HWND hwnd);
    
    // Message box
    static int messageBox(HWND hwnd, const wchar_t* text, const wchar_t* caption, UINT type);
    
    // Clipboard operations
    static BOOL openClipboard(HWND hwnd);
    static BOOL closeClipboard();
    static BOOL emptyClipboard();
    static HANDLE getClipboardData(UINT format);
    static HANDLE setClipboardData(UINT format, HANDLE data);
    
    // Timer operations
    static UINT_PTR setTimer(HWND hwnd, UINT_PTR id, UINT elapse, void* timerProc);
    static BOOL killTimer(HWND hwnd, UINT_PTR id);
    
    // Menu operations
    static HMENU createMenu();
    static HMENU createPopupMenu();
    static BOOL destroyMenu(HMENU menu);
    static BOOL appendMenu(HMENU menu, UINT flags, UINT_PTR id, const wchar_t* item);
    static BOOL insertMenu(HMENU menu, UINT position, UINT flags, UINT_PTR id, const wchar_t* item);
    static BOOL deleteMenu(HMENU menu, UINT position, UINT flags);
    static BOOL checkMenuItem(HMENU menu, UINT id, UINT check);
    static BOOL enableMenuItem(HMENU menu, UINT id, UINT enable);
    static HMENU getMenu(HWND hwnd);
    static BOOL setMenu(HWND hwnd, HMENU menu);
    static BOOL trackPopupMenu(HMENU menu, UINT flags, int x, int y, HWND hwnd);
    
    // Dialog operations
    static INT_PTR dialogBox(HINSTANCE instance, const wchar_t* templateName, HWND parent, void* dialogProc);
    static HWND createDialog(HINSTANCE instance, const wchar_t* templateName, HWND parent, void* dialogProc);
    static BOOL endDialog(HWND dialog, INT_PTR result);
    
    // GDI operations (basic)
    static HDC getDC(HWND hwnd);
    static int releaseDC(HWND hwnd, HDC dc);
    static HDC beginPaint(HWND hwnd, void* paintStruct);
    static BOOL endPaint(HWND hwnd, const void* paintStruct);
    
    // Module/instance operations
    static HMODULE getModuleHandle(const wchar_t* moduleName);
    static HMODULE loadLibrary(const wchar_t* fileName);
    static BOOL freeLibrary(HMODULE module);
    static void* getProcAddress(HMODULE module, const char* procName);
    
    // System metrics
    static int getSystemMetrics(int index);
    
    // Drag and drop
    static void dragAcceptFiles(HWND hwnd, BOOL accept);
    static void dragFinish(HDROP drop);
    static UINT dragQueryFile(HDROP drop, UINT index, wchar_t* buffer, UINT bufferSize);
    
    // Utility functions
    static DWORD getLastError();
    static void setLastError(DWORD error);
    static void sleep(DWORD milliseconds);
    static DWORD getTickCount();
    
    // String conversion helpers
    static std::wstring stringToWString(const std::string& str);
    static std::string wstringToString(const std::wstring& wstr);
};

} // namespace Platform
