# SmileScan 🦷

AI-powered smartphone-based dental screening system for children using Deep Learning.

![Status](https://img.shields.io/badge/status-research%20phase-yellow)

---

## Overview

SmileScan is a research project focused on developing a smartphone-based dental screening system for children using Computer Vision and Deep Learning.

The system aims to assist parents and healthcare workers in performing early dental condition screening through smartphone images.

The system does not replace professional dental diagnosis. Instead, it provides an initial screening result that can be validated by dental professionals.

The validated results from dentists will be collected as high-quality labeled data to support future model improvement.

---

## Research Background

Dental problems, especially dental caries in children, remain a common health issue that requires early detection and prevention.

However, access to dental examination is still limited in some communities. By utilizing smartphone cameras and Artificial Intelligence, this project explores the possibility of providing an accessible early screening tool.

---

## Research Objectives

The objectives of this project are:

- Develop a smartphone-based dental screening system.
- Apply Computer Vision and Deep Learning techniques for dental condition identification.
- Implement image quality assessment to ensure uploaded images are suitable for analysis.
- Provide a workflow where AI predictions can be validated by dental professionals.
- Build a structured dataset from validated screening results for future model improvement.

---

## System Concept

The general workflow of the system:

1. **Image Capture** – A parent or healthcare worker captures a photo of the child's teeth using a smartphone camera.
2. **Image Quality Assessment** – The system checks whether the uploaded image meets the minimum quality requirements (lighting, focus, clarity, and the presence of the teeth region) before it is accepted for analysis.
3. **AI Model Inference** – The accepted image is sent to the backend, where a Deep Learning model performs dental condition classification (e.g., signs of caries or healthy teeth).
4. **Screening Result** – The prediction is returned to the app and displayed to the user as an initial screening result.
5. **Professional Validation** – Dental professionals can review and validate the AI prediction through the dashboard, confirming or correcting the result.
6. **Structured Dataset** – Validated results are stored as high-quality labeled data, which will be used to improve the model in future iterations.

The system does not replace professional dental diagnosis. Instead, it provides an initial screening result that can be validated by dental professionals.

---

## Project Structure

```
skripsi-dental-screening-ai/
│
├── docs/
│   ├── literature/
│   │   ├── week-01/
│   │   ├── week-02/
│   │   ├── week-03/
│   │   └── summary.md
│   ├── proposal/
│   ├── architecture/
│   ├── methodology/
│   ├── dataset/
│   ├── roadmap/
│   ├── meeting-notes/
│   ├── experiments/
│   └── deployment/
│
├── app/            # Mobile application (frontend, smartphone-based)
├── backend/        # Backend services / API
├── ai-model/       # Deep Learning models, training, and inference
├── dashboard/      # Validation dashboard for dental professionals
│
└── README.md
```

---

## Folder Description

- **docs/literature/** – Weekly literature review notes and a summary file.
- **docs/proposal/** – Research proposal document.
- **docs/architecture/** – System architecture diagrams and documentation.
- **docs/methodology/** – Research methodology and experimental design.
- **docs/dataset/** – Dataset documentation and labeling guidelines.
- **docs/roadmap/** – Project roadmap and milestones.
- **docs/meeting-notes/** – Notes from supervision meetings.
- **docs/experiments/** – Experiment logs and results.
- **docs/deployment/** – Deployment guides and configuration.
- **app/** – The smartphone-based frontend application.
- **backend/** – Backend services, API, and data storage.
- **ai-model/** – Deep learning model development (training, evaluation, inference).
- **dashboard/** – Web dashboard for dental professionals to validate screening results.

---

## Getting Started

This section will be completed as the project develops.

---

## License

To be determined.
