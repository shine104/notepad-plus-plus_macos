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
#include <vector>
#include <functional>

// Platform-agnostic file system operations interface

namespace Platform {

class FileSystem {
public:
    // File operations
    static HANDLE createFile(
        const wchar_t* fileName,
        DWORD desiredAccess,
        DWORD shareMode,
        void* securityAttributes,
        DWORD creationDisposition,
        DWORD flagsAndAttributes,
        HANDLE templateFile
    );
    
    static BOOL readFile(
        HANDLE file,
        void* buffer,
        DWORD numberOfBytesToRead,
        DWORD* numberOfBytesRead,
        void* overlapped
    );
    
    static BOOL writeFile(
        HANDLE file,
        const void* buffer,
        DWORD numberOfBytesToWrite,
        DWORD* numberOfBytesWritten,
        void* overlapped
    );
    
    static BOOL closeHandle(HANDLE handle);
    
    static DWORD getFileSize(HANDLE file, DWORD* fileSizeHigh);
    
    static BOOL setFilePointer(HANDLE file, LONG distanceToMove, LONG* distanceToMoveHigh, DWORD moveMethod);
    
    static BOOL setEndOfFile(HANDLE file);
    
    static BOOL flushFileBuffers(HANDLE file);
    
    // File attributes
    static DWORD getFileAttributes(const wchar_t* fileName);
    
    static BOOL setFileAttributes(const wchar_t* fileName, DWORD fileAttributes);
    
    static BOOL getFileAttributesEx(
        const wchar_t* fileName,
        int infoLevelId,
        void* fileInformation
    );
    
    // File time
    static BOOL getFileTime(
        HANDLE file,
        FILETIME* creationTime,
        FILETIME* lastAccessTime,
        FILETIME* lastWriteTime
    );
    
    static BOOL setFileTime(
        HANDLE file,
        const FILETIME* creationTime,
        const FILETIME* lastAccessTime,
        const FILETIME* lastWriteTime
    );
    
    // Directory operations
    static BOOL createDirectory(const wchar_t* pathName, void* securityAttributes);
    
    static BOOL removeDirectory(const wchar_t* pathName);
    
    static BOOL setCurrentDirectory(const wchar_t* pathName);
    
    static DWORD getCurrentDirectory(DWORD bufferLength, wchar_t* buffer);
    
    // File finding
    static HANDLE findFirstFile(const wchar_t* fileName, void* findFileData);
    
    static BOOL findNextFile(HANDLE findFile, void* findFileData);
    
    static BOOL findClose(HANDLE findFile);
    
    // File operations
    static BOOL deleteFile(const wchar_t* fileName);
    
    static BOOL moveFile(const wchar_t* existingFileName, const wchar_t* newFileName);
    
    static BOOL moveFileEx(
        const wchar_t* existingFileName,
        const wchar_t* newFileName,
        DWORD flags
    );
    
    static BOOL copyFile(
        const wchar_t* existingFileName,
        const wchar_t* newFileName,
        BOOL failIfExists
    );
    
    // Path operations
    static DWORD getFullPathName(
        const wchar_t* fileName,
        DWORD bufferLength,
        wchar_t* buffer,
        wchar_t** filePart
    );
    
    static DWORD getTempPath(DWORD bufferLength, wchar_t* buffer);
    
    static UINT getTempFileName(
        const wchar_t* pathName,
        const wchar_t* prefixString,
        UINT unique,
        wchar_t* tempFileName
    );
    
    // File existence check
    static BOOL fileExists(const wchar_t* fileName);
    
    static BOOL directoryExists(const wchar_t* pathName);
    
    // File monitoring (FSEvents on macOS, ReadDirectoryChangesW on Windows)
    class FileMonitor {
    public:
        using ChangeCallback = std::function<void(const std::wstring& path, DWORD action)>;
        
        FileMonitor();
        ~FileMonitor();
        
        BOOL startMonitoring(const wchar_t* directory, BOOL watchSubtree, DWORD notifyFilter);
        void stopMonitoring();
        void setCallback(ChangeCallback callback);
        
    private:
        class Impl;
        Impl* _impl;
    };
    
    // Utility functions
    static std::wstring getFileName(const std::wstring& fullPath);
    static std::wstring getDirectoryName(const std::wstring& fullPath);
    static std::wstring getFileExtension(const std::wstring& fullPath);
    static std::wstring combinePath(const std::wstring& path1, const std::wstring& path2);
    static std::vector<std::wstring> getFilesInDirectory(
        const std::wstring& directory,
        const std::wstring& pattern = L"*",
        BOOL recursive = FALSE
    );
    
    // Special folders
    static std::wstring getAppDataPath();
    static std::wstring getDocumentsPath();
    static std::wstring getDesktopPath();
    static std::wstring getHomePath();
};

} // namespace Platform
