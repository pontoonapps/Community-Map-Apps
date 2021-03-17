# CommunityMap (Android & iOS)
Android and iOS version of the Community Map 
Community is a mobile app which is able to link Community groups, teams or services together with their members. The Training Centres or Services can place pins of locations they want their members to know about on a map and then share them via email with those members. The users can remove themselves from services they do not wish to see, filter the pins by category and see all information the Service has provided.

<p align="center">
  <img src="interregLogo.png" width="400" title="Interreg Logo">
</p>

## About PONToon
PONToon is an exciting project that will use a range of new and developing technologies such as games development, 3D/virtual reality, social media and web/mobile apps to engage, support and up-skill women in order to aid their employment opportunities.

The project is centred around community development, social and economic inclusion and equality. It aims to produce a method of working that's not only scalable and transferrable but also applicable to broader demographic sets and geographical regions for continuing impact.

PONToon will employ digital tools and methods to provide equal access to training and employment services in response to the digital skills shortage existing across all sectors of work. PONToon will provide a more flexible approach to existing training/employment services increasing efficiency and quality due to the dual effect of the toolkit enhancing both technical digital skills and core competencies for employment.
```bash
Budget received from the France (Channel) England Programme: €4 million ERDF
Total Project Budget: €5.79 million
Project Duration: 3.5 years
```

## Building Android
1) Open PONToonMap folder with Android Studio and wait for gradle files to be installed if required.
2) Build.

GOOGLE_MAPS_API_KEY
An API key must be set up and set in gradle.properties
https://developers.google.com/maps/documentation/javascript/get-api-key

## Building iOS
1) Set up cocapods, https://guides.cocoapods.org/using/getting-started.html
2) In terminal: pod install
3) Open pontoons-map.xcworkspace with Xcode.
4) Build.

GOOGLE_MAPS_API_KEY
An API key must be set up and set in AppDelegate.swift\
https://developers.google.com/maps/documentation/javascript/get-api-key}


To use this app you will need the Community API: https://github.com/pontoonapps/Community-API

