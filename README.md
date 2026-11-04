# Face Detection & Smile Analysis

A Flutter app for selecting a photo from the device gallery and analyzing it
with Google ML Kit Face Detection. The app outlines every detected face and
shows the total face count, the percentage of smiling faces, and each face's
smile probability. A smile is classified at a probability of 70% or higher.

## Run the app

This project uses `google_mlkit_face_detection`, which supports Android and
iOS. Run on an Android or iOS device or emulator:

```sh
flutter pub get
flutter run
```

Select **Upload Image** to choose a photo, then choose **Upload Another Image**
to analyze a different one. If no faces are detected, the face count and smiling
percentage are both shown as zero.
