# simulator_photo_import

simulator_photo_import makes it easy to populate the Photo Library in the iPhone Simulator for testing, etc.

1. Set `TSQImageImportPath` in `simulator_photo_import-Info.plist` to the path
   where your test images are. (e.g., `/Users/<myusername>/Pictures/iPhoto
   Library/Masters`)
2. Set `TSQTraverseSubdirectories` in `simulator_photo_import-Info.plist`. When
   set to `YES` any `.png` or `.jpg` image in any subdirectory of
   `TSQImageImportPath` will be added to the Photo Library. When set to `NO`,
   only files at the top level of `TSQImageImportPath` are added.
3. Run in the Simulator.
4. Press the 'Start' button.

Special thanks to the very fine folks at [Everyme](http://everyme.com) for
giving me the idea and letting me work on it in their office.
