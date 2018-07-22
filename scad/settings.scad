/* true  -> place the controller housing to
            right of the motor housing
   false -> place the controller housing below
            the motor housing
*/
side_by_side = false;

/* include a battery compartment */
with_battery_housing = true;

/* true  -> make the walls just tall enough for
            the motor
   false -> make the walls tall enough to enclose
            the controller
*/
min_height = false;

/* default wall/floor thickness */
thickness = 4;

battery_height = 23;
battery_length = 79;
battery_width = 37;

solar_controller_height = 15;
solar_controller_width  = 37;
solar_controller_length = 61;



/* dimensions of NodeMCU + Motor Shield standing on edge */
controller_x = 62;
controller_y = 27;
controller_z = 45;

/* length of the motor body */
motor_l = 55;
/* diameter of the motor body */
motor_d = 26;

/* height of inserts placed above and below motor housing */
padding = 6;

/* length of thumbscrews inside the housing
   (thumbscrews must be at thumbscrew_internal_l + thickness long)
*/
thumbscrew_internal_l = 14;

/* radius of thumbscrews */
thumbscrew_radius = 3;
/* offset of left hand thumbscrew from left inner edge of motor housing */
left_thumbscrew_offset = 8;
/* offset of right hand thumbscrew from right inner edge of motor housing */
right_thumbscrew_offset = 13;

/* radius of holes for wall mount screws */
mount_hole_r = 3;

/* internal dimensions of the motor housing. */
motor_housing_internal_x = max(motor_d + padding + thumbscrew_internal_l,
                                side_by_side ? controller_x : battery_length - (controller_y + thickness));
motor_housing_internal_y = max(motor_l + 5, side_by_side ? 0 : controller_x);

/* external dimensions of the motor housing */
motor_housing_total_x    = motor_housing_internal_x + 2*thickness;
motor_housing_total_y    = motor_housing_internal_y + 2*thickness;

internal_z = min_height ? motor_d : max(controller_z, motor_d);
total_z    = internal_z + thickness;

/* extra padding to center the motor in the Z dimension */
motor_pad = with_battery_housing ? (internal_z - solar_controller_height - motor_d) :
            (internal_z - motor_d)/2;

mount_hole_offset = (motor_housing_internal_x / 6) ;
mount_hole_inset_r = 5;

/* settings for the thumbscrew plate */
thumbscrew_plate_inset_r= 5.75;
thumbscrew_plate_thickness = 6;
thumbscrew_plate_inset_h = 3;
thumbscrew_plate_l = motor_housing_internal_y - 1;
thumbscrew_plate_w = motor_d;

/* batter housing size */
battery_total_x = max(battery_length + thickness, (controller_y + thickness + motor_housing_total_x));

/*
 * inside of the lid is external size of the housing + 2 mm wiggle room in
 * both X and Y. Lid wall height will be to the edge of the bridge over the
 * motor shaft
 */
lid_space = 0.5; /* how much extra space to leave between inside of lid and outside of housing */
lid_thickness = thickness/2;

lid_internal_x = motor_housing_total_y + battery_height + thickness + (lid_space *2);
lid_internal_y = motor_housing_total_x + controller_y + thickness + (lid_space * 2);
lid_internal_z = total_z - (motor_pad + motor_d + 5);

lid_total_x = lid_internal_x + 2*lid_thickness;
lid_total_y = lid_internal_y + 2*lid_thickness;
lid_total_z = lid_internal_z + lid_thickness;

led_x_offset = lid_thickness + thickness + lid_space + 8;
led_radius   = 3;
led_y_offset = lid_total_y - (lid_thickness + thickness + lid_space) - 13;
led_y_spacing = 7;

switch_center_x_offset = lid_thickness + thickness + lid_space + 40;
switch_center_y_offset = lid_thickness + thickness + lid_space + controller_y - 10;
switch_hole_radius = 10;

solar_controller_ports_x = 11;
solar_controller_ports_x_offset = lid_thickness + thickness + lid_space + solar_controller_length - solar_controller_ports_x;
solar_controller_ports_y_offset = lid_total_y - (lid_thickness + thickness + lid_space) - solar_controller_width - 12;

/* little module to diff with a square corner to round it out */
module chamfer(r,h){
    translate([r, r, -1]){
        rotate([0,0,180])
        difference(){
            cube([r+1,r+1,h]);
            translate([0,0,-1]){
                cylinder(r=r, h=h+2, $fn=64);
            }
        }
    }
}