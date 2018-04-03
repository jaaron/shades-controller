// leave commented for nodemcu motorshield
// #define ADAFRUIT_MOTORSHIELD

/* replace these with your WiFi info */
const char ssid[] = "MySSID";
const char wifi_pass[] = "MyWifiPassword";

/* Replace with IP of host running shade-server software 
 * and port number for raw HTTP. 
 *
 * *NB* Do not expost raw HTTP port to the internet
 */
const char control_host[] = "192.168.1.90";
const short control_http_port = 8080;

/* Device ID, Name, and Description. These are used by the local
   control panel and passed to Amazon for Alexa integration. */
const char id[] = "shade-controller-00";
const char name[] = "Kitchen Shades";
const char description[] = "Kitchen Window Shade";
