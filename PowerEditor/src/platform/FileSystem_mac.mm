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

#import "FileSystem.h"
#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <codecvt>
#include <locale>

namespace Platform {

// Helper functions
static NSString* wstringToNSString(const wchar_t* wstr) {
    if (!wstr) return nil;
    return [NSString stringWithCharacters:(const unichar*)wstr length:wcslen(wstr)];
}

static std::wstring NSStringToWString(NSString* nsstr) {
    if (!nsstr) return L"";
    std::wstring result;
    result.resize([nsstr length]);
    [nsstr getCharacters:(unichar*)result.data() range:NSMakeRange(0, [nsstr length])];
    return result;
}

static std::string wstringToUTF8(const std::wstring& wstr) {
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    return converter.to_bytes(wstr);
}

static std::wstring UTF8ToWString(const std::string& str) {
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    return converter.from_bytes(str);
}

// File operations
HANDLE FileSystem::createFile(
    const wchar_t* fileName,
    DWORD desiredAccess,
    DWORD shareMode,
    void* securityAttributes,
    DWORD creationDisposition,
    DWORD flagsAndAttributes,
    HANDLE templateFile)
{
    if (!fileName) return INVALID_HANDLE_VALUE;
    
    std::string path = wstringToUTF8(fileName);
    int flags = 0;
    mode_t mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
    
    // Map Windows access modes to POSIX
    if (desiredAccess & 0x80000000) { // GENERIC_READ
        flags |= O_RDONLY;
    }
    if (desiredAccess & 0x40000000) { // GENERIC_WRITE
        flags = (flags == O_RDONLY) ? O_RDWR : O_WRONLY;
    }
    
    // Map creation disposition
    switch (creationDisposition) {
        case 1: // CREATE_NEW
            flags |= O_CREAT | O_EXCL;
            break;
        case 2: // CREATE_ALWAYS
            flags |= O_CREAT | O_TRUNC;
            break;
        case 3: // OPEN_EXISTING
            // No additional flags
            break;
        case 4: // OPEN_ALWAYS
            flags |= O_CREAT;
            break;
        case 5: // TRUNCATE_EXISTING
            flags |= O_TRUNC;
            break;
    }
    
    int fd = open(path.c_str(), flags, mode);
    if (fd == -1) {
        return INVALID_HANDLE_VALUE;
    }
    
    return (HANDLE)(intptr_t)fd;
}

BOOL FileSystem::readFile(
    HANDLE file,
    void* buffer,
    DWORD numberOfBytesToRead,
    DWORD* numberOfBytesRead,
    void* overlapped)
{
    if (file == INVALID_HANDLE_VALUE || !buffer) return FALSE;
    
    int fd = (int)(intptr_t)file;
    ssize_t bytesRead = read(fd, buffer, numberOfBytesToRead);
    
    if (bytesRead < 0) {
        if (numberOfBytesRead) *numberOfBytesRead = 0;
        return FALSE;
    }
    
    if (numberOfBytesRead) *numberOfBytesRead = (DWORD)bytesRead;
    return TRUE;
}

BOOL FileSystem::writeFile(
    HANDLE file,
    const void* buffer,
    DWORD numberOfBytesToWrite,
    DWORD* numberOfBytesWritten,
    void* overlapped)
{
    if (file == INVALID_HANDLE_VALUE || !buffer) return FALSE;
    
    int fd = (int)(intptr_t)file;
    ssize_t bytesWritten = write(fd, buffer, numberOfBytesToWrite);
    
    if (bytesWritten < 0) {
        if (numberOfBytesWritten) *numberOfBytesWritten = 0;
        return FALSE;
    }
    
    if (numberOfBytesWritten) *numberOfBytesWritten = (DWORD)bytesWritten;
    return TRUE;
}

BOOL FileSystem::closeHandle(HANDLE handle) {
    if (handle == INVALID_HANDLE_VALUE) return FALSE;
    int fd = (int)(intptr_t)handle;
    return (close(fd) == 0) ? TRUE : FALSE;
}

DWORD FileSystem::getFileSize(HANDLE file, DWORD* fileSizeHigh) {
    if (file == INVALID_HANDLE_VALUE) return INVALID_FILE_ATTRIBUTES;
    
    int fd = (int)(intptr_t)file;
    struct stat st;
    if (fstat(fd, &st) != 0) {
        return INVALID_FILE_ATTRIBUTES;
    }
    
    if (fileSizeHigh) {
        *fileSizeHigh = (DWORD)(st.st_size >> 32);
    }
    return (DWORD)(st.st_size & 0xFFFFFFFF);
}

BOOL FileSystem::setFilePointer(HANDLE file, LONG distanceToMove, LONG* distanceToMoveHigh, DWORD moveMethod) {
    if (file == INVALID_HANDLE_VALUE) return FALSE;
    
    int fd = (int)(intptr_t)file;
    int whence = SEEK_SET;
    
    switch (moveMethod) {
        case 0: whence = SEEK_SET; break; // FILE_BEGIN
        case 1: whence = SEEK_CUR; break; // FILE_CURRENT
        case 2: whence = SEEK_END; break; // FILE_END
    }
    
    off_t offset = distanceToMove;
    if (distanceToMoveHigh) {
        offset |= ((off_t)*distanceToMoveHigh) << 32;
    }
    
    off_t result = lseek(fd, offset, whence);
    return (result != -1) ? TRUE : FALSE;
}

BOOL FileSystem::setEndOfFile(HANDLE file) {
    if (file == INVALID_HANDLE_VALUE) return FALSE;
    
    int fd = (int)(intptr_t)file;
    off_t pos = lseek(fd, 0, SEEK_CUR);
    if (pos == -1) return FALSE;
    
    return (ftruncate(fd, pos) == 0) ? TRUE : FALSE;
}

BOOL FileSystem::flushFileBuffers(HANDLE file) {
    if (file == INVALID_HANDLE_VALUE) return FALSE;
    
    int fd = (int)(intptr_t)file;
    return (fsync(fd) == 0) ? TRUE : FALSE;
}

// File attributes
DWORD FileSystem::getFileAttributes(const wchar_t* fileName) {
    if (!fileName) return INVALID_FILE_ATTRIBUTES;
    
    std::string path = wstringToUTF8(fileName);
    struct stat st;
    
    if (stat(path.c_str(), &st) != 0) {
        return INVALID_FILE_ATTRIBUTES;
    }
    
    DWORD attrs = FILE_ATTRIBUTE_NORMAL;
    
    if (S_ISDIR(st.st_mode)) {
        attrs |= FILE_ATTRIBUTE_DIRECTORY;
    }
    
    // Check if file is hidden (starts with .)
    const char* filename = strrchr(path.c_str(), '/');
    if (filename && filename[1] == '.') {
        attrs |= FILE_ATTRIBUTE_HIDDEN;
    }
    
    // Check if read-only
    if (!(st.st_mode & S_IWUSR)) {
        attrs |= FILE_ATTRIBUTE_READONLY;
    }
    
    return attrs;
}

BOOL FileSystem::setFileAttributes(const wchar_t* fileName, DWORD fileAttributes) {
    if (!fileName) return FALSE;
    
    std::string path = wstringToUTF8(fileName);
    struct stat st;
    
    if (stat(path.c_str(), &st) != 0) {
        return FALSE;
    }
    
    mode_t mode = st.st_mode;
    
    if (fileAttributes & FILE_ATTRIBUTE_READONLY) {
        mode &= ~(S_IWUSR | S_IWGRP | S_IWOTH);
    } else {
        mode |= S_IWUSR;
    }
    
    return (chmod(path.c_str(), mode) == 0) ? TRUE : FALSE;
}

BOOL FileSystem::getFileAttributesEx(
    const wchar_t* fileName,
    int infoLevelId,
    void* fileInformation)
{
    if (!fileName || !fileInformation) return FALSE;
    
    std::string path = wstringToUTF8(fileName);
    struct stat st;
    
    if (stat(path.c_str(), &st) != 0) {
        return FALSE;
    }
    
    WIN32_FILE_ATTRIBUTE_DATA* data = (WIN32_FILE_ATTRIBUTE_DATA*)fileInformation;
    data->dwFileAttributes = getFileAttributes(fileName);
    
    // Convert Unix timestamps to FILETIME (100-nanosecond intervals since 1601)
    const uint64_t UNIX_EPOCH_IN_FILETIME = 116444736000000000ULL;
    
    uint64_t creationTime = (st.st_ctime * 10000000ULL) + UNIX_EPOCH_IN_FILETIME;
    uint64_t accessTime = (st.st_atime * 10000000ULL) + UNIX_EPOCH_IN_FILETIME;
    uint64_t writeTime = (st.st_mtime * 10000000ULL) + UNIX_EPOCH_IN_FILETIME;
    
    data->ftCreationTime.dwLowDateTime = (DWORD)(creationTime & 0xFFFFFFFF);
    data->ftCreationTime.dwHighDateTime = (DWORD)(creationTime >> 32);
    data->ftLastAccessTime.dwLowDateTime = (DWORD)(accessTime & 0xFFFFFFFF);
    data->ftLastAccessTime.dwHighDateTime = (DWORD)(accessTime >> 32);
    data->ftLastWriteTime.dwLowDateTime = (DWORD)(writeTime & 0xFFFFFFFF);
    data->ftLastWriteTime.dwHighDateTime = (DWORD)(writeTime >> 32);
    
    data->nFileSizeLow = (DWORD)(st.st_size & 0xFFFFFFFF);
    data->nFileSizeHigh = (DWORD)(st.st_size >> 32);
    
    return TRUE;
}

// Directory operations
BOOL FileSystem::createDirectory(const wchar_t* pathName, void* securityAttributes) {
    if (!pathName) return FALSE;
    
    std::string path = wstringToUTF8(pathName);
    return (mkdir(path.c_str(), 0755) == 0) ? TRUE : FALSE;
}

BOOL FileSystem::removeDirectory(const wchar_t* pathName) {
    if (!pathName) return FALSE;
    
    std::string path = wstringToUTF8(pathName);
    return (rmdir(path.c_str()) == 0) ? TRUE : FALSE;
}

BOOL FileSystem::setCurrentDirectory(const wchar_t* pathName) {
    if (!pathName) return FALSE;
    
    std::string path = wstringToUTF8(pathName);
    return (chdir(path.c_str()) == 0) ? TRUE : FALSE;
}

DWORD FileSystem::getCurrentDirectory(DWORD bufferLength, wchar_t* buffer) {
    if (!buffer || bufferLength == 0) return 0;
    
    char cwd[PATH_MAX];
    if (getcwd(cwd, sizeof(cwd)) == nullptr) {
        return 0;
    }
    
    std::wstring wcwd = UTF8ToWString(cwd);
    if (wcwd.length() >= bufferLength) {
        return (DWORD)(wcwd.length() + 1);
    }
    
    wcscpy(buffer, wcwd.c_str());
    return (DWORD)wcwd.length();
}

// File operations
BOOL FileSystem::deleteFile(const wchar_t* fileName) {
    if (!fileName) return FALSE;
    
    std::string path = wstringToUTF8(fileName);
    return (unlink(path.c_str()) == 0) ? TRUE : FALSE;
}

BOOL FileSystem::moveFile(const wchar_t* existingFileName, const wchar_t* newFileName) {
    if (!existingFileName || !newFileName) return FALSE;
    
    std::string oldPath = wstringToUTF8(existingFileName);
    std::string newPath = wstringToUTF8(newFileName);
    
    return (rename(oldPath.c_str(), newPath.c_str()) == 0) ? TRUE : FALSE;
}

BOOL FileSystem::moveFileEx(
    const wchar_t* existingFileName,
    const wchar_t* newFileName,
    DWORD flags)
{
    // For now, just use moveFile (flags are ignored)
    return moveFile(existingFileName, newFileName);
}

BOOL FileSystem::copyFile(
    const wchar_t* existingFileName,
    const wchar_t* newFileName,
    BOOL failIfExists)
{
    @autoreleasepool {
        NSString* source = wstringToNSString(existingFileName);
        NSString* dest = wstringToNSString(newFileName);
        NSFileManager* fm = [NSFileManager defaultManager];
        
        if (failIfExists && [fm fileExistsAtPath:dest]) {
            return FALSE;
        }
        
        NSError* error = nil;
        BOOL success = [fm copyItemAtPath:source toPath:dest error:&error];
        return success ? TRUE : FALSE;
    }
}

// Path operations
DWORD FileSystem::getFullPathName(
    const wchar_t* fileName,
    DWORD bufferLength,
    wchar_t* buffer,
    wchar_t** filePart)
{
    if (!fileName) return 0;
    
    @autoreleasepool {
        NSString* path = wstringToNSString(fileName);
        NSString* fullPath = [path stringByStandardizingPath];
        
        if (!fullPath) return 0;
        
        std::wstring wfullPath = NSStringToWString(fullPath);
        
        if (buffer && bufferLength > 0) {
            if (wfullPath.length() >= bufferLength) {
                return (DWORD)(wfullPath.length() + 1);
            }
            wcscpy(buffer, wfullPath.c_str());
            
            if (filePart) {
                wchar_t* lastSlash = wcsrchr(buffer, L'/');
                *filePart = lastSlash ? (lastSlash + 1) : buffer;
            }
        }
        
        return (DWORD)wfullPath.length();
    }
}

DWORD FileSystem::getTempPath(DWORD bufferLength, wchar_t* buffer) {
    @autoreleasepool {
        NSString* tempDir = NSTemporaryDirectory();
        std::wstring wtemp = NSStringToWString(tempDir);
        
        if (buffer && bufferLength > 0) {
            if (wtemp.length() >= bufferLength) {
                return (DWORD)(wtemp.length() + 1);
            }
            wcscpy(buffer, wtemp.c_str());
        }
        
        return (DWORD)wtemp.length();
    }
}

BOOL FileSystem::fileExists(const wchar_t* fileName) {
    if (!fileName) return FALSE;
    
    std::string path = wstringToUTF8(fileName);
    struct stat st;
    return (stat(path.c_str(), &st) == 0 && S_ISREG(st.st_mode)) ? TRUE : FALSE;
}

BOOL FileSystem::directoryExists(const wchar_t* pathName) {
    if (!pathName) return FALSE;
    
    std::string path = wstringToUTF8(pathName);
    struct stat st;
    return (stat(path.c_str(), &st) == 0 && S_ISDIR(st.st_mode)) ? TRUE : FALSE;
}

// Utility functions
std::wstring FileSystem::getFileName(const std::wstring& fullPath) {
    size_t pos = fullPath.find_last_of(L"/\\");
    if (pos == std::wstring::npos) return fullPath;
    return fullPath.substr(pos + 1);
}

std::wstring FileSystem::getDirectoryName(const std::wstring& fullPath) {
    size_t pos = fullPath.find_last_of(L"/\\");
    if (pos == std::wstring::npos) return L"";
    return fullPath.substr(0, pos);
}

std::wstring FileSystem::getFileExtension(const std::wstring& fullPath) {
    size_t pos = fullPath.find_last_of(L'.');
    if (pos == std::wstring::npos) return L"";
    return fullPath.substr(pos);
}

std::wstring FileSystem::combinePath(const std::wstring& path1, const std::wstring& path2) {
    if (path1.empty()) return path2;
    if (path2.empty()) return path1;
    
    wchar_t lastChar = path1[path1.length() - 1];
    if (lastChar == L'/' || lastChar == L'\\') {
        return path1 + path2;
    }
    return path1 + L"/" + path2;
}

std::wstring FileSystem::getAppDataPath() {
    @autoreleasepool {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            NSString* appSupport = paths[0];
            return NSStringToWString(appSupport);
        }
        return L"";
    }
}

