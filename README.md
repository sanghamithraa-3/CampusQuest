# CampusQuest

CampusQuest is a Flutter Android app for recording student activities, reviewing submissions as faculty, and building a portfolio from approved achievements.

## Included flows

- Student and faculty entry screens with college email validation.
- Student home, quest discovery, achievement submission, portfolio, and profile pages.
- Faculty review queue with approve and request-changes actions.
- Approved achievements appear in the student portfolio; pending and returned items stay private.
- Submission and review data persists in the app's private Android storage.
- Responsive Material 3 layouts and bottom-tab navigation.

## Run

Open `campus_quest_app` in Android Studio or VS Code with the Flutter extension, select an Android emulator/device, then run the app. The app uses Flutter SDK components only and has no third-party Dart packages to install.

## Current data mode

The app currently runs as a local demo: the sign-in screen validates an email and password format, and the selected role is for previewing each interface. It does not authenticate users or synchronize records between devices. Faculty review and student records share the app's local demo store.

For a college deployment, connect Firebase Authentication, Cloud Firestore, and Cloud Storage; configure the campus email domain; assign faculty access and review categories from an administrator-managed roster; and add Firestore/Storage security rules before publishing. Firebase project credentials and the college's approved email domain were not present in the workspace, so the app is structured as a working UI/demo without pretending to enforce institutional access controls.
