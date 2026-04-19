#include <Arduino.h>
#define TINY_GSM_MODEM_SIM800
#define TINY_GSM_RX_BUFFER 256

#include <TinyGPS++.h>
#include <TinyGsmClient.h>
#include <ArduinoHttpClient.h>

// ── Firebase ──────────────────────────────
const char FIREBASE_HOST[] = "yathrikan-mini-default-rtdb.firebaseio.com";
const String FIREBASE_PATH = "/bus_101/gps.json";
const int SSL_PORT         = 443;

// ── APN — change to bsnlnet when BSNL ready
const char apn[]  = "bsnlnet";
const char user[] = "";
const char pass[] = "";

// ── SIM800L ───────────────────────────────
#define SIM_RX 26
#define SIM_TX 27
HardwareSerial sim800serial(1);
TinyGsm modem(sim800serial);

// ── GPS ───────────────────────────────────
#define GPS_RX 16
#define GPS_TX 17
HardwareSerial gpsSerial(2);
TinyGPSPlus gps;

// ── HTTP client ───────────────────────────
TinyGsmClientSecure gsm_client(modem, 0);
HttpClient http_client = HttpClient(gsm_client, FIREBASE_HOST, SSL_PORT);

#define SEND_INTERVAL 5000
unsigned long lastSend = 0;

// ─────────────────────────────────────────

void connectGPRS() {
  Serial.print("[SIM] Connecting GPRS...");
  int tries = 0;
  while (!modem.gprsConnect(apn, user, pass)) {
    Serial.print(".");
    delay(2000);
    tries++;
    if (tries > 10) {
      Serial.println("FAILED — restarting modem...");
      modem.restart();
      tries = 0;
    }
  }
  Serial.println("OK — IP: " + modem.localIP().toString());
}

void connectSSL() {
  Serial.print("[SSL] Connecting to Firebase...");
  int tries = 0;
  while (!http_client.connect(FIREBASE_HOST, SSL_PORT)) {
    Serial.print(".");
    delay(2000);
    tries++;
    if (tries > 5) {
      Serial.println("SSL FAILED — reconnecting GPRS...");
      http_client.stop();
      modem.gprsDisconnect();
      delay(2000);
      connectGPRS();
      tries = 0;
    }
  }
  Serial.println("OK");
}

void postToFirebase(float lat, float lng, int speed) {
  String data = "{";
  data += "\"lat\":"   + String(lat, 6) + ",";
  data += "\"lng\":"   + String(lng, 6) + ",";
  data += "\"speed\":" + String(speed);
  data += "}";

  Serial.println("[FB] Sending: " + data);

  http_client.connectionKeepAlive();
  http_client.put(FIREBASE_PATH, "application/json", data);

  int status = http_client.responseStatusCode();
  http_client.responseBody();

  if (status == 200) {
    Serial.println("[FB] Success! Status: 200 ✅");
  } else {
    Serial.println("[FB] Failed! Status: " + String(status));
    // reconnect on failure
    http_client.stop();
    if (!modem.isGprsConnected()) connectGPRS();
    connectSSL();
  }
}

void setup() {
  Serial.begin(115200);
  sim800serial.begin(9600, SERIAL_8N1, SIM_RX, SIM_TX);
  gpsSerial.begin(9600,   SERIAL_8N1, GPS_RX, GPS_TX);
  delay(4000);

  Serial.println("================================");
  Serial.println("     Yathrikan Bus Tracker      ");
  Serial.println("================================");

  Serial.println("[SIM] Initializing...");
  modem.restart();
  String info = modem.getModemInfo();
  Serial.println("[SIM] " + info);

  // wait for network
  Serial.print("[SIM] Waiting for network...");
  while (!modem.waitForNetwork(30000)) {
    Serial.print(".");
  }
  Serial.println("OK");
  Serial.println("[SIM] Signal: " + String(modem.getSignalQuality()));

  http_client.setHttpResponseTimeout(15000);

  connectGPRS();
  connectSSL();

  Serial.println("================================");
  Serial.println("       System Ready!            ");
  Serial.println("================================");
}

void loop() {
  // always feed GPS
  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }

  // check connection health
  if (!http_client.connected()) {
    Serial.println("[HTTP] Connection lost — reconnecting...");
    http_client.stop();
    if (!modem.isGprsConnected()) connectGPRS();
    connectSSL();
  }

  // send every 3 seconds
  if (millis() - lastSend >= SEND_INTERVAL) {
    lastSend = millis();

    if (gps.location.isValid() && gps.location.age() < 2000) {
      float lat  = gps.location.lat();
      float lng  = gps.location.lng();
      int speed  = (int)round(gps.speed.kmph());
      int sats   = gps.satellites.value();

      Serial.printf("[GPS] Lat:%.6f Lng:%.6f Speed:%dkm/h Sats:%d\n",
                    lat, lng, speed, sats);

      postToFirebase(lat, lng, speed);

    } else {
      Serial.printf("[GPS] Waiting for fix... Chars:%d Sats:%d\n",
                    gps.charsProcessed(),
                    gps.satellites.value());
    }
  }
}