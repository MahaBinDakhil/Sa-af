# Sa'af 🌴

**Sa'af** is a mobile app that helps farmers and palm owners detect date palm leaf diseases early. Take or upload a photo of a palm leaf, and the app tells you whether the palm is healthy or diseased, names the disease, shows how confident the AI is, and explains *why* it made that decision.

The app is part of the graduation project **"An Explainable Hybrid CNN-Transformer Model for Date Palm Disease Classification"**.

---

## Features

- **Scan a palm leaf** – capture a photo with the camera or pick one from the gallery.
- **Instant diagnosis** – healthy or diseased, the disease name, and a confidence score.
- **Explainable AI (XAI)** – a Grad-CAM heatmap and highlighted region show which parts of the leaf the model focused on, plus a "How the AI decided" breakdown of the top predictions.
- **Disease information** – a description, symptoms, and treatment steps for each disease.
- **AI chatbot** – ask questions about a scan, like *"How can I treat this disease?"* or *"How did you identify this disease?"*
- **Scan history** – all past scans, with search and *All / Healthy / Diseased* filters.
- **Home dashboard** – counts of healthy palms, diseased cases, and total diagnoses, plus the latest results.
- **User accounts** – sign up, log in, edit profile, change password, and delete account. Each user only sees their own data.

## Detected Classes

The model classifies a palm leaf into one of **9 classes**:

| # | Class |
|---|---|
| 1 | Potassium Deficiency |
| 2 | Manganese Deficiency |
| 3 | Magnesium Deficiency |
| 4 | Black Scorch |
| 5 | Leaf Spots |
| 6 | Fusarium Wilt |
| 7 | Rachis Blight |
| 8 | Parlatoria Blanchardi |
| 9 | Healthy |

## The AI Model

A dual-branch hybrid deep learning model that runs two networks in parallel and fuses their features:

- **EfficientNetV2-S** (CNN) captures local texture details on the leaf.
- **Swin-Tiny Transformer** captures global spatial patterns across the leaf.

The model works in two stages: it first decides **healthy vs. diseased**, then classifies the **specific disease** among the 8 disease classes. **Grad-CAM** is used to generate visual explanations of each prediction.

## Tech Stack

| Part | Technology |
|---|---|
| Mobile app | Flutter (Dart) |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| AI model | PyTorch (EfficientNetV2-S + Swin-Tiny) |
| Explainability | Grad-CAM++ |

## Getting Started

```bash
git clone https://github.com/MahaBinDakhil/Sa-af.git
cd Sa-af
flutter pub get
flutter run
```

> On Windows, enable **Developer Mode** before running the app.

## Team

- Anfal Alobeid
- Maram Alkhamis
- Raghad Alessa
- Maha bin Dakhil
- Batool Bamuqabel

**Supervised by:** Dr. Nouf AlShenaifi

Computer Science Department, College of Computer and Information Sciences
