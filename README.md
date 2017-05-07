# Tiny Album
This is a small application that helps people to store their photos with searchable text. All data will be stored in the cloud. People still can access viewed content even the network is not available.

## Features
* Easy Search
* Cloud Base
* Simple Interface

## Usage
*You need to create an account*

Q: *How to create an album?*  
A: click on the ADD icon and enter any name you want, then click on button - create.

Q: *How to add photos into an album?*  
A: Option #1, You can click on the CAMERA icon to take a photo, and the photo will save into the album automatically. Option #2, You can click on the G icon to download the photos from Google Image, then you can tap on any picture for saving it into the album.

Q: *How to delete photos in an album?*  
A: Click on the RECYCLE-BIN icon to enter the removal mode, then tap on any unwanted picture; Finally click on the RECYCLE-BIN icon again to quit the removal mode.

Q: *How to delete an ablum*  
A: Swipe the album name to left, then click on button - delete.

## Build
```
1. Install CocoaPods
$ sudo gem install cocoapods

2. Under the project directory, Install all required library
$ pod install

3. Click on tinyalbum.xcworkspace to open the project
```

## Libraries & APIs
* Parse
* ParseUI
* Google Image Search API

## Known Bugs
1. Library ParseUI - showing pagination causes an out-of-range exception when there's an error on loading data from Parse server (Example: refresh data while the network is disconnected)

## License
Free to all
