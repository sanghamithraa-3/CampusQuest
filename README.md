# Campus Quest

### A Digital Achievement Management and Portfolio Generation Platform

Campus Quest is a college-focused application designed to help students maintain a centralized record of their academic, co-curricular, extracurricular, and other achievements. Students can submit their achievements with certificate links and generate a professional digital portfolio that showcases their accomplishments.

The platform also provides an administrator interface for managing student accounts and achievement records, making achievement documentation more organized and accessible within a college.

## Features

### Student
- **Secure Authentication:** Register and log in using college email and password.
- **Achievement Management:** Add, view, edit, and manage personal achievement records.
- **Certificate Links:** Attach certificate URLs as supporting evidence.
- **Digital Portfolio:** Generate a consolidated portfolio containing submitted achievements.
- **Portfolio Download:** Download a professionally formatted PDF portfolio.
- **Personalized Records:** Maintain achievement details in one centralized location.

### Administrator
- **Student Management:** View and manage student accounts.
- **Account Control:** Deactivate student accounts when necessary.
- **Achievement Management:** View, edit, and delete achievement records.
- **Portfolio Access:** View and download portfolios for individual students.
- **Centralized Administration:** Manage student and achievement data through an administrator interface.

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Mobile and Web Frontend | Flutter, Dart |
| Backend | Node.js, Express.js |
| Database | MongoDB Atlas |
| Authentication | JWT |
| Password Security | bcrypt |
| API Communication | REST API |
| Portfolio Generation | PDF generation library |
| Development Tools | Visual Studio Code, Git, GitHub |

## Project Structure

```text
CampusQuest/
├── backend/
│   ├── config/
│   ├── controllers/
│   ├── middleware/
│   ├── models/
│   ├── routes/
│   ├── scripts/
│   ├── services/
│   ├── tests/
│   ├── .env.example
│   ├── package.json
│   └── server.js
│
├── frontend/
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── theme/
│   │   └── widgets/
│   ├── android/
│   ├── web/
│   └── pubspec.yaml
│
├── .gitignore
└── README.md
```

*The directory listing is illustrative; actual filenames may vary slightly.*

## Prerequisites

Install the following before running the project:

- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Visual Studio Code](https://code.visualstudio.com/)
- A MongoDB Atlas account or another compatible MongoDB deployment

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/sanghamithraa-3/CampusQuest.git
cd CampusQuest
```

### 2. Configure the Backend

Navigate to the backend directory:

```bash
cd backend
npm install
```

Create a local `.env` file using `.env.example` as a reference. Fill in the required MongoDB connection string, JWT secret, port, and other variables required by the backend.

**Important:** Never commit `.env` files, database credentials, or production secrets to GitHub.

### 3. Start the Backend Server

Run the development script configured in `package.json`:

```bash
npm run dev
```

If that script is unavailable, run `npm run` to inspect the available scripts.

The API is expected to run at:

```text
http://localhost:5000
```

The API base URL used by the frontend is:

```text
http://localhost:5000/api
```

These addresses assume the default local development configuration.

### 4. Configure the Flutter Frontend

Open a second terminal and navigate to the frontend:

```bash
cd frontend
flutter pub get
```

### 5. Run the Application

To run the web application in Chrome:

```bash
flutter run -d chrome
```

To run on a connected Android device, enable USB debugging and verify that Flutter detects the device:

```bash
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with the ID displayed by Flutter.

### 6. Configure the API URL for Deployment

For a production web build, supply the deployed backend URL if the application supports the `API_BASE_URL` compile-time variable:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-backend-domain/api
```

Replace the example domain with your actual deployed API address. Configure the production backend with HTTPS and the appropriate CORS origins.

## 🔐 Security

Campus Quest incorporates security measures such as:

- Password hashing using bcrypt.
- JWT-based authentication.
- Backend role-based authorization.
- Server-side request validation.
- Protection against unauthorized access to student records.
- Environment-based configuration for sensitive credentials.
- Database checks to prevent deactivated accounts from accessing protected routes.

Security depends on correct configuration and deployment. Keep dependencies updated, restrict database network access, and use HTTPS in production.

## 📄 Portfolio Generation

Students can generate a PDF portfolio containing their personal details and achievement records. The portfolio is designed to present achievements in a structured, professional format, including details such as achievement title, category, date, description, and certificate URL.

## 🧪 Testing

To run the backend tests:

```bash
cd backend
npm test
```

The test suite checks supported backend functionality and validation behavior. Additional frontend, integration, and deployment testing should be performed before production use.

## 🔮 Future Enhancements

Potential future improvements include:

- College-specific deployment and configuration.
- Advanced portfolio templates and customization.
- Improved search and filtering for achievement records.
- Analytics for institutional achievement documentation.
- Automated backup and recovery procedures.
- Additional accessibility and usability improvements.

## 🎯 Project Objective

The primary objective of Campus Quest is to simplify achievement documentation, reduce scattered record-keeping, and help students maintain a reusable digital portfolio for academic, internship, placement, and career opportunities.

## 👩‍💻 Developer

**Sanghamithraa E**  
BE Computer Science and Engineering  
Thiagarajar College of Engineering, Madurai

## 📜 License

A license has not yet been specified. Add a suitable open-source license before distributing the project for reuse.
