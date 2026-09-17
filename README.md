# Campus Companion — Role-Based Campus Management System

> A real-time mobile campus management platform that connects students, faculty, class representatives, staff, and administrators through a centralized, role-based system.

Campus Companion is a full-stack mobile application designed to simplify everyday academic and campus operations. It provides students with quick access to timetables, faculty information, classroom availability, events, and notifications while giving administrators and class representatives tools to manage and communicate important campus information.

---

## 📌 Problem Statement

Students often depend on manually shared timetables, class representatives, notice boards, or direct communication to find information such as:

* Where a class is being conducted
* Which classrooms are currently available
* Where a faculty member is located
* Whether a classroom has been changed
* What events or announcements are happening
* What their current academic schedule looks like

This creates unnecessary communication overhead and makes frequently changing information difficult to maintain.

Campus Companion addresses this by providing a centralized platform where academic and campus information can be managed and accessed according to the user's role.

---

## 🎯 Objectives

* Centralize frequently used campus information.
* Provide role-specific access to application features.
* Make timetable and classroom information easily accessible.
* Help students locate available classrooms.
* Simplify faculty discovery.
* Allow Class Representatives to communicate classroom changes.
* Provide administrators with centralized management capabilities.
* Reduce dependency on manual communication for routine campus information.

---

# ✨ Key Features

## 🔐 Role-Based Authentication

The application supports **five user roles**, each with different permissions:

| Role                 | Main Capabilities                                                  |
| -------------------- | ------------------------------------------------------------------ |
| Student              | Timetable, classroom search, faculty search, events, notifications |
| Class Representative | Student features + classroom updates and section notifications     |
| Faculty              | Teaching schedule, profile, cabin information                      |
| Staff                | Administrative information management                              |
| Admin                | User, course, timetable, event and system management               |

Authentication is implemented using **JWT**, while passwords are securely hashed using **bcrypt**.

---

## 📅 Dynamic Timetable

The timetable system allows administrators to manage academic schedules centrally.

Features include:

* Semester-based timetable management
* Branch and section-specific schedules
* Subject allocation
* Faculty allocation
* Classroom information
* Timetable creation and editing
* Dynamic timetable retrieval

The timetable is connected to the course information rather than relying on a completely independent static dataset.

### Example hierarchy

```text
Semester
   │
   ├── Branch
   │      │
   │      └── Section
   │             │
   │             └── Timetable
   │                    ├── Subject
   │                    ├── Faculty
   │                    └── Classroom
```

---

# 🏫 Empty Classroom Finder

One of the core features of Campus Companion is the **Empty Classroom Finder**.

Students can determine which classrooms are available based on the timetable and selected time slot.

### Workflow

```text
Select Day
    ↓
Select Time Slot
    ↓
Retrieve Timetable
    ↓
Identify Occupied Classrooms
    ↓
Compare Available Rooms
    ↓
Display Empty Classrooms
```

This can help students find spaces for:

* Self-study
* Group discussions
* Project work
* Club activities
* Meetings

---

# 👨‍🏫 Faculty Search

Students can search for faculty members and access relevant information such as:

* Faculty name
* Department
* Subject
* Cabin information
* Contact information

This reduces the need to manually ask classmates or representatives for faculty location details.

---

# 🔔 Classroom Change Notifications

Class Representatives can update classroom information when a class is moved.

The workflow is:

```text
Class Representative
        ↓
Updates Classroom
        ↓
Backend Processes Update
        ↓
Notification Generated
        ↓
Students Receive Update
```

This is particularly useful when classroom changes occur shortly before a lecture.

---

# 📢 Events & Announcements

The application provides a centralized location for campus events and announcements.

Administrators can manage event information while students can view upcoming activities.

Examples include:

* Workshops
* Seminars
* Club activities
* Campus events
* Important announcements

---

# 👤 Profile Management

Users can manage their profile information through the application.

Features include:

* View profile
* Update profile information
* Change password
* Upload profile picture

Profile images are stored using **Cloudinary**.

---

# 🛠️ Admin Dashboard

Administrators have centralized control over important campus data.

The dashboard provides management capabilities for:

* Users
* Courses
* Timetables
* Faculty information
* Events
* Other application data

CRUD operations are exposed through protected REST APIs.

---

# 🗄️ Database Design

The application uses **MongoDB Atlas** as its primary database.

### Main Collections

```text
Users
Courses
Timetables
Events
Notifications
```

### Users

Stores user authentication and role information.

```text
User
├── Name
├── Email
├── Password
├── Role
├── Roll Number
├── Branch
├── Semester
├── Section
└── Profile Image
```

### Courses

Stores academic course information.

```text
Course
├── Subject
├── Subject Code
├── Faculty
├── Semester
├── Branch
├── Section
└── Color Code
```

### Timetables

Stores scheduled academic sessions.

```text
Timetable
├── Semester
├── Branch
├── Section
├── Day
├── Time Slot
├── Subject
├── Faculty
└── Classroom
```

