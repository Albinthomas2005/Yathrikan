#include <Arduino.h>
#include <WiFi.h>
#include <TinyGPS++.h>
#include <Firebase_ESP_Client.h>

// ── WiFi Credentials ─────────────────────────────
#define WIFI_SSID     "Infinix NOTE 10"
#define WIFI_PASSWORD "9876543210"

// ── Firebase ─────────────────────────────────────
#define API_KEY "AIzaSyAhGRfieuFymjiPUV1GxhJgB9akS6w1H8c"
#define DATABASE_URL "yathrikan-mini-default-rtdb.firebaseio.com"

// ── GPS Pins ─────────────────────────────────────
#define GPS_RX 16
#define GPS_TX 17

HardwareSerial gpsSerial(2);
TinyGPSPlus gps;

// ── Firebase Objects ─────────────────────────────
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ── Timing ───────────────────────────────────────
#define SEND_INTERVAL 3000
unsigned long lastSend = 0;

// ────────────────────────────────────────────────

void postToFirebase(float lat, float lng, int speed) {

  if (Firebase.RTDB.setFloat(&fbdo, "/bus_101/gps/lat", lat))
    Serial.println("[FB] Latitude sent");

  if (Firebase.RTDB.setFloat(&fbdo, "/bus_101/gps/lng", lng))
    Serial.println("[FB] Longitude sent");

  if (Firebase.RTDB.setInt(&fbdo, "/bus_101/gps/speed", speed))
    Serial.println("[FB] Speed sent");
}

void setup() {

  Serial.begin(115200);

  gpsSerial.begin(9600, SERIAL_8N1, GPS_RX, GPS_TX);

  Serial.println("\n================================");
  Serial.println("     Yathrikan Bus Tracker      ");
  Serial.println("================================");

  // ── WiFi Connect ──
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("[WiFi] Connecting");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n[WiFi] Connected");
  Serial.println(WiFi.localIP());

  // ── Firebase Setup ──
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // IMPORTANT FIX (no login needed for testing)
  config.signer.test_mode = true;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("[Firebase] Ready");
  Serial.println("================================");
}

void loop() {

  // ── Read GPS ──
  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }

  // ── WiFi reconnect ──
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[WiFi] Reconnecting...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
    }
    Serial.println("\n[WiFi] Reconnected");
  }

  // ── Send every 3 sec ──
  if (millis() - lastSend >= SEND_INTERVAL) {

    lastSend = millis();

    if (gps.location.isValid() && gps.location.age() < 2000) {

      float lat = gps.location.lat();
      float lng = gps.location.lng();
      int speed = (int)gps.speed.kmph();

      Serial.printf("[GPS] Lat: %.6f | Lng: %.6f | Speed: %d km/h\n",
                    lat, lng, speed);

      postToFirebase(lat, lng, speed);

    } else {

      Serial.printf("[GPS] Waiting fix... sats:%d chars:%d\n",
                    gps.satellites.value(),
                    gps.charsProcessed());
    }
  }
}