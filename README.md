# YEM Events 🎉

A full-stack event management app built with Flutter and Firebase. Users can create, discover, and RSVP to events — with real-time push notifications and email confirmations on every RSVP.

---

## Screenshots

| Login | Home | Event Detail |
|-------|------|--------------|
| ![Login](screenshots/login.png) | ![Home](screenshots/home.png) | ![Detail](screenshots/detail.png) |

| Create Event | Profile |
|--------------|---------|
| ![Create](screenshots/create.png) | ![Profile](screenshots/profile.png) |

---

## Features

- **Authentication** — Email/password signup and login with Firebase Auth. Display name set on registration.
- **Event discovery** — Browse all upcoming events with rich cards showing image, date, location and host.
- **Search & filter** — Search events by keyword or location. Filter by date range.
- **Create events** — Add title, description, location, date/time and an optional image (uploaded to ImgBB).
- **Edit & delete events** — Creators can update or remove their events with full image management.
- **RSVP system** — One-tap RSVP with live attendee count and attendee list.
- **Push notifications** — Event creators receive a push notification via FCM when someone RSVPs.
- **Email notifications** — Attendees receive a confirmation email; creators receive an RSVP alert email via EmailJS.
- **Profile page** — View account info, edit display name, and sign out.
- **Real-time updates** — All data syncs live via Firestore streams — no refresh needed.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x |
| State management | Riverpod 3.x |
| Backend | Firebase (Auth, Firestore, Cloud Messaging) |
| Image hosting | ImgBB API |
| Email | EmailJS |
| Push notifications | FCM v1 API with service account auth |
| Architecture | Feature-first with repository pattern |

---

## Project Structure

```
lib/
├── app/                        # App entry point and routing
├── core/
│   └── services/
│       ├── notification_service.dart
│       └── email_service.dart
└── features/
    ├── auth/
    │   ├── data/repositories/
    │   ├── domains/models/
    │   └── presentation/
    │       ├── pages/
    │       └── providers/
    └── events/
        ├── data/repositories/
        └── domains/models/
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Firebase project with Auth, Firestore and Cloud Messaging enabled
- ImgBB account (for image uploads)
- EmailJS account (for email notifications)

### Setup

**1. Clone the repository**
```bash
git clone https://github.com/Hardeyemmy/yem-events-signature
cd yem-events-signature
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure Firebase**

Run FlutterFire CLI to connect your Firebase project:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

**4. Create a `.env` file** in the project root:
```env
FCM_PROJECT_ID=your-firebase-project-id
FCM_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
FCM_CLIENT_ID=your-client-id
FCM_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n
EMAILJS_SERVICE_ID=your_service_id
EMAILJS_TEMPLATE_CONFIRMATION=your_template_id
EMAILJS_TEMPLATE_CREATOR_NOTIFY=your_template_id
EMAILJS_PUBLIC_KEY=your_public_key
IMGBBAPI_KEY=your_imgbb_key
```

**5. Run the app**
```bash
flutter run
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /events/{eventId} {
      allow read: if true;
      allow create: if request.auth != null
        && request.resource.data.creatorId == request.auth.uid
        && request.resource.data.title.size() >= 5
        && request.resource.data.date > request.time;
      allow update, delete: if request.auth.uid == resource.data.creatorId
        && request.resource.data.creatorId == resource.data.creatorId;
      match /attendees/{userId} {
        allow read: if true;
        allow create, delete: if request.auth.uid == userId;
      }
    }
    match /notifications/{notifId} {
      allow create: if request.auth != null;
      allow read, update, delete: if request.auth != null;
    }
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `FCM_PROJECT_ID` | Firebase project ID |
| `FCM_CLIENT_EMAIL` | Service account email |
| `FCM_CLIENT_ID` | Service account client ID |
| `FCM_PRIVATE_KEY` | Service account private key |
| `EMAILJS_SERVICE_ID` | EmailJS service ID |
| `EMAILJS_TEMPLATE_CONFIRMATION` | EmailJS RSVP confirmation template ID |
| `EMAILJS_TEMPLATE_CREATOR_NOTIFY` | EmailJS creator notification template ID |
| `EMAILJS_PUBLIC_KEY` | EmailJS public key |
| `IMGBBAPI_KEY` | ImgBB API key for image uploads |



---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## License

MIT
