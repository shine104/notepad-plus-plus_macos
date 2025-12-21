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

#import "NotepadPlusWindowController.h"
#import "Scintilla.h"
#import "ScintillaView.h"

@implementation NotepadPlusWindowController

- (instancetype)init {
  // Create the window
  NSRect contentRect = NSMakeRect(100, 100, 800, 600);
  NSWindowStyleMask styleMask =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
      NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

  NSWindow *window =
      [[NSWindow alloc] initWithContentRect:contentRect
                                  styleMask:styleMask
                                    backing:NSBackingStoreBuffered
                                      defer:NO];

  self = [super initWithWindow:window];
  if (self) {
    _currentFilePath = nil;
    _isDocumentModified = NO;

    [self setupWindow];
    [self setupTextView];
    [self setupToolbar];
    [self updateWindowTitle];
  }

  return self;
}

#pragma mark - Window Setup

- (void)setupWindow {
  NSWindow *window = self.window;

  window.title = @"Untitled";
  window.delegate = self;

  // Center the window on screen
  [window center];

  // Set minimum size
  window.minSize = NSMakeSize(400, 300);

  // Enable full screen mode
  window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;

  // Set appearance to support dark mode
  window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
}

- (void)setupTextView {
  // Create ScintillaView - it manages its own scroll view
  NSRect contentFrame = [[self.window contentView] bounds];

  self.textView = [[ScintillaView alloc] initWithFrame:contentFrame];
  self.textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  // Get the internal scroll view for reference
  self.scrollView = self.textView.scrollView;

  // Configure basic Scintilla properties
  // Set monospaced font
  [self.textView setStringProperty:SCI_STYLESETFONT
                         parameter:STYLE_DEFAULT
                             value:@"Menlo"];
  [self.textView setGeneralProperty:SCI_STYLESETSIZE
                          parameter:STYLE_DEFAULT
                              value:12];

  // Apply default style to all styles
  [self.textView setGeneralProperty:SCI_STYLECLEARALL parameter:0 value:0];

  // Enable undo collection
  [self.textView setGeneralProperty:SCI_SETUNDOCOLLECTION parameter:1 value:0];

  // Set UTF-8 encoding
  [self.textView setGeneralProperty:SCI_SETCODEPAGE
                          parameter:SC_CP_UTF8
                              value:0];

  // Enable line numbers (margin 0)
  [self.textView setGeneralProperty:SCI_SETMARGINTYPEN
                          parameter:0
                              value:SC_MARGIN_NUMBER];
  [self.textView setGeneralProperty:SCI_SETMARGINWIDTHN parameter:0 value:40];

  // Set tab width
  [self.textView setGeneralProperty:SCI_SETTABWIDTH parameter:4 value:0];

  // Enable caret line highlighting
  [self.textView setGeneralProperty:SCI_SETCARETLINEVISIBLE
                          parameter:1
                              value:0];

  // Set selection colors
  [self.textView setColorProperty:SCI_SETSELBACK
                        parameter:1
                            value:[NSColor selectedTextBackgroundColor]];

  // Set up notification for text changes
  // ScintillaView uses delegate pattern instead of NSNotificationCenter
  // We'll handle this through Scintilla notifications later

  // Add ScintillaView to window
  [self.window.contentView addSubview:self.textView];
}

- (void)setupToolbar {
  // Create toolbar
  NSToolbar *toolbar =
      [[NSToolbar alloc] initWithIdentifier:@"NotepadPlusToolbar"];
  toolbar.displayMode = NSToolbarDisplayModeIconOnly;
  toolbar.allowsUserCustomization = YES;
  toolbar.autosavesConfiguration = YES;

  self.toolbar = toolbar;
  self.window.toolbar = toolbar;

  // TODO: Add toolbar items (New, Open, Save, etc.)
}

- (void)updateWindowTitle {
  NSString *title;

  if (self.currentFilePath) {
    title = [self.currentFilePath lastPathComponent];
  } else {
    title = @"Untitled";
  }

  if (self.isDocumentModified) {
    title = [NSString stringWithFormat:@"%@ — Edited", title];
  }

  self.window.title = title;
  self.window.representedURL =
      self.currentFilePath ? [NSURL fileURLWithPath:self.currentFilePath] : nil;
}

#pragma mark - Document Operations

