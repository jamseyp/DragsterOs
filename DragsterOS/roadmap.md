# 🏎️ DRAGSTER OS: TACTICAL ROADMAP

## 🏁 EPIC 1: THE MISSION ENGINE (Algorithmic Coaching)
- [x] **1. CSV Ingestion Engine:** Build a parser that reads `hmPlan.csv` and converts it into a SwiftData `TrainingBlock` model.
- [x] **2. Adaptive Target Scaling:** If Morning Readiness is < 40, automatically mutate today’s Mission Target (e.g., downgrade a Threshold run to Zone 2) and flag it with a "System Override" UI banner.
- [x] **3. Aerobic Decoupling Detection:** Compare average Power vs. average HR across similar runs to calculate your running economy/efficiency factor. Have Gemini analyze if decoupling occurred.
- [ ] **4. Fuel Injection Calculator:** Estimate required kJ (kilojoules) for the upcoming Mission based on planned duration/power, and output an exact pre-workout macro target (e.g., "60g Carbs Required").

## 🫀 EPIC 2: DEEP BIOMETRICS & CHASSIS FATIGUE
- [ ] **5. TSB (Training Stress Balance) Charting:** Calculate Chronic Training Load (CTL) and Acute Training Load (ATL) to map out your exact "Form" and "Fatigue" on a line chart over 90 days.
- [X] **6. Sleep Architecture Parsing:** Upgrade the HealthKit sleep query to not just track total hours, but calculate the percentage of Deep + REM sleep to output a "Neuromuscular Recovery Score".
- [ ] **7. Localized Soreness Heatmap:** A visual human body diagram in the `PitStopView` where you can tap muscles (Calves, Quads, Hamstrings) to log localized DOMS severity.
- [ ] **8. Automated W/kg Tracking:** Pull `HKQuantityTypeIdentifier.bodyMass` daily, merge it with your average running power, and plot your structural power-to-weight ratio over time.

## 🏎️ EPIC 3: EQUIPMENT & TACTICAL LOGISTICS
- [ ] **9. Push Notifications for Tire Wear:** Utilize the `SystemAlertManager` to push a local notification to your Lock Screen the moment a specific `RunningShoe` crosses 85% degradation.
- [ ] **10. Shoe ROI (Return on Investment) Metrics:** Track the average pace/power achieved *per shoe*. (e.g., "The Vaporfly 3 yields a +12% power efficiency over the Boston 12 at Threshold pace").
- [ ] **11. Weather & Environmental Overlay:** Fetch DarkSky/WeatherKit data at the time of workout logging to track performance degradation in heat/humidity.

## 🚀 EPIC 4: HIGH-PERFORMANCE UI/UX (iOS Integration)
- [ ] **12. Live Activities (Dynamic Island):** When a Mission is "Engaged", drop a Live Activity into the Dynamic Island showing the Target Pace and Fueling reminders.
- [ ] **13. Lock Screen Widgets:** Build circular iOS Widgets that display your daily Readiness Score (Red/Yellow/Green) and today's Mission distance right on your lock screen.
- [ ] **14. Apple Watch Companion App:** A barebones watchOS app that displays your actual Dragster OS power/pace targets natively on your wrist during the run.
- [ ] **15. Siri Shortcuts (App Intents):** Allow voice logging: *"Hey Siri, log a 10k run on Dragster OS using the Nike Vaporflys."*

## 🧠 EPIC 5: AI & EXTERNAL INTEGRATION
- [ ] **16. Custom LLM Prompt Builder:** A settings menu where you can modify the "System Prompt" that gets sent to Gemini, allowing you to switch the AI personality between "Harsh Tactician" and "Supportive Coach".
- [ ] **17. Strava / TrainingPeaks Export:** Build an OAuth bridge to push the completed `KineticSession` data directly to Strava with the AI-generated debrief as the workout description.
- [ ] **18. Continuous AI Macro-Cycle Review:** A weekly summary view that aggregates the last 7 sessions, feeds them to Gemini, and generates a paragraph analyzing your overall block progression.
- [ ] **19. Bluetooth BLE Direct Link:** Bypass Apple Health and connect Dragster OS directly to a Bluetooth Power Meter (Stryd) or Chest Strap (Polar H10) for raw, unfiltered data streams.
- [ ] **20. Post-Mission RPE vs HR Discrepancy Alert:** An algorithmic check that flashes a warning if your Subjective RPE was "9/10" but your Heart Rate was only Zone 2 (an indicator of central nervous system exhaustion).