### Events

Stores campus event information.

```text
Event
├── Title
├── Description
├── Date
├── Image
└── Created By
```

### Notifications

Stores notification information used for communicating important updates.

```text
Notification
├── Title
├── Message
├── Recipient
├── Type
├── Created At
└── Status
```

---

# 🏗️ System Architecture

Campus Companion follows a client-server architecture.

```text
                    ┌─────────────────────┐
                    │     Flutter App     │
                    │   Mobile Frontend   │
                    └──────────┬──────────┘
                               │
                         HTTP / REST
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Node.js + Express  │
                    │      REST API        │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
        Authentication    Business Logic    File Handling
              │                │                │
              │                │                ▼
              │                │           Cloudinary
              │                │
              └────────────────┼────────────────┐
                               ▼                │
                    ┌─────────────────────┐     │
                    │    MongoDB Atlas    │     │
                    │      Database       │     │
                    └─────────────────────┘     │
```

---

# 🔄 Authentication Flow

```text
User
 │
 │ Email + Password
 ▼
Flutter Application
 │
 │ POST /login
 ▼
Express API
 │
 ▼
Validate Credentials
 │
 ├── bcrypt password verification
 │
 ▼
Generate JWT
 │
 ▼
Return Token
 │
 ▼
Flutter Secure Storage
 │
 ▼
Authenticated API Requests
```

Protected endpoints validate the JWT before allowing access to restricted resources.

---

# 🔑 Security

The application implements several security mechanisms:

* JWT-based authentication
* bcrypt password hashing
* Protected REST endpoints
* Role-Based Access Control
* Secure token storage
* Authenticated administrative operations
* Controlled file uploads through Cloudinary

---

# 🌐 REST API

The backend exposes approximately **25–30 REST APIs** across different modules.

### Major API categories

```text
Authentication
      │
      ├── Login
      ├── Change Password
      └── Authentication / User Verification

Users
      │
      ├── Create User
      ├── Get Users
      ├── Update User
      ├── Delete User
      └── Search Faculty

Courses
      │
      ├── Create Course
      ├── Get Courses
      ├── Update Course
      └── Delete Course

Timetable
      │
      ├── Create Timetable
      ├── Get Timetable
      ├── Update Timetable
      └── Update Classroom

Events
      │
      ├── Create Event
      ├── Get Events
      ├── Update Event
      └── Delete Event

Notifications
      │
      ├── Create / Send Notification
      └── Retrieve Notifications
```

---

# 📱 Application Modules

The project consists of approximately **10 major functional modules**:

1. Authentication
2. User Management
3. Profile Management
4. Timetable Management
5. Course Management
6. Empty Classroom Finder
7. Faculty Search
8. Events & Announcements
9. Notifications
10. Admin Dashboard

---

# 🧰 Technology Stack

## Frontend

* Flutter
* Dart
* Flutter Secure Storage
* REST API Integration

## Backend

* Node.js
* Express.js
* JavaScript
* REST APIs

## Database

* MongoDB
* MongoDB Atlas
* Mongoose

## Authentication & Security

* JSON Web Tokens (JWT)
* bcrypt

## Cloud Services

* Cloudinary — Profile image storage
* MongoDB Atlas — Cloud database

## Development Tools

* Android Studio
* Visual Studio Code
* Git
* GitHub
* Postman

---

# 📂 Project Structure

```text
Campus-Companion/
│
├── backend/
│   │
│   ├── config/
│   │
│   ├── controllers/
│   │   ├── userController.js
│   │   └── ...
│   │
│   ├── middleware/
│   │   ├── auth.js
│   │   ├── upload.js
│   │   └── ...
│   │
│   ├── models/
│   │   ├── User.js
│   │   ├── Course.js
│   │   ├── Timetable.js
│   │   ├── Event.js
│   │   └── Notification.js
│   │
│   ├── routes/
│   │   ├── auth.js
│   │   ├── user.js
│   │   ├── course.js
│   │   ├── timetable.js
│   │   └── ...
│   │
│   ├── utils/
│   │
│   ├── .env
│   ├── server.js
│   └── package.json
│
├── frontend/
│   │
│   ├── lib/
│   │   ├── pages/
│   │   │   ├── home_page.dart
│   │   │   ├── timetable_page.dart
│   │   │   ├── find_teacher_page.dart
│   │   │   ├── find_classroom_page.dart
│   │   │   ├── admin_homepage.dart
│   │   │   └── ...
│   │   │
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   │
│   │   ├── models/
│   │   ├── widgets/
│   │   └── main.dart
│   │
│   ├── assets/
│   └── pubspec.yaml
│
└── README.md
```

---

# ⚙️ Installation & Setup

## Prerequisites

Make sure the following are installed:

* Flutter SDK
* Dart SDK
* Node.js
* npm
* MongoDB Atlas account
* Cloudinary account
* Android Studio / Android SDK
* Git

---

## 1. Clone the Repository

