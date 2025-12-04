# Weather API Setup Guide

## Current Status

⚠️ **Weather API requires configuration to get live weather data**

The app currently uses **mock weather data** because no valid API key is configured.

## Quick Setup (5 minutes)

### Step 1: Get Your Free API Key

1. Go to: https://home.openweathermap.org/users/sign_up
2. Create a free account (no credit card required)
3. Verify your email
4. Go to: https://home.openweathermap.org/api_keys
5. Copy your API key (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

⏱️ **Note:** It may take 10-15 minutes for your new API key to activate after signup.

### Step 2: Add API Key to Your App

1. Open Xcode
2. Navigate to: `selfie-timelapse/Services/WeatherService.swift`
3. Find line 17 with: `private let apiKey = "YOUR_API_KEY_HERE"`
4. Replace `YOUR_API_KEY_HERE` with your actual API key
5. Save the file

**Example:**

```swift
// Before:
private let apiKey = "YOUR_API_KEY_HERE"

// After:
private let apiKey = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
```

### Step 3: Test It

1. Build and run your app
2. Take a selfie
3. Check the calendar view - you should see real weather data!

## How It Works

### With API Key ✅

- Fetches real-time weather from OpenWeatherMap
- Shows actual temperature, conditions, humidity
- Displays accurate weather emoji icons
- Caches results to minimize API calls
- Free tier: 1,000 calls/day (plenty for daily selfies)

### Without API Key (Current) ⚠️

- Uses realistic mock weather data
- Generates temperature based on day of year
- Still displays weather UI
- Great for development/testing

## Troubleshooting

### "Invalid API key" error

- Wait 10-15 minutes after signup for key activation
- Double-check you copied the entire key
- Make sure there are no extra spaces
- Verify the key at: https://home.openweathermap.org/api_keys

### Console shows "Using mock data"

- API key not configured or invalid
- Check spelling of `YOUR_API_KEY_HERE`
- Rebuild the app after changing the key

### No weather showing at all

- Check location permissions are granted
- Ensure `Info.plist` has location usage description
- Check console logs for error messages

## API Details

- **Endpoint:** `api.openweathermap.org/data/2.5/weather`
- **Method:** GET
- **Parameters:** lat, lon, appid, units
- **Response:** JSON with weather data
- **Rate Limit:** 60 calls/minute (free tier)
- **Daily Limit:** 1,000 calls/day (free tier)

## Privacy & Security

- Your API key is stored locally in the app
- Not committed to git (add to .gitignore if sharing)
- Weather requests only when taking selfies
- Data is cached to reduce API calls

## Cost

**Free Forever Plan:**

- ✅ 1,000 calls/day
- ✅ Current weather data
- ✅ No credit card required
- ✅ Perfect for this app

For a daily selfie app, you'll use ~30 calls/month - well within limits!

## Need Help?

- OpenWeatherMap FAQ: https://openweathermap.org/faq
- API Documentation: https://openweathermap.org/current
- Check console logs in Xcode for detailed error messages
