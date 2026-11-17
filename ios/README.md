# Daybook for iPhone

The iOS app is a native SwiftUI app. Its bookings, registered clients, package templates, and client session balances are stored on the device with SwiftData; it has no account, server, or network sync. Package templates can be selected when registering clients. Editing or deleting a template does not change packages already assigned to clients. A registered client's balance decreases when a new booking uses their package and is restored if that booking is deleted. Package renewals start a new balance cycle, and clients with two or fewer sessions remaining are marked as almost done.

## Open and run

1. Use a Mac with Xcode 15 or later.
2. Open `ios/Daybook.xcodeproj` in Xcode.
3. Select the Daybook target and set your Apple development team under **Signing & Capabilities**.
4. Choose an iPhone simulator or connected iPhone and press **Run**.

The app targets iOS 17 and later. The original `index.html` in the workspace is still the web prototype; the native iPhone implementation lives in `ios/`.

Bookings are stored locally on the device. They are not shared across devices, and deleting the app may remove its local data.
