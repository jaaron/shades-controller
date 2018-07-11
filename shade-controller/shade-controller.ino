#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>

#include <Adafruit_MQTT_Client.h>
#include <Adafruit_MQTT.h>

#define UP FORWARD
#define DOWN BACKWARD


/* config.h must define the following variables:

   const char ssid[] = "your wifi ssid";
   const char wifi_pass[] = "your wifi password"

   const char id[] = "unique id for this unit"
   const char name[] = "friendly name for this unit"
   const char description[] = "helpful description for this unit"

   const char control_host[] = "ip or hostname of control server"
   const short control_http_port = portnum;

   also, to use adafruit motor shield, #define ADAFRUIT_MOTORSHIELD
*/
#include "config.h"

unsigned int localUdpPort = 4210;
char incomingPacket[255];

char buffer[128];

long dist_max = 100;
long dist_min = 0;
long distance = 0;
long target = 0;
long direction = 0; /* 0 for stop, -1 for reverse, +1 for forward */



// MQTT stuff
WiFiClient client;

Adafruit_MQTT_Client mqtt(&client, mqtt_server, mqtt_port);
Adafruit_MQTT_Subscribe cmdfeed = Adafruit_MQTT_Subscribe(&mqtt, id, MQTT_QOS_0);

void MQTT_connect() {
  int8_t ret;

  // Stop if already connected.
  if (mqtt.connected()) {
    return;
  }

  Serial.print("Connecting to MQTT... ");

  uint8_t retries = 3;
  while ((ret = mqtt.connect()) != 0) { // connect will return 0 for connected
       Serial.println(mqtt.connectErrorString(ret));
       Serial.println("Retrying MQTT connection in 10 seconds...");
       mqtt.disconnect();
       delay(10000);  // wait 10 seconds
       retries--;
       if (retries == 0) {
         // basically die and wait for WDT to reset me
         while (1);
       }
  }
  Serial.println("MQTT Connected!");
}
/* End MQTT Stuff */


#ifdef ADAFRUIT_MOTORSHIELD 

#define SPEED 192

#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_MS_PWMServoDriver.h"

// Create the motor shield object with the default I2C address
// Adafruit_MotorShield AFMS = Adafruit_MotorShield(); 
// Or, create it with a different I2C address (say for stacking)
Adafruit_MotorShield AFMS = Adafruit_MotorShield(); 

// Select which 'port' M1, M2, M3 or M4. In this case, M1
Adafruit_DCMotor *myMotor = AFMS.getMotor(1);

void motor_init(void){
  AFMS.begin();
  myMotor->run(RELEASE);
}

void motor_up(void){
    myMotor->run(UP);
    myMotor->setSpeed(SPEED);
}

void motor_down(void){
    myMotor->run(DOWN);
    myMotor->setSpeed(SPEED);
}

void motor_stop(void){
    myMotor->setSpeed(0);
    myMotor->run(RELEASE);
}

#else

#define SPEED 1000
#define DIRA 0
#define PWMA 5

void motor_init(void){
    pinMode(DIRA, OUTPUT);
    pinMode(PWMA, OUTPUT);
  
    analogWrite(PWMA,0);
    digitalWrite(DIRA,1);
}

void motor_up(void){
    digitalWrite(DIRA,1);
    analogWrite(PWMA, SPEED);
}

void motor_down(void){
    digitalWrite(DIRA,0);
    analogWrite(PWMA, SPEED);
}

void motor_stop(void){
    analogWrite(PWMA, 0);
}

#endif

#ifdef DISTANCE_TEST

void distance_init(void){}

long get_distance(void){
    if(distance < target){
	return distance +1;
    }else if(distance > target){
	return distance - 1;
    }
    return distance;
}

#else
#ifdef DISTANCE_HC_SR05

#include "SR04.h"

#define TRIG_PIN D7
#define ECHO_PIN D6
SR04 sr04 = SR04(ECHO_PIN, TRIG_PIN);

void distance_init(void){
}

long get_distance(void){
  return sr04.DistanceAvg();
}

#else

#include <SoftwareSerial.h>
#define US_100_TX D8
#define US_100_RX D7

SoftwareSerial us100(US_100_RX, US_100_TX);


void distance_init(void){
  us100.begin(9600);
}

