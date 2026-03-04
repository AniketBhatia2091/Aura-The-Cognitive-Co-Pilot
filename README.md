# Aura: The Cognitive Co-Pilot

Aura is a mindful productivity app designed to reduce cognitive load and help users confidently capture and execute tasks. Built entirely with native Apple frameworks, Aura leverages on-device heuristics to analyze text input, detect urgency, and dynamically adapt its interface to the user's mental state.

## Inspiration & Problem 

Modern task managers are often too complex, requiring users to fill out endless forms—tags, folders, dates, and priorities—just to save a single thought. For neurodivergent individuals or anyone experiencing cognitive overload, this friction prevents them from capturing tasks at all, leading to mental clutter and anxiety. 

Aura solves this by providing a single, frictionless **"Brain Dump"** text box. You just type naturally. A custom on-device heuristic engine extracts actionable micro-tasks and prioritizes them automatically based on urgency keywords and structure. By completely removing the burden of organization, Aura transforms chaotic thoughts into a calm, actionable plan instantly.

## Key Features

*   **Brain Dump Input:** Pour everything out — tasks, worries, ideas. No categories, no tags, no priority dropdowns. Just type.
*   **On-Device Heuristic Engine:** Parses messy thoughts into clean micro-tasks using a lightweight text parsing engine — splitting on conjunctions, stripping filler phrases, scoring urgency, and grouping tasks.
*   **Cognitive Load Detection:** Aura quietly watches how much you've written, your typing speed, conjunction usage, and emotional keywords to calculate a Cognitive Load Score (0-100).
*   **Calm Mode:** When the Cognitive Load Score gets high, the UI shifts — colors dim, a soft overlay fades in, and a supportive message appears. Aura pulls the simplest task to the top as a **Micro Win** to build momentum.
*   **Focus Ring:** Shows your current task with a timer, silently adjusting suggested focus durations based on your daily session count to prevent burnout.
*   **100% Privacy:** Everything runs on-device. No server calls, no analytics SDKs. Your thoughts stay on your phone.

## Accessibility Focus

Accessibility is the foundational pillar of Aura's design, focusing heavily on cognitive accessibility. 

*   **Reduced Visual Noise:** Dark, soothing color palette with gentle gradients to prevent eye strain. The Focus Ring spotlights a single active task, reducing choice paralysis.
*   **Dynamic Type & High Contrast:** Full compatibility with Dynamic Type and high-contrast colors for critical action buttons.
*   **VoiceOver Support:** Every interactive element and dynamic state (including the cognitive load badge and Calm Mode overlay) is fully annotated with VoiceOver labels and hints.

## Technology Stack

Aura relies heavily on native Apple frameworks to ensure privacy, performance, and a seamless experience.

*   **SwiftUI & Observation:** For a fluid, reactive interface and clean, efficient state management (using iOS 17's `@Observable` macro).
*   **SwiftData:** For local, declarative persistence of Brain Dump sessions, tasks, and analytics history.
*   **Swift Charts:** To build the "Reflection" analytics dashboard with beautiful, accessible data visualizations.
*   **Foundation (Regex & NLP Heuristics):** A custom parsing engine using native String manipulation, Regex, and deterministic heuristics for 100% on-device processing.

## Beyond the App

*[PLACEHOLDER: Add your personal description here regarding coding clubs, mentoring, community service, or teaching you have done related to technology.]*
