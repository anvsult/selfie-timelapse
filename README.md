# Selfie Timelapse

An iOS app for capturing daily selfies and creating timelapse videos.

## Features

- Take daily selfies with face-guided camera
- Daily motivational quotes when taking selfies (via ZenQuotes API)
- Weather tracking for each selfie location (via OpenWeatherMap API)
- Track your streak and view statistics
- Generate timelapse videos from your selfies
- View selfie locations on a map
- Calendar view of your selfie history with weather data

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Installation

1. Clone the repository
2. Open `selfie-timelapse.xcodeproj` in Xcode
3. **Configure Weather API (Recommended)**
   - The app will work without this, but live weather data enhances the experience
   - Get a free API key from [OpenWeatherMap](https://openweathermap.org/api):
     - Sign up at: https://home.openweathermap.org/users/sign_up
     - After signup, find your API key at: https://home.openweathermap.org/api_keys
   - Open `Services/WeatherService.swift`
   - Replace `YOUR_API_KEY_HERE` with your actual API key
   - **Note:** Without an API key, the app automatically uses realistic mock weather data
4. Build and run the app
5. Grant camera and location permissions when prompted

## API Integration

### ZenQuotes API

- **Purpose:** Provides daily motivational quotes
- **Status:** ✅ Working - No configuration needed
- **Usage:** Displays in camera view to encourage daily selfies
- **Free tier:** Unlimited access

### OpenWeatherMap API

- **Purpose:** Shows weather conditions for each selfie
- **Status:** ⚠️ Requires configuration (optional)
- **Setup Instructions:**
  1. Sign up: https://home.openweathermap.org/users/sign_up
  2. Get API key: https://home.openweathermap.org/api_keys
  3. Add to `Services/WeatherService.swift` (line with `apiKey`)
- **Features:**
  - Real-time temperature and conditions
  - Weather emoji icons in calendar view
  - Humidity and description data
- **Free tier:** 1,000 calls/day (more than enough for daily selfies)
- **Fallback:** Uses realistic mock data if no API key configured

## Technology

- SwiftUI
- SwiftData
- AVFoundation
- CoreLocation
- MapKit
- **REST APIs:**
  - ZenQuotes API (motivational quotes)
  - OpenWeatherMap API (weather data)

## Authors

Anvar Sultanov
Louis Caron
Ava Keyhani
