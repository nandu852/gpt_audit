# Project Management App

A complete Flutter application for managing projects with comprehensive audit logging, user authentication, and file attachments.

## Features

### 🔐 Authentication
- **Email/Password Sign Up & Sign In**: Create new accounts or sign in with existing credentials
- **Google Sign-In**: One-click authentication using Google accounts
- **User Profile Management**: Display names and email addresses
- **Secure Sign Out**: Proper session management

### 🏠 Home Dashboard
- **Welcome Screen**: Clean, modern interface with app branding
- **Quick Actions**: Add new projects, view existing projects, access audit logs
- **Navigation Drawer**: Easy access to all app sections
- **User Profile**: Quick access to user information and sign out

### 📝 Project Management
- **Create Projects**: Add new projects with company name, requirements, and specifications
- **Edit Projects**: Modify existing projects with change tracking
- **Project List**: View all projects with metadata (company, last modified, user)
- **Project Details**: Detailed view with activity history and attachments

### 📎 File Management
- **File Uploads**: Attach files to projects during creation or editing
- **Storage Integration**: Files stored securely in Firebase Storage
- **Metadata Tracking**: File names, sizes, and URLs logged for audit purposes

### 📊 Audit & Logging System
- **Comprehensive Logging**: Every action logged with user, timestamp, and details
- **Sequence Numbers**: Unique sequence numbers for each project's logs
- **Change Tracking**: Before/after values for all field modifications
- **Activity History**: Complete timeline of all project activities
- **Global Audit Logs**: View all system activities across all projects
- **Filtering**: Filter logs by action type, user, and date

### 🎨 User Interface
- **Material Design 3**: Modern, responsive UI following latest design standards
- **Form Validation**: Real-time validation with helpful error messages
- **Loading States**: Proper loading indicators during operations
- **Responsive Layout**: Works on various screen sizes and orientations

## Technical Architecture

### Backend Services
- **Firebase Authentication**: User management and security
- **Cloud Firestore**: Database for projects and audit logs
- **Firebase Storage**: File storage and management
- **Google Sign-In**: OAuth authentication provider

### Data Models
```
Projects Collection:
- project_id
- company_name
- requirements
- specifications
- created_by
- created_at
- updated_by
- updated_at
- log_sequence

Audit Logs Collection:
- log_id
- project_id
- action
- user_email
- user_name
- timestamp
- sequence
- summary
- changes (JSON diff)
- remarks
- attachments (metadata)
```

### Security Features
- **Authentication Required**: All operations require valid user session
- **User Isolation**: Users can only access their own data
- **Input Validation**: Server-side and client-side validation
- **Secure File Storage**: Files stored with proper access controls

## Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Firebase project with Authentication, Firestore, and Storage enabled

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   - Add `google-services.json` to `android/app/`
   - Enable Authentication, Firestore, and Storage in Firebase Console
   - Configure Google Sign-In in Firebase Console
4. Run `flutter run` to start the app

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.19.6
  cloud_firestore: ^4.17.5
  firebase_storage: ^11.7.7
  file_picker: ^8.0.3
  google_sign_in: ^6.2.1
```

## Usage Guide

### First Time Setup
1. Launch the app
2. Choose "Sign Up" to create a new account
3. Enter your display name, email, and password
4. Or use "Continue with Google" for quick setup

### Daily Usage
1. **Add Projects**: Use the "Add New Project" button to create projects
2. **Manage Projects**: View and edit existing projects from the project list
3. **Track Changes**: All modifications are automatically logged with timestamps
4. **Upload Files**: Attach relevant documents during project creation or editing
5. **Audit Trail**: Review complete project history and user activities

### Navigation
- **Home**: Main dashboard with quick actions
- **Projects**: List and manage all projects
- **Audit Logs**: View system-wide activity history
- **User Menu**: Access profile and sign out options

## Development Notes

### Code Structure
- **lib/main.dart**: App entry point with authentication gating
- **lib/auth.dart**: Complete authentication system
- **lib/projects.dart**: Home dashboard and navigation
- **lib/add_project.dart**: Project creation form
- **lib/edit_project_page.dart**: Project editing with change tracking
- **lib/existing_project.dart**: Project list and management
- **lib/project_details.dart**: Project details and file management
- **lib/audit_log_page.dart**: Global audit log viewer
- **lib/logging.dart**: Centralized audit logging system

### Key Features Implemented
- ✅ Complete authentication flow (sign up, sign in, Google auth)
- ✅ Project CRUD operations with validation
- ✅ File upload and storage integration
- ✅ Comprehensive audit logging with sequences
- ✅ Modern Material Design 3 UI
- ✅ Responsive navigation and user management
- ✅ Form validation and error handling
- ✅ Loading states and user feedback

### Future Enhancements
- User roles and permissions
- Project templates and workflows
- Advanced search and filtering
- Export functionality for reports
- Mobile push notifications
- Offline support and sync

## Troubleshooting

### Common Issues
1. **Firebase Configuration**: Ensure `google-services.json` is properly placed
2. **Google Sign-In**: Verify OAuth client ID is configured in Firebase Console
3. **File Uploads**: Check Firebase Storage rules and permissions
4. **Authentication**: Ensure Firebase Auth is enabled and configured

### Build Issues
- Run `flutter clean` and `flutter pub get` if dependencies are corrupted
- Verify Android SDK and build tools versions
- Check Firebase configuration in `firebase_options.dart`

## License

This project is for educational and development purposes. Please ensure compliance with Firebase and Google services terms of use.
