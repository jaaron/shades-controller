include <settings.scad>

/* punch an ellipse for a mounting screw through a surface of height h,
   assumes currently aligned to bottom of surface */
module mount_ellipse(h){
    union(){
        translate([0,0,h/2]){
            translate([-mount_hole_inset_r/2, 0, 0]) cylinder(r = mount_hole_inset_r, h = 3*h, $fn = 128);
            translate([0, 0, h/2]) cube([mount_hole_inset_r, 2*mount_hole_inset_r, h], center=true);
            translate([mount_hole_inset_r/2, 0, 0]) cylinder(r = mount_hole_inset_r, h = 3*h, $fn=128);
        }
        translate([0,0,-h]){
            translate([-mount_hole_r/2, 0, 0]) cylinder(r = mount_hole_r, h = 3*h, $fn = 128);
            translate([0, 0, h]) cube([mount_hole_r, 2*mount_hole_r, 3*h], center=true);
            translate([mount_hole_r/2, 0, 0]) cylinder(r = mount_hole_r, h = 3*h, $fn=128);
        }
    }
}

/* punch a circle for a mounting screw through a surface of height h,
   assumes currently aligned to bottom of surface */
module mount_hole(h){
    union(){
        translate([0,0,h/2]){
            cylinder(r = mount_hole_inset_r, 3*h, $fn=128);
        }
        translate([0,0,-h]){
            cylinder(r = mount_hole_r, 3*h, $fn=128);
        }
    }
}


module controller_housing(){
    if(side_by_side){
        difference(){
            translate([0, - (thickness + controller_y), 0]){
                cube([motor_housing_total_x, controller_y + thickness, total_z]);
            }
            /* controller cutout */
            translate([thickness, -controller_y, thickness]){
                cube([motor_housing_internal_x, controller_y+thickness, total_z]);
            }
            /* cut a hole for the power line */
            translate([-thickness, -20, thickness]){
                cube([3*thickness, 10, 10]);
            }
        }
    }else{
        translate([-(thickness + controller_y), 0, 0]){
            difference(){
                cube([controller_y + thickness, motor_housing_total_y, total_z]);
                union(){
                    translate([thickness, thickness, thickness]){
                        cube([controller_y+1, motor_housing_internal_y, total_z]);
                    }
                    /* cut a hole for the power line */
                    translate([thickness, -thickness, thickness]){
                        cube([controller_y, 3*thickness, 10]);
                    }
                    
                    /* cut a hole for the sensor line */
                    translate([thickness, controller_x, thickness]){
                        cube([2*thickness, 10, 10]);
                    }
                }
            }
        }
    }
}

module battery_housing(){
    if(with_battery_housing){
        if(!side_by_side){
            translate([-(thickness + controller_y), -(thickness + battery_height), 0]){
                battery_internal_x = battery_total_x - 2*thickness;
                difference(){
                    cube([battery_total_x, battery_height + thickness, total_z]);
                    translate([thickness, thickness, thickness]){
                        cube([battery_internal_x, battery_height+1, total_z]);
                    }
                }
            }
        }
    }
}

difference(){
    translate([-thickness, -thickness, -thickness]){
        union(){
            cube([motor_housing_total_x, motor_housing_total_y, total_z]);
            controller_housing();
            battery_housing();
        }
    }
    union(){
        translate([0, 0, motor_pad]){
            cube([motor_housing_internal_x, motor_housing_internal_y, total_z]);
            translate([padding, motor_housing_internal_y-1, 0]){
                cube([motor_housing_internal_x - (2*padding), thickness+2, motor_d + 5]);
            }
            /* cut a notch from the back of the motor to the 
                controller housing to run the wires*/
            if(side_by_side){
                translate([0,-2*thickness,motor_pad + (2/3)*motor_d]){
                    cube([motor_housing_internal_x, 3*thickness, total_z]);
                }
            }else{
                translate([-2*thickness, 0, motor_pad +  (2/3)*motor_d]){
                    cube([3*thickness, 10, total_z]);
                }
                if(with_battery_housing){
                    translate([-(thickness + controller_y), /* motor_housing_internal_x - solar_controller_length*/ ,
                                - 2*thickness, 
                                motor_pad +  (2/3)*motor_d]){
                        cube([motor_housing_internal_x + controller_y + thickness/* solar_controller_length */, 
                                    3*thickness, internal_z]);
                    }
                    
                }
            }
        }

        /* thumbscrew holes */
        translate([motor_housing_internal_x - 3, 0, motor_pad + (motor_d / 2)]){
            translate([0, motor_housing_internal_y - thumbscrew_radius - left_thumbscrew_offset, 0]){
                rotate([0,90,0]){
                    cylinder(r=thumbscrew_radius, h = 10, $fn=128);
                }
            }
            translate([0, thumbscrew_radius + right_thumbscrew_offset, 0]){
                rotate([0,90,0]){
                    cylinder(r=thumbscrew_radius, h = 10, $fn=128);
                }
            }
        }
        
        /* mount holes */
        translate([0,0,-thickness]){
            translate([0, motor_housing_internal_y - mount_hole_offset, 0]){
                /* upper left */
                translate([motor_housing_internal_x - mount_hole_offset, 0, 0]){
                    mount_hole(thickness + motor_pad);
                }
                
                /* lower left */
                translate([side_by_side ? mount_hole_offset : -(thickness + controller_y - mount_hole_offset), 0, 0]){
                        mount_ellipse(thickness + (side_by_side ? motor_pad : 0));
                }
            }

            translate([0, side_by_side ? mount_hole_offset - (thickness  + controller_y) : 
                          (with_battery_housing ? mount_hole_offset - (thickness + battery_height) :
                           mount_hole_offset),
                       0]){
                /* upper */
                translate([motor_housing_internal_x - mount_hole_offset, 0, 0]){
                    mount_hole(thickness + (side_by_side || with_battery_housing) ? 0 : motor_pad);
                }
                /* lower */
                translate([side_by_side ? mount_hole_offset : -(thickness + controller_y - mount_hole_offset), 0, 0]){
                        mount_ellipse(thickness);
                }
            }
        }
    }
}

/* make a little lip to slide the solar controller under*/
translate([0, motor_housing_internal_y - 10, internal_z - 2]){
    cube([2, 10, 2]);
    translate([motor_housing_internal_x - 2, 0, 0]){
        cube([2,10,2]);
    }
}


