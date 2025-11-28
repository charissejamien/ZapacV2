# 🚍 ZAPAC – Zap Around Cebu

**ZAPAC** is a real-time commuter tracking app designed to make commuting around Cebu faster, safer, and more convenient. It helps users view nearby jeepney and bus routes, track vehicle locations, and save favorites — all in one seamless mobile experience.

---

## 📱 Features

- 🔐 **User Authentication** – Secure login and registration using Firebase Auth  
- 🗺️ **Live Map Tracking** – View real-time locations of public vehicles  
- ⭐ **Favorite Routes** – Save frequently used routes for easy access  
- 📝 **Commuter Insights** – Submit feedback, comments, or reports  
- 🧑‍💼 **Profile Management** – Manage personal account, dark mode, and preferences  
- 🌗 **Light & Dark Mode** – For comfortable use, day or night

---

## 🛠️ Built With

| Tech | Purpose |
|------|---------|
| [Flutter](https://flutter.dev/) | Cross-platform mobile app framework  
| [Firebase Auth](https://firebase.google.com/products/auth) | User login & registration  
| [Cloud Firestore](https://firebase.google.com/products/firestore) | Real-time NoSQL database  
| [Google Maps SDK](https://developers.google.com/maps/documentation) | Map and location tracking  
| [Dart](https://dart.dev/) | App logic and backend code

---

## 📂 Project Structure

lib/
├── AuthManager.dart         # Handles login/logout
├── dashboard.dart           # Dashboard/Homepage
├── profile_page.dart        # User profile management
├── routes.dart              # Route viewing and management
├── add_insight_modal.dart   # Feedback submission
├── map_page.dart            # Map and live tracking (if implemented)
├── main.dart                # Entry point

---

---

## 📦 Firebase Collections

| Collection        | Description                     |
|------------------|---------------------------------|
| `users`          | Stores user account info  
| `routes`         | Lists all available jeepney/bus routes  
| `favorites`      | User-specific saved routes  
| `location`       | Real-time vehicle location data  
| `insights`       | Feedback submitted by users  

---

## 🔐 Security & Privacy

- Firebase Auth + Firestore Rules  
- Encrypted data in transit and at rest  
- Only authenticated users can access personal data  
- Dark mode for low-light safety and accessibility

---

## 🧑‍💻 Developers

ZAPAC was developed by:

- 👩‍💻 [Princess Mikaela Borbajo]
- 👩‍💻 [Charisse Jamie]
- 👩‍💻 [Zoie Estorba] 

🚀 As part of our thesis project to solve local transportation problems using smart mobile tech.

---

## 📸 Screenshots

---

## 📌 How to Run Locally

1. Clone the repo  
   ```bash
   git clone https://github.com/charissejamien/Zapac.git
   cd Zapac
   
2. Install dependencies
```bash
	flutter pub get
```

3. Run the app
```bash
flutter run
```

⚠️ Make sure Firebase is correctly set up with your own google-services.json and GoogleService-Info.plist

---

📬 License

This project is for academic purposes and not yet licensed for commercial deployment.

---

❤️ Acknowledgements
	•	Inspired by Cebu’s local commute experience
	•	Thanks to the support of our professors and classmates
	•	Icons from Material Design
	•	Map data from Google Maps Platform
