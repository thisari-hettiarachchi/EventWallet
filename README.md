# eventwallet

A Flutter event-planning app with Firebase-backed bookings, provider discovery, and booking-linked in-app chat.

## Booking chat feature

The app now includes in-app messaging between the client and the service provider for each booking.

### What’s included

- Booking-based chat thread keyed by `bookingId`
- User ↔ provider text messaging
- Unread message counts per participant
- Last-message preview in the thread list
- Booking summary shown inside each chat thread
- Inbox entry points from both user and provider booking pages

### Firestore structure

- `bookings/{bookingId}`
- `booking_chats/{bookingId}`
- `booking_chats/{bookingId}/messages/{messageId}`

Thread documents store lightweight metadata such as:

- `bookingId`
- `userId`
- `providerId`
- `clientName`
- `providerName`
- `eventName`
- `selectedPackage`
- `bookingStatus`
- `lastMessage`
- `lastMessageAt`
- `lastMessageSenderId`
- `unreadCounts.{uid}`

## Testing

Run the service tests with:

```powershell
flutter test test\services\booking_service_test.dart test\services\chat_service_test.dart
```

## Getting Started

Helpful Flutter resources:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)
