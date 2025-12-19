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

#import "WindowManager.h"
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <map>
#include <codecvt>
#include <locale>

namespace Platform {

// Internal storage for mapping HWND to NSWindow/NSView
static std::map<HWND, NSWindow*> g_windowMap;
static std::map<HWND, NSView*> g_viewMap;
static DWORD g_lastError = ERROR_SUCCESS;

// Helper function to convert wstring to NSString
static NSString* wstringToNSString(const wchar_t* wstr) {
    if (!wstr) return nil;
    return [NSString stringWithCharacters:(const unichar*)wstr 
                                   length:wcslen(wstr)];
}

// Helper function to convert NSString to wstring
static void NSStringToWString(NSString* nsstr, wchar_t* buffer, int maxCount) {
    if (!nsstr || !buffer || maxCount <= 0) return;
    NSUInteger length = MIN([nsstr length], (NSUInteger)(maxCount - 1));
    [nsstr getCharacters:(unichar*)buffer range:NSMakeRange(0, length)];
    buffer[length] = L'\0';
}

HWND WindowManager::createWindow(
    const wchar_t* className,
    const wchar_t* windowName,
    DWORD style,
    int x, int y,
    int width, int height,
    HWND parent,
    HMENU menu,
    HINSTANCE instance,
    void* param)
{
    @autoreleasepool {
        NSRect contentRect = NSMakeRect(x, y, width, height);
        NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | 
                                      NSWindowStyleMaskClosable | 
                                      NSWindowStyleMaskMiniaturizable;
        
        if (style & WS_THICKFRAME) {
            styleMask |= NSWindowStyleMaskResizable;
        }
        
        NSWindow* window = [[NSWindow alloc] initWithContentRect:contentRect
                                                       styleMask:styleMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        
        if (windowName) {
            window.title = wstringToNSString(windowName);
        }
        
        HWND hwnd = (__bridge HWND)window;
        g_windowMap[hwnd] = window;
        
        return hwnd;
    }
}

void WindowManager::destroyWindow(HWND hwnd) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            NSWindow* window = it->second;
            [window close];
            g_windowMap.erase(it);
        }
    }
}

void WindowManager::showWindow(HWND hwnd, int cmdShow) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            NSWindow* window = it->second;
            switch (cmdShow) {
                case SW_SHOW:
                case SW_SHOWNORMAL:
                    [window makeKeyAndOrderFront:nil];
                    break;
                case SW_HIDE:
                    [window orderOut:nil];
                    break;
                case SW_MINIMIZE:
                    [window miniaturize:nil];
                    break;
                case SW_MAXIMIZE:
                    [window zoom:nil];
                    break;
            }
        }
    }
}

void WindowManager::hideWindow(HWND hwnd) {
    showWindow(hwnd, SW_HIDE);
}

BOOL WindowManager::isWindowVisible(HWND hwnd) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            return [it->second isVisible] ? TRUE : FALSE;
        }
        return FALSE;
    }
}

void WindowManager::updateWindow(HWND hwnd) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            [it->second display];
        }
    }
}

void WindowManager::moveWindow(HWND hwnd, int x, int y, int width, int height, BOOL repaint) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            NSWindow* window = it->second;
            NSRect frame = NSMakeRect(x, y, width, height);
            [window setFrame:frame display:(repaint ? YES : NO)];
        }
    }
}

void WindowManager::getWindowRect(HWND hwnd, RECT* rect) {
    @autoreleasepool {
        if (!rect) return;
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            NSRect frame = [it->second frame];
            rect->left = (LONG)frame.origin.x;
            rect->top = (LONG)frame.origin.y;
            rect->right = (LONG)(frame.origin.x + frame.size.width);
            rect->bottom = (LONG)(frame.origin.y + frame.size.height);
        }
    }
}

void WindowManager::getClientRect(HWND hwnd, RECT* rect) {
    @autoreleasepool {
        if (!rect) return;
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            NSRect contentRect = [[it->second contentView] frame];
            rect->left = 0;
            rect->top = 0;
            rect->right = (LONG)contentRect.size.width;
            rect->bottom = (LONG)contentRect.size.height;
        }
    }
}

void WindowManager::setWindowText(HWND hwnd, const wchar_t* text) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end() && text) {
            it->second.title = wstringToNSString(text);
        }
    }
}

int WindowManager::getWindowText(HWND hwnd, wchar_t* buffer, int maxCount) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end() && buffer && maxCount > 0) {
            NSString* title = it->second.title;
            NSStringToWString(title, buffer, maxCount);
            return (int)[title length];
        }
        return 0;
    }
}