std::wstring FileSystem::getDocumentsPath() {
    @autoreleasepool {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            return NSStringToWString(paths[0]);
        }
        return L"";
    }
}

std::wstring FileSystem::getDesktopPath() {
    @autoreleasepool {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            return NSStringToWString(paths[0]);
        }
        return L"";
    }
}

std::wstring FileSystem::getHomePath() {
    @autoreleasepool {
        NSString* homePath = NSHomeDirectory();
        return NSStringToWString(homePath);
    }
}

// Stub implementations for complex features
BOOL FileSystem::getFileTime(HANDLE file, FILETIME* creationTime, FILETIME* lastAccessTime, FILETIME* lastWriteTime) {
    // TODO: Implement using fstat
    return FALSE;
}

BOOL FileSystem::setFileTime(HANDLE file, const FILETIME* creationTime, const FILETIME* lastAccessTime, const FILETIME* lastWriteTime) {
    // TODO: Implement
    return FALSE;
}

HANDLE FileSystem::findFirstFile(const wchar_t* fileName, void* findFileData) {
    // TODO: Implement using opendir/readdir
    return INVALID_HANDLE_VALUE;
}

BOOL FileSystem::findNextFile(HANDLE findFile, void* findFileData) {
    // TODO: Implement
    return FALSE;
}

