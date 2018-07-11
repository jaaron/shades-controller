// leave commented for nodemcu motorshield
// #define ADAFRUIT_MOTORSHIELD

/* replace these with your WiFi info */
const char ssid[] = "MySSID";
const char wifi_pass[] = "MyWifiPassword";

/* Replace with IP and port of MQTT Broker
 */
const char mqtt_server[] = "192.168.1.90";
const short mqtt_port = 1883;

/* don't edit these, they must agree with the topics used by the server. */
const char *status_topic = "shade_status";
const char *registration_topic = "registration";

/* Device ID, Name, and Description. These are used by the local
   control panel and passed to Amazon for Alexa integration. */
const char id[] = "shade-controller-00";
const char name[] = "Kitchen Shades";
const char description[] = "Kitchen Window Shade";