HWND WindowManager::findWindow(const wchar_t* className, const wchar_t* windowName) {
    @autoreleasepool {
        if (windowName) {
            NSString* searchTitle = wstringToNSString(windowName);
            for (auto& pair : g_windowMap) {
                if ([pair.second.title isEqualToString:searchTitle]) {
                    return pair.first;
                }
            }
        }
        return nullptr;
    }
}

HWND WindowManager::setFocus(HWND hwnd) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            [it->second makeKeyWindow];
            return hwnd;
        }
        return nullptr;
    }
}

void WindowManager::setForegroundWindow(HWND hwnd) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            [it->second makeKeyAndOrderFront:nil];
            [NSApp activateIgnoringOtherApps:YES];
        }
    }
}

BOOL WindowManager::isZoomed(HWND hwnd) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            return [it->second isZoomed] ? TRUE : FALSE;
        }
        return FALSE;
    }
}

BOOL WindowManager::isIconic(HWND hwnd) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            return [it->second isMiniaturized] ? TRUE : FALSE;
        }
        return FALSE;
    }
}

int WindowManager::messageBox(HWND hwnd, const wchar_t* text, const wchar_t* caption, UINT type) {
    @autoreleasepool {
        NSAlert* alert = [[NSAlert alloc] init];
        
        if (caption) {
            alert.messageText = wstringToNSString(caption);
        }
        if (text) {
            alert.informativeText = wstringToNSString(text);
        }
        
        // Set alert style based on type
        if (type & MB_ICONERROR) {
            alert.alertStyle = NSAlertStyleCritical;
        } else if (type & MB_ICONWARNING) {
            alert.alertStyle = NSAlertStyleWarning;
        } else {
            alert.alertStyle = NSAlertStyleInformational;
        }
        
        // Add buttons based on type
        if (type & MB_OKCANCEL) {
            [alert addButtonWithTitle:@"OK"];
            [alert addButtonWithTitle:@"Cancel"];
        } else if (type & MB_YESNO) {
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
        } else if (type & MB_YESNOCANCEL) {
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
        } else {
            [alert addButtonWithTitle:@"OK"];
        }
        
        NSModalResponse response = [alert runModal];
        
        // Map response to Windows message box return values
        switch (response) {
            case NSAlertFirstButtonReturn:
                return (type & MB_YESNO) || (type & MB_YESNOCANCEL) ? IDYES : IDOK;
            case NSAlertSecondButtonReturn:
                return (type & MB_YESNO) || (type & MB_YESNOCANCEL) ? IDNO : IDCANCEL;
            case NSAlertThirdButtonReturn:
                return IDCANCEL;
            default:
                return IDOK;
        }
    }
}

void WindowManager::sleep(DWORD milliseconds) {
    [NSThread sleepForTimeInterval:(milliseconds / 1000.0)];
}

DWORD WindowManager::getLastError() {
    return g_lastError;
}

void WindowManager::setLastError(DWORD error) {
    g_lastError = error;
}

std::wstring WindowManager::stringToWString(const std::string& str) {
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    return converter.from_bytes(str);
}

std::string WindowManager::wstringToString(const std::wstring& wstr) {
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    return converter.to_bytes(wstr);
}

// Stub implementations for functions that need more complex implementation
LONG_PTR WindowManager::setWindowLongPtr(HWND hwnd, int index, LONG_PTR newValue) {
    // TODO: Implement using associated objects
    return 0;
}

LONG_PTR WindowManager::getWindowLongPtr(HWND hwnd, int index) {
    // TODO: Implement using associated objects
    return 0;
}

HWND WindowManager::getParent(HWND hwnd) {
    // TODO: Implement
    return nullptr;
}

HWND WindowManager::setParent(HWND hwnd, HWND newParent) {
    // TODO: Implement
    return nullptr;
}

HWND WindowManager::getFocus() {
    // TODO: Implement
    return nullptr;
}

LRESULT WindowManager::sendMessage(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    // TODO: Implement message routing
    return 0;
}

BOOL WindowManager::postMessage(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    // TODO: Implement message posting
    return FALSE;
}

void WindowManager::setWindowPos(HWND hwnd, HWND insertAfter, int x, int y, int cx, int cy, UINT flags) {
    // TODO: Implement
}

void WindowManager::invalidateRect(HWND hwnd, const RECT* rect, BOOL erase) {
    @autoreleasepool {
        auto it = g_windowMap.find(hwnd);
        if (it != g_windowMap.end()) {
            [[it->second contentView] setNeedsDisplay:YES];
        }
    }
}

