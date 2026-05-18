# OnyxFi Frontend & GenUI Rules

## Framework & Core Libraries
- You are strictly developing a cross-platform mobile and web application using **Flutter (Dart)**.
- For Artificial Intelligence, use the official `google_generative_ai` SDK to connect with the Gemini API.
- For data visualization and financial graphics, strictly use the `fl_chart` library.

## State Management & Architecture
- Maintain a clean, modular folder structure as defined in the project architecture map.
- Separate running application screens (`views/`) from components rendered dynamically by the AI agent (`catalog/`).

## Generative UI (GenUI) Implementation Strategy
- OnyxFi does not rely on raw text outputs for complex financial data. It renders dynamic widgets based on structured JSON payloads received from the Gemini API.
- All dynamic widgets must reside in `lib/catalog/`.
- Every catalog component must take a structured Dart Model or Map parsed from the AI JSON output as its parameter.
- When tasked to implement GenUI bridges, create a strict mapping in `lib/catalog/component_registry.dart` that dynamically evaluates JSON keys (e.g., `{"type": "projection_chart", "data": {...}}`) and outputs the corresponding Flutter widget.
- Ensure all dynamic JSON structures are strongly validated to avoid null pointer exceptions during real-time render cycles in front of the hackathon jury.