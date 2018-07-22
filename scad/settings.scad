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
solar_controller_length = 50;

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