void WindowManager::validateRect(HWND hwnd, const RECT* rect) {
    // TODO: Implement
}

void WindowManager::setCursor(HCURSOR cursor) {
    // TODO: Implement
}

HCURSOR WindowManager::loadCursor(HINSTANCE instance, const wchar_t* cursorName) {
    // TODO: Implement
    return nullptr;
}

void WindowManager::clientToScreen(HWND hwnd, POINT* point) {
    // TODO: Implement coordinate conversion
}

void WindowManager::screenToClient(HWND hwnd, POINT* point) {
    // TODO: Implement coordinate conversion
}

BOOL WindowManager::enableWindow(HWND hwnd, BOOL enable) {
    // TODO: Implement
    return TRUE;
}

BOOL WindowManager::isWindowEnabled(HWND hwnd) {
    // TODO: Implement
    return TRUE;
}

// Clipboard stubs
BOOL WindowManager::openClipboard(HWND hwnd) { return TRUE; }
BOOL WindowManager::closeClipboard() { return TRUE; }
BOOL WindowManager::emptyClipboard() { return TRUE; }
HANDLE WindowManager::getClipboardData(UINT format) { return nullptr; }
HANDLE WindowManager::setClipboardData(UINT format, HANDLE data) { return nullptr; }

// Timer stubs
UINT_PTR WindowManager::setTimer(HWND hwnd, UINT_PTR id, UINT elapse, void* timerProc) { return 0; }
BOOL WindowManager::killTimer(HWND hwnd, UINT_PTR id) { return FALSE; }

// Menu stubs
HMENU WindowManager::createMenu() { return nullptr; }
HMENU WindowManager::createPopupMenu() { return nullptr; }
BOOL WindowManager::destroyMenu(HMENU menu) { return FALSE; }
BOOL WindowManager::appendMenu(HMENU menu, UINT flags, UINT_PTR id, const wchar_t* item) { return FALSE; }
BOOL WindowManager::insertMenu(HMENU menu, UINT position, UINT flags, UINT_PTR id, const wchar_t* item) { return FALSE; }
BOOL WindowManager::deleteMenu(HMENU menu, UINT position, UINT flags) { return FALSE; }
BOOL WindowManager::checkMenuItem(HMENU menu, UINT id, UINT check) { return FALSE; }
BOOL WindowManager::enableMenuItem(HMENU menu, UINT id, UINT enable) { return FALSE; }
HMENU WindowManager::getMenu(HWND hwnd) { return nullptr; }
BOOL WindowManager::setMenu(HWND hwnd, HMENU menu) { return FALSE; }
BOOL WindowManager::trackPopupMenu(HMENU menu, UINT flags, int x, int y, HWND hwnd) { return FALSE; }

// Dialog stubs
INT_PTR WindowManager::dialogBox(HINSTANCE instance, const wchar_t* templateName, HWND parent, void* dialogProc) { return 0; }
HWND WindowManager::createDialog(HINSTANCE instance, const wchar_t* templateName, HWND parent, void* dialogProc) { return nullptr; }
BOOL WindowManager::endDialog(HWND dialog, INT_PTR result) { return FALSE; }

// GDI stubs
HDC WindowManager::getDC(HWND hwnd) { return nullptr; }
int WindowManager::releaseDC(HWND hwnd, HDC dc) { return 0; }
HDC WindowManager::beginPaint(HWND hwnd, void* paintStruct) { return nullptr; }
BOOL WindowManager::endPaint(HWND hwnd, const void* paintStruct) { return FALSE; }

// Module stubs
HMODULE WindowManager::getModuleHandle(const wchar_t* moduleName) { return nullptr; }
HMODULE WindowManager::loadLibrary(const wchar_t* fileName) { return nullptr; }
BOOL WindowManager::freeLibrary(HMODULE module) { return FALSE; }
void* WindowManager::getProcAddress(HMODULE module, const char* procName) { return nullptr; }

// System metrics stub
int WindowManager::getSystemMetrics(int index) { return 0; }

// Drag and drop stubs
void WindowManager::dragAcceptFiles(HWND hwnd, BOOL accept) {}
void WindowManager::dragFinish(HDROP drop) {}
UINT WindowManager::dragQueryFile(HDROP drop, UINT index, wchar_t* buffer, UINT bufferSize) { return 0; }

DWORD WindowManager::getTickCount() {
    return (DWORD)([[NSProcessInfo processInfo] systemUptime] * 1000.0);
}

} // namespace Platform
