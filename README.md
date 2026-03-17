# prm393_project (Flutter + Firebase)

## TL;DR
- **What**: Flutter mobile app for room discovery + booking by hour, with role-based flows (User / Host / Admin).
- **Backend**: Firebase (Auth + Firestore + Messaging). Optional supporting services: Cloudinary, Google Maps.
- **Docs**: Detailed setup lives in `SETUP.md`.

## Project Metadata (for tools/LLMs)
- **App name**: `prm393_project` (from `pubspec.yaml`)
- **Dart SDK**: `^3.10.4`
- **Primary entrypoint**: `lib/main.dart`
- **Firebase config (generated)**: `lib/firebase_options.dart`
- **Firebase project id**: `prm393-project` (see `firebase.json`)
- **OpenAPI spec (3.1)**: `openapi.json` (Vietnam provinces API; used for location/divisions)

## Project Structure

models
- Firestore data models

dtos
- API / request response objects

services
- Firebase interaction
- Cloudinary upload
- booking logic

screens
- UI pages

widgets
- reusable UI components

utils
- helpers
- constants

## Table of Contents
- [Quickstart](#quickstart)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Capabilities (by role)](#capabilities-by-role)
- [Configuration](#configuration)
- [API / Integrations](#api--integrations)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Quickstart
Use `SETUP.md` as the source of truth for prerequisites, Firebase setup (including SHA-1), and running the app.

Minimal commands:

```bash
flutter pub get
flutter run
```

## Tech Stack
- **Frontend**: Flutter
- **Auth**: Firebase Authentication (Email/Password + Google Sign-In)
- **Database**: Cloud Firestore
- **Notifications**: Firebase Cloud Messaging + local notifications
- **Maps**: Google Maps API (integration)
- **Media**: Cloudinary (image hosting)
- **Payments**:
  - **COD**: current (enabled)
  - **VNPay / Credit Card**: planned (not fully enabled yet)

## Repository Structure
Top-level layout (high-signal directories/files):

```text
lib/               Flutter app source
android/ ios/      Mobile platform projects
web/ windows/      Additional platform targets
test/              Unit/widget tests
SETUP.md           Setup guide (prereqs + Firebase steps)
openapi.json       API contract used by the app (location/divisions)
firebase.json      Firebase project mapping / outputs
pubspec.yaml       Dependencies + assets (includes `.env`)
```

## Data Model (Firestore) — Must-have Schema
This section describes the **minimum required** Firestore collections/fields based on the current app code in `lib/`, plus the required additions for **voucher management**.

### Collections (overview)
- **`users/{uid}`**: user profile, role, auth provider, FCM token.
- **`rooms/{roomId}`**: host listings (rooms).
  - **`rooms/{roomId}/daily_prices/{yyyy-MM-dd}`**: per-date overrides (price / blocked).
- **`bookings/{bookingId}`**: booking records.
- **`notifications/{notificationId}`**: in-app notifications.
- **`chat_rooms/{roomId}`**: chat room metadata.
- **`messages/{messageId}`**: chat messages.
- **`host_requests/{requestId}`**: requests to become a host.
- **`properties/{hostId}`**: host property profile (stored as a doc keyed by `hostId`).
- **`orders/{orderId}`**: legacy/alternate booking/payment entity (used by `room_details_screen.dart`).
- **`daily_prices/{roomId_yyyy-MM-dd}`**: alternate daily price storage (used by `calendar_service.dart`).
- **Voucher management (new)**:
  - **`vouchers/{voucherId}`**: voucher definitions (host-scoped or global).
  - **`voucher_redemptions/{redemptionId}`** (recommended): per-user usage tracking (optional but strongly recommended).

### `users/{uid}` (required fields)
```json
{
  "email": "user@example.com",
  "authProvider": "email|google",
  "role": "USER|HOST|ADMIN",
  "createdAt": "Timestamp",

  "fullName": "string?",
  "phoneNumber": "string?",
  "address": "string?",
  "dateOfBirth": "Timestamp?",
  "displayName": "string?",
  "photoURL": "string?",

  "fcmToken": "string?"
}
```

### `rooms/{roomId}` (required fields)
This project currently has two room shapes in code history; the actively used service layer expects these fields:

```json
{
  "hostId": "string",
  "title": "string",
  "description": "string",
  "images": ["string"],
  "basePrice": 100000.0, // price per hour
  "status": "available|maintenance|unavailable",
  "quantity": 1,
  "amenities": ["wifi", "pool"],
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### `rooms/{roomId}/daily_prices/{yyyy-MM-dd}` (required fields)
```json
{
  "roomId": "string",
  "date": "Timestamp",
  "price": 120000.0,
  "isBlocked": false
}
```

### `bookings/{bookingId}` (required fields)
```json
{
  "roomId": "string",
  "roomTitle": "string",
  "userId": "string",
  "userName": "string",
  "hostId": "string",

  "checkIn": "Timestamp", // with time precision
  "checkOut": "Timestamp", // with time precision
  "guestCount": 2,
  "totalPrice": 240000.0,
  "status": "pending|confirmed|rejected|paid|completed|cancelled",
  "note": "string?",

  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

#### Booking voucher fields (required for voucher feature)
When a voucher is applied, store a **snapshot** on the booking (so historical totals don’t change if a voucher is edited later):

```json
{
  "voucherId": "string?",
  "voucherCode": "string?",
  "voucherScope": "HOST|GLOBAL?",
  "voucherHostId": "string?",
  "voucherDiscountAmount": 20000.0
}
```

### `vouchers/{voucherId}` (NEW — required fields)
```json
{
  "code": "SUMMER2026",

  "scope": "HOST|GLOBAL",
  "hostId": "string?", 

  "type": "PERCENT|FIXED",
  "value": 10,
  "maxDiscount": 50000,
  "minSubtotal": 100000,

  "startAt": "Timestamp?",
  "endAt": "Timestamp?",
  "isActive": true,

  "usageLimitTotal": 1000,
  "usageLimitPerUser": 1,

  "createdBy": "string",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

#### Voucher scope rules (must enforce)
- **Host voucher** (`scope=HOST`): valid only if **`booking.hostId == voucher.hostId`**.
- **Global voucher** (`scope=GLOBAL`): valid for **any booking**.

### `voucher_redemptions/{redemptionId}` (recommended)
Recommended for enforcing per-user limits without scanning all bookings.

```json
{
  "voucherId": "string",
  "userId": "string",
  "bookingId": "string",
  "createdAt": "Timestamp"
}
```

### Other collections used by current code (minimum fields)
`notifications/{notificationId}`:
```json
{
  "recipientId": "string",
  "title": "string",
  "body": "string",
  "type": "system|booking|host_request|chat",
  "relatedId": "string?",
  "isRead": false,
  "createdAt": "Timestamp"
}
```

`chat_rooms/{roomId}`:
```json
{
  "participants": ["uidA", "uidB"],
  "participantNames": { "uidA": "Alice", "uidB": "Bob" },
  "participantAvatars": { "uidA": "https://...", "uidB": "https://..." },
  "lastMessage": "string",
  "updatedAt": "Timestamp",
  "unreadCounts": { "uidA": 0, "uidB": 2 }
}
```

#### Chat constraint (must enforce): private 1:1 only
- The app only supports **private chats between 2 users** (no group chats).
- **Invariant**: `participants.length == 2`
- **Room ID strategy (current code)**: `roomId = "<min(uidA,uidB)>_<max(uidA,uidB)>"` to prevent duplicates.

`messages/{messageId}`:
```json
{
  "roomId": "string",
  "senderId": "string",
  "text": "string",
  "createdAt": "Timestamp"
}
```

`host_requests/{requestId}`:
```json
{
  "userId": "string",
  "businessName": "string",
  "phone": "string",
  "address": "string",
  "description": "string",
  "businessStartYear": 2020,
  "businessType": "private|business",
  "taxCode": "string?",
  "status": "pending|approved|rejected",
  "note": "string?",
  "createdAt": "Timestamp"
}
```

> `taxCode` is required only when `businessType == "business"`. Omitted (null) for private/individual operators.

`properties/{hostId}`:
```json
{
  "hostId": "string",
  "title": "string",
  "description": "string",
  "address": "string",
  "coverImage": "string",
  "policies": ["string"],
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### Notes (current codebase quirks)
- There are **two daily price storage patterns** in current code:
  - `rooms/{roomId}/daily_prices/{yyyy-MM-dd}` (used by `room_service.dart`)
  - `daily_prices/{roomId_yyyy-MM-dd}` (used by `calendar_service.dart`)
  Pick one as the long-term source of truth to reduce duplication.

## Capabilities (by role)
This section is intentionally written in a structured way for easy retrieval.

### User
- **Authentication & Security**
  - **Registration/Login**: session persistence + refresh token support
  - **Forgot password**: recovery via email
  - **OTP verification**: planned (coming soon)

- **Explore & Search**
  - **Homepage**: featured rooms + nearby rooms + categories
  - **Advanced search**: name, location, price range, guest count, check-in/out times
  - **Filters**: price sort, rating, amenities (wifi, pool, air conditioning, …)
  - **Map search**: Google Maps-based discovery

- **Room details & Booking**
  - **Details**: image carousel, description, rules, reviews
  - **Availability**: calendar-based selection with hour precision
  - **Booking flow**: total calculation based on floor-rounded hours + discount code/voucher + user info confirmation
  - **Status tracking**: Pending → Confirmed → Completed/Cancelled

- **Payment & Account**
  - **Payments**: COD is currently the only allowed method (VNPay / card planned)
  - **Manage bookings**: history, details, date change request, cancellation/refund
  - **Reviews**: star rating, comments, photo upload
  - **Profile**: update info, avatar, password

### Host
- **Room management**: create/edit/delete rooms; bulk update images/prices/status
- **Booking operations**: review guest requests; confirm/reject; direct chat
- **Calendar controls**: block/unblock slots; seasonal/period pricing
- **Revenue reports**: monthly/yearly stats; export report file
- **Voucher management (host-scoped)**:
  - Host-created vouchers can be applied to **any booking for that host’s rooms**.

### Admin
- **User management**: list users/hosts, roles/permissions, lock accounts
- **Room moderation**: approve before publishing; hide non-compliant listings
- **System coordination**: handle complaints, refunds, fraud control
- **Notifications**: system notifications + automated email events
- **Voucher management (global)**:
  - Admin-created vouchers can be applied **globally across the platform**.

## Voucher Rules (scope)
- **Host voucher**: created by a Host; valid for bookings where **booking.hostId == voucher.hostId**.
- **Global voucher**: created by Admin; valid for **any booking** on the platform.

## Configuration
### Firebase
- **Android**: requires `android/app/google-services.json` (not included by default in many repos)
- **Generated options**: `lib/firebase_options.dart` (can be generated via `flutterfire configure`)
- **Auth providers**: Email/Password + Google Sign-In (see `SETUP.md` for SHA-1 steps)

### Environment variables (`.env`)
`pubspec.yaml` includes `.env` as an asset, and the app uses `flutter_dotenv`.

- **File**: `.env`
- **Guidance**:
  - Treat `.env` as sensitive (do not store secrets in git history).
  - If you need to share expected keys, add a `.env.example` (recommended).

## API / Integrations
- **Location divisions API**:
  - **Contract**: `openapi.json`
  - **Base path** (per spec): `/api/v2`
  - **Purpose**: Vietnam provinces/divisions lookup (e.g., for address selection)

## Development
Common commands:

```bash
flutter clean
flutter pub get
flutter test
```

## Contributing
- Keep changes focused and update docs when behavior or setup changes.
- If you add new configuration keys, also update `.env.example` (recommended) and this README.

## License
TBD (add your license here).

## Notifications (in-app + device)
The app supports **two user-facing notification surfaces**:
- **In-app inbox**: documents in Firestore `notifications` filtered by `recipientId`.
- **Device notification**: FCM push to the device token stored at `users/{uid}.fcmToken`, displayed via local notifications.

### Delivery rule (recommended)
- **Write in-app first**, then attempt to send **FCM push** (so notifications are not lost if push fails).

### When to send notifications
#### Chat (private 1:1)
- **On message send**: notify the recipient (**in-app + device**).
- **On opening a chat room**: reset unread counter (`chat_rooms/{roomId}.unreadCounts.<uid> = 0`); optionally mark related in-app notifications as read.

#### Booking
- **On booking created (User → Host)**: notify Host (**in-app + device**).
- **On booking status change (Host/Admin → User)**: notify User (**in-app + device**).
- **On booking cancelled (either side)**: notify the other party (**in-app + device**).

#### Host request
- **On request submitted (User → Admin)**: notify Admin (**in-app + device**).
- **On request approved/rejected (Admin → User)**: notify User (**in-app + device**).

### When to avoid device push (anti-spam)
- **Bulk/system actions** (e.g., “mark all read”, batch updates): prefer **in-app only**.
- **User already actively viewing the relevant screen/room**: optionally **in-app only** (UX choice).