- (void)newDocument:(id)sender {
  NSLog(@"Creating new document");

  // Check if current document needs saving
  if (self.isDocumentModified) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Do you want to save changes?";
    alert.informativeText =
        @"Your changes will be lost if you don't save them.";
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Don't Save"];
    [alert addButtonWithTitle:@"Cancel"];

    NSModalResponse response = [alert runModal];

    if (response == NSAlertFirstButtonReturn) {
      [self saveDocument:sender];
    } else if (response == NSAlertThirdButtonReturn) {
      return; // Cancel
    }
  }

  // Clear the text view
  self.textView.string = @"";
  self.currentFilePath = nil;
  self.isDocumentModified = NO;
  [self updateWindowTitle];
}

- (void)openDocument:(id)sender {
  NSLog(@"Opening document");

  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  openPanel.canChooseFiles = YES;
  openPanel.canChooseDirectories = NO;
  openPanel.allowsMultipleSelection = NO;

  [openPanel beginSheetModalForWindow:self.window
                    completionHandler:^(NSModalResponse result) {
                      if (result == NSModalResponseOK) {
                        NSURL *url = openPanel.URL;
                        if (url) {
                          [self openFile:url.path];
                        }
                      }
                    }];
}

- (void)openFile:(NSString *)filePath {
  NSLog(@"Opening file: %@", filePath);

  NSError *error = nil;
  NSString *content = [NSString stringWithContentsOfFile:filePath
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];

  if (error) {
    NSLog(@"Error opening file: %@", error.localizedDescription);

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Error Opening File";
    alert.informativeText = error.localizedDescription;
    [alert addButtonWithTitle:@"OK"];
    alert.alertStyle = NSAlertStyleCritical;
    [alert runModal];

    return;
  }

  self.textView.string = content;
  self.currentFilePath = filePath;
  self.isDocumentModified = NO;
  [self updateWindowTitle];
}

- (void)saveDocument:(id)sender {
  NSLog(@"Saving document");

  if (self.currentFilePath) {
    [self saveToFile:self.currentFilePath];
  } else {
    [self saveDocumentAs:sender];
  }
}

- (void)saveDocumentAs:(id)sender {
  NSLog(@"Save document as");

  NSSavePanel *savePanel = [NSSavePanel savePanel];
  savePanel.allowedFileTypes =
      @[ @"txt", @"cpp", @"h", @"py", @"js", @"html", @"css" ];
  savePanel.allowsOtherFileTypes = YES;

  if (self.currentFilePath) {
    savePanel.nameFieldStringValue = [self.currentFilePath lastPathComponent];
  }

  [savePanel beginSheetModalForWindow:self.window
                    completionHandler:^(NSModalResponse result) {
                      if (result == NSModalResponseOK) {
                        NSURL *url = savePanel.URL;
                        if (url) {
                          [self saveToFile:url.path];
                        }
                      }
                    }];
}

- (void)saveToFile:(NSString *)filePath {
  NSError *error = nil;
  NSString *content = self.textView.string;

  [content writeToFile:filePath
            atomically:YES
              encoding:NSUTF8StringEncoding
                 error:&error];

  if (error) {
    NSLog(@"Error saving file: %@", error.localizedDescription);

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Error Saving File";
    alert.informativeText = error.localizedDescription;
    [alert addButtonWithTitle:@"OK"];
    alert.alertStyle = NSAlertStyleCritical;
    [alert runModal];

    return;
  }

  self.currentFilePath = filePath;
  self.isDocumentModified = NO;
  [self updateWindowTitle];

  NSLog(@"File saved successfully: %@", filePath);
}

#pragma mark - Text Change Notification

- (void)textDidChange:(NSNotification *)notification {
  // Note: ScintillaView uses delegate pattern for notifications
  // We'll implement proper Scintilla notification handling in Phase 4B
  // For now, we'll track changes through save operations
  if (!self.isDocumentModified) {
    self.isDocumentModified = YES;
    [self updateWindowTitle];
  }
}

#pragma mark - Window Delegate

- (BOOL)windowShouldClose:(NSWindow *)sender {
  if (self.isDocumentModified) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Do you want to save changes?";
    alert.informativeText =
        @"Your changes will be lost if you don't save them.";
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Don't Save"];
    [alert addButtonWithTitle:@"Cancel"];

    NSModalResponse response = [alert runModal];

    if (response == NSAlertFirstButtonReturn) {
      [self saveDocument:nil];
      return YES;
    } else if (response == NSAlertThirdButtonReturn) {
      return NO; // Cancel close
    }
  }

  return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
  // Cleanup
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