BOOL FileSystem::findClose(HANDLE findFile) {
    // TODO: Implement
    return FALSE;
}

UINT FileSystem::getTempFileName(const wchar_t* pathName, const wchar_t* prefixString, UINT unique, wchar_t* tempFileName) {
    // TODO: Implement using mkstemp
    return 0;
}

std::vector<std::wstring> FileSystem::getFilesInDirectory(
    const std::wstring& directory,
    const std::wstring& pattern,
    BOOL recursive)
{
    // TODO: Implement
    return std::vector<std::wstring>();
}

// FileMonitor implementation
class FileSystem::FileMonitor::Impl {
public:
    // TODO: Implement using FSEvents
};

FileSystem::FileMonitor::FileMonitor() : _impl(nullptr) {
    // TODO: Create Impl
}

FileSystem::FileMonitor::~FileMonitor() {
    // TODO: Delete Impl
}

BOOL FileSystem::FileMonitor::startMonitoring(const wchar_t* directory, BOOL watchSubtree, DWORD notifyFilter) {
    // TODO: Implement
    return FALSE;
}

void FileSystem::FileMonitor::stopMonitoring() {
    // TODO: Implement
}

void FileSystem::FileMonitor::setCallback(ChangeCallback callback) {
    // TODO: Implement
}

} // namespace Platform
