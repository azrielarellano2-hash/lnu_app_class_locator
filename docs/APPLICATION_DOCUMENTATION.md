# OCR-Based Academic Schedule Extractor

## App Name

**OCR-Based Academic Schedule Extractor**

A Flutter Android mobile application that reads Leyte Normal University (LNU) enrolment e-slip images and converts them into structured class schedule records for on-device use.

---

## Purpose

The application extracts class schedule data from LNU e-slip images using **Google ML Kit Text Recognition v2** for on-device optical character recognition (OCR) and an **LNU-specific regex engine** that parses recognized text into normalized schedule fields. Students can capture or select an e-slip photo, run OCR locally, review parsed classes, and use the results within the app without sending images to a remote server.

---

## Core Modules

### OcrService

Responsible for image input and text recognition.

- Accepts e-slip images from the device camera or gallery via `image_picker` (and file selection where supported).
- Invokes **Google ML Kit Text Recognition v2** (`TextRecognizer` with Latin script) to produce raw text from the image.
- Groups recognized text into table-oriented lines to preserve e-slip row structure before parsing.

**Implementation reference:** `lib/services/eslip_ocr_service.dart` (`EslipOcrService`)

### ScheduleParser

Responsible for interpreting OCR output into schedule records.

- Preprocesses raw OCR text (line breaks, time markers, enrolment row codes).
- Applies **LNU-specific regular expressions** for subject codes, time ranges, room codes, and day patterns (e.g. `MTh`, `TF`, `W`).
- Maps each enrolment row to structured fields: subject code, description, room, days, and start/end times.
- Surfaces parse warnings when rows cannot be fully interpreted.

**Implementation reference:** `lib/utils/eslip_ocr_parser.dart` (`parseEslipOcrText`)

---

## Fields Extracted

For each class row detected on the e-slip, the parser extracts:

| Field | Description | Example |
|-------|-------------|---------|
| **Subject code** | Official course code | `IT-122`, `IT-121L` |
| **Subject description** | Course title from the e-slip row | System Analysis and Design |
| **Room number** | Campus room or lab code | `COMLAB2A`, `CISCOLAB`, `TBA11A` |
| **Class days** | Meeting days (normalized display) | Monday and Thursday, Wednesday |
| **Start time** | Class start in 12-hour format | `8:00 AM` |
| **End time** | Class end in 12-hour format | `9:00 AM` |

Additional profile metadata (student ID, name, college, course, section) may be parsed from the e-slip header when present in the OCR text.

---

## Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter |
| **Language** | Dart |
| **OCR** | Google ML Kit Text Recognition v2 (`google_mlkit_text_recognition`) |
| **Media input** | `image_picker`, `file_picker` |
| **Local storage** | SQLite (`sqflite`) |
| **State management** | `provider` |
| **IDE** | Visual Studio Code |
| **Version control** | Git |

---

## Development Methodology

The project follows the **Waterfall Software Development Life Cycle (SDLC)**. Each phase completes before the next begins.

### 1. Planning

- Defined the problem: manual transcription of LNU e-slip schedules is slow and error-prone.
- Scoped an Android-only, offline OCR solution aligned with real e-slip layouts.
- Identified required fields, target devices, and success criteria for parsing accuracy.

### 2. Design

- Designed the scan → OCR → parse → store → display workflow.
- Specified regex patterns for LNU subject codes, rooms, times, and day abbreviations.
- Planned UI screens (welcome, scan, schedule, campus map/buildings) and local database schema.

### 3. Development

- Implemented `OcrService` integration with ML Kit Text Recognition v2.
- Built the LNU-specific `ScheduleParser` and supporting utilities.
- Connected parsing output to schedule views, SQLite persistence, and campus locator features.

### 4. Testing

- Executed functional tests on a single Android device using real LNU e-slip images.
- Validated parser behavior with unit tests against sample OCR lines and predefined pass/fail cases.
- Recorded parsing warnings and edge cases (blurry photos, partial tables, unusual room codes).

### 5. Deployment

- Built release/debug APKs for Android installation.
- Documented setup, dependencies, and known limitations for maintainers and evaluators.

---

## Testing

### Approach

**Functional testing** was performed on a **single Android physical device** using **real LNU e-slip images** captured or imported during development.

### Test cases

Each test case used a predefined **pass** or **fail** expectation:

| ID | Scenario | Expected result |
|----|----------|-----------------|
| TC-01 | Clear, full e-slip photo | **Pass** — all visible rows parsed with correct subject, room, days, and times |
| TC-02 | Blurry or low-light image | **Fail** — empty or incomplete OCR; user warned to retake photo |
| TC-03 | Cropped e-slip (partial table) | **Fail** or partial **pass** — missing rows; warnings shown for incomplete data |
| TC-04 | Standard IT lab row (e.g. `COMLAB2A`, `MTh`) | **Pass** — room and day pattern match LNU conventions |
| TC-05 | Lab subject code with `L` suffix (e.g. `IT-121L`) | **Pass** — lab code captured before generic code match |
| TC-06 | Wednesday-only slot (`W`) | **Pass** — single-day pattern normalized correctly |
| TC-07 | Parser unit samples (synthetic OCR lines) | **Pass** — automated tests in `test/eslip_ocr_parser_test.dart` |

### Automated tests

Dart unit tests verify regex and parser logic independent of the device camera, including sample rows mirroring actual e-slip formatting.

---

## Limitations

- **Offline only** — OCR and parsing run entirely on the device; no cloud OCR or sync service is used.
- **Android only** — primary development and validation target is Android; other platforms are not formally supported or tested.
- **Single device tested** — functional results reflect one physical Android handset; behavior may vary on other models or Android versions.
- **No formal usability evaluation** — usability studies (task completion time, satisfaction surveys, heuristic evaluation) have **not** been conducted yet.
- **OCR quality dependent** — poor lighting, glare, or cropping can reduce recognition accuracy regardless of parser design.
- **LNU e-slip format bound** — regex rules are tailored to LNU enrolment slip layouts; other universities or document types are out of scope.

---

## Repository

**GitHub:** [azrielarellano2-hash/lnu_app_class_locator](https://github.com/azrielarellano2-hash/lnu_app_class_locator)
