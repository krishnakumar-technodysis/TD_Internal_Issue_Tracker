# td_issue_tracking_portal

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Deploy

flutter clean
flutter build web --release

firebase login
firebase init hosting
Use an existing project → choose your Firebase project
What do you want to use as your public directory? - > build/web
✔ Configure as single-page app (rewrite all urls to /index.html)? → YES
✔ Set up automatic builds? → NO
firebase deploy --only hosting

