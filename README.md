# Campus Plug

Welcome to **Campus Plug**, a campus marketplace platform connecting student vendors with buyers. This project is a comprehensive solution designed to enable users to browse products, place orders, and communicate directly with vendors within a campus environment.

## Project Structure

The repository is structured into several components:

- **`mobile_app/`**: The primary user interface built with Flutter. It serves both buyers and vendors.
- **`admin_dashboard/`**: (Planned/In Progress) A dashboard for platform administrators to monitor activity and manage users/vendors.
- **`backend/`**: (Planned/In Progress) Reserved for custom backend logic or serverless functions (e.g., Firebase Cloud Functions).
- **`docs/`**: Documentation for the project.

## Tech Stack

- **Frontend (Mobile)**: [Flutter](https://flutter.dev/) & Dart. State management is handled via `provider`.
- **Backend & Database**: [Firebase](https://firebase.google.com/)
  - **Firebase Authentication**: User and vendor login/signup.
  - **Cloud Firestore**: NoSQL database for structured data.
  - **Firebase Storage**: For storing product images and user media.

## Features

Based on the database schema and rules, the platform supports:
- **User Management**: Authentication and profile management for buyers and vendors.
- **Vendor Listings**: Dedicated profiles and listings for vendors to showcase their goods.
- **Product Catalog**: Browsing, creating, and managing products.
- **Order Management**: Tracking purchases and order fulfillment for both customers and vendors.
- **Reviews**: Users can leave feedback on products/vendors.
- **Real-time Chat**: In-app messaging system connecting buyers and vendors securely.

## Prerequisites & Setup

### Mobile App Development
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Ensure you have the Android toolchain or Xcode installed for mobile development.
3. Run the setup script for Android (if applicable) located at `setup_android.ps1`.
4. Navigate to the `mobile_app` directory:
   ```bash
   cd mobile_app
   ```
5. Install dependencies:
   ```bash
   flutter pub get
   ```
6. Run the app:
   ```bash
   flutter run
   ```

### Firebase Configuration
The project requires a Firebase project. Make sure you have the Firebase CLI installed to deploy rules:
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

## Security Rules

The application uses strict Firebase Security Rules (`firestore.rules` and `storage.rules`) to ensure data privacy:
- Users can only modify their own profiles.
- Products can only be modified by their owning vendor.
- Chats and messages are strictly restricted to the participants of the conversation.
- Orders are restricted to the customer who placed them and the vendor fulfilling them.

## Assets
The `mobile_app/assets/` folder contains app-specific assets like the `campus_plug_logo.png` and authentication illustrations. Typography is powered by `google_fonts`.