```bash
git clone https://github.com/your-username/campus-companion.git

cd campus-companion
```

---

# 2. Backend Setup

Navigate to the backend:

```bash
cd backend
```

Install dependencies:

```bash
npm install
```

Create a `.env` file:

```env
PORT=4000

MONGO_URI=your_mongodb_connection_string

JWT_SECRET=your_jwt_secret

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

Start the development server:

```bash
npm run dev
```

The backend will run on:

```text
http://localhost:4000
```

---

# 3. Flutter Setup

Open a new terminal:

```bash
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

Check connected devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

---

# 📡 API Configuration

The Flutter application communicates with the backend through a centralized API service.

Example:

```dart
class ApiService {
  static const String baseUrl = "http://10.0.2.2:4000";
}
```

For a physical Android device, replace the emulator address with the local machine's network IP when required.

---

# 🧪 Testing

The REST APIs can be tested using tools such as **Postman**.

Typical testing flow:

```text
Login
  ↓
Receive JWT
  ↓
Add Authorization Header
  ↓
Call Protected Endpoint
  ↓
Verify Response
```

Example authorization header:

```text
Authorization: Bearer <JWT_TOKEN>
```

---

# 🚀 Current Deployment

The application was developed and tested using:

```text
Flutter Application
        ↓
Local Node.js / Express Server
        ↓
MongoDB Atlas
        ↓
Cloudinary
```

The backend is currently intended for development/testing rather than production deployment.

---

# 👥 Team

**Team Size:** 4 Members

### Role

**Project Lead & Full-Stack Developer**

Responsibilities included:

* System architecture
* Backend development
* Flutter application development
* REST API development
* MongoDB schema design
* JWT authentication
* Role-Based Access Control
* Cloudinary integration
* Feature integration
* Project coordination

---

# 📊 Project Snapshot

| Metric              | Details                             |
| ------------------- | ----------------------------------- |
| Platform            | Flutter Mobile Application          |
| Backend             | Node.js + Express.js                |
| Database            | MongoDB Atlas                       |
| Cloud Storage       | Cloudinary                          |
| Authentication      | JWT + bcrypt                        |
| User Roles          | 5                                   |
| Core Modules        | ~10                                 |
| REST APIs           | ~25–30                              |
| MongoDB Collections | 5                                   |
| Team Size           | 4                                   |
| Role                | Project Lead & Full-Stack Developer |
| Deployment          | Local Backend + Cloud Database      |

---

# 🧠 Key Technical Highlights

### Role-Based Access Control

Five distinct roles are handled through authorization logic rather than simply displaying different UI screens.

```text
JWT
 ↓
Authentication Middleware
 ↓
Identify User
 ↓
Check Role
 ↓
Authorize / Reject Request
```

---

### Dynamic Data Relationships

The timetable and course data are structured around:

```text
Semester
    ↓
Branch
    ↓
Section
    ↓
Courses
    ↓
Faculty
    ↓
Timetable
    ↓
Classroom
```

This allows changes to academic information to propagate through the application's relevant workflows rather than requiring completely separate static datasets.

---

### Centralized API Layer

The Flutter frontend communicates with the backend through a dedicated API service, keeping HTTP communication separate from individual UI screens.

This improves maintainability and makes backend endpoints easier to modify without rewriting application screens.

---

# 🔮 Future Enhancements

Potential future improvements include:

* Firebase Cloud Messaging for production push notifications
* QR-based attendance
* Smart classroom booking
* Campus bus tracking
* Lost & Found module
* Complaint management
* Library integration
* Examination schedule
* Placement notifications
* Indoor campus navigation
* AI-powered campus assistant
* AI-based timetable optimization

---

# ⚠️ Known Limitations

* The backend is currently designed primarily for local development/testing.
* Classroom availability depends on the accuracy of the stored timetable.
* The Empty Classroom Finder cannot determine physical occupancy; it determines availability from scheduled timetable data.
* Production deployment and infrastructure scaling have not yet been implemented.
* Notification delivery requires proper production push-notification infrastructure.

---

# 📸 Screenshots

Add screenshots of the following screens here:

```text
Login
Dashboard
Timetable
Empty Classroom Finder
Faculty Search
Events
Profile
Admin Dashboard
```

Example:

```markdown
![Login Screen](screenshots/login.png)

![Dashboard](screenshots/dashboard.png)

![Timetable](screenshots/timetable.png)

![Empty Classroom Finder](screenshots/classroom.png)
```

---

# 🔗 Future Documentation

The project can be extended with:

* API documentation using Swagger/OpenAPI
* Database ER diagrams
* System architecture diagrams
* API request/response examples
* Deployment documentation
* Contribution guidelines

---

# 📄 License

This project was developed as an academic software project and is intended for educational and demonstration purposes.

---

## 👨‍💻 Author

**Sai Samay**

Project Lead & Full-Stack Developer

Technologies:

```text
Flutter • Dart • Node.js • Express.js • MongoDB
JWT • REST APIs • Cloudinary • Git
```