long get_distance(void){    
    int retry = 0;
    us100.flush();
    us100.write(0x55);
    while(retry < 10 && us100.available() < 2){
	retry++;
	delay(20);
    }
    if(us100.available() < 2){
	return -1;
    }
    unsigned short high = us100.read() << 8;
    unsigned short low = us100.read();
    long dist = ((long)(high + low))/10;
    if(dist > 1000){
	return -1;
    }else if(dist < 0){
	return -1;
    }
    return dist;
}

#endif
#endif

HTTPClient http_client;

void register_with_server(void){
  String req = (String("{\"id\": \"")+id+"\", \"name\": \""+name+"\", \"description\": \""+description+"\", "+
		"\"ip\": \""+WiFi.localIP().toString()+"\"}\r\n");
  Serial.println(String("Registering with server ")+mqtt_server);  
  mqtt.publish(registration_topic, req.c_str(), 0);
  /*
  http_client.begin(control_host, control_http_port, "/register");
  http_client.addHeader("Content-type", "application/json");
  int res = http_client.POST(req);
  Serial.println(String("Got response: ") + res);
  */
  
}

int poll_for_command(void){
    String req = "";
    return 0;
}

void calibrate(void){
  dist_max = get_distance();
  motor_up();
  long tmp;
  do{      
      delay(100);
      tmp = get_distance();
      /* avoid teleportation */
      if(tmp > dist_max + 50){
	  continue;
      }
      /* found the top */
      if(tmp < dist_max + 2){
	  break;
      }
      if(tmp > dist_max + 2){
	  dist_max = tmp;
      }
  }while(1);
  motor_stop();
  dist_max -= 1; /* give a little buffer */  
  Serial.printf("Calibrated: dist_max = %ld\n", dist_max);
}

void cmd_callback(char *data, uint16_t len){
    Serial.printf("Got command \"%s\"\n", data);
    if(strncmp("SET ", data, 4) == 0){
	long tmp = strtol(data + 4, NULL, 10);
	if(tmp >= 0 && tmp <= 100){
	    target = percent_to_distance(tmp);
	    Serial.printf("Set target to %ld\n", target);
	}
    }else if(strncmp("CALIBRATE", data, 9) == 0){
	calibrate();
    }
}

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, wifi_pass);
  Serial.println();
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  Serial.print("Connected, IP address: ");
  Serial.println(WiFi.localIP());

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
  digitalWrite(LED_BUILTIN, HIGH);

  motor_init();
  distance_init();
  
  cmdfeed.setCallback(cmd_callback);
  mqtt.subscribe(&cmdfeed);

  MQTT_connect();
  register_with_server();
}

long distance_to_percent(void){
  return ((distance - dist_min)*100) / (dist_max - dist_min);
}

long percent_to_distance(long percent){
  return dist_min + ((percent*(dist_max - dist_min))/100);
}

void loop() {
    MQTT_connect();
    mqtt.processPackets(100);
    
    distance = get_distance();
    Serial.printf("Current distance: %ld target: %d direction: %d\n", distance, target, direction);
    
    if(direction != 0){
	if((direction < 0 && target >= distance) ||
	   (direction > 0 && target <= distance)){
	    motor_stop();
	    direction = 0;
	    target = distance;
	}
    }
    /*
    http_client.begin(control_host, control_http_port, String("/shade/")+id+"/poll");
    int res = http_client.POST(String(distance_to_percent()));
    if(res != 200){
	Serial.printf("HTTP POST Returned status %d\n");
    }else{
	String str = http_client.getString();
    
	if(str.length() == 0){
	}else{
	    int pct = str.toInt();

	    target = percent_to_distance(pct);

	    if(target < distance){
		Serial.print("BACKWARD!\n");
		direction = -1;
		motor_down();
	    }else if(target > distance){
		Serial.print("FORWARD!");
		direction = 1;
		motor_up();
	    }
	}
    }
    */

    sprintf(buffer, "{\"shade_id\": \"%s\", \"status\": %d}", id,
	    distance_to_percent());
    
    mqtt.publish(status_topic, buffer, 0);
    
    if(direction == 0){
	delay(3000);
    }else{
	digitalWrite(LED_BUILTIN, LOW);
	delay(150);
	digitalWrite(LED_BUILTIN, HIGH);
	delay(150);
    }
}
