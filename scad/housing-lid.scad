include <settings.scad>

module housing_lid(){
    mirror([0,0,1]){
        union(){
            difference(){
                cube([lid_total_x, lid_total_y, lid_total_z]);
                union(){
                    translate([lid_thickness, lid_thickness, lid_thickness]){
                        cube([lid_internal_x, lid_internal_y, lid_internal_z + 1]);
                    }
                    for(i= [0 : 1 : 2]){
                        translate([led_x_offset + led_radius, led_y_offset - led_radius - i*(led_y_spacing + 2*led_radius), -1]){
                            cylinder(r = led_radius, h = thickness + 2, $fn=128);
                        }
                    }
                    translate([switch_center_x_offset, switch_center_y_offset, -1]){
                        cylinder(r = switch_hole_radius, h = thickness + 2, $fn = 128);
                    }
                    /*
                    translate([solar_controller_ports_x_offset, solar_controller_ports_y_offset, lid_thickness/2]){
                        cube([solar_controller_ports_x, solar_controller_width, thickness]);
                    }
                    */
                    translate([0,0,-1]){
                        chamfer(lid_thickness, lid_total_z + 3);
                        translate([lid_total_x, 0, 0]){
                            rotate([0,0,90]){
                                chamfer(lid_thickness, lid_total_z + 3);
                            }
                            translate([0, lid_total_y, 0]){
                                rotate([0,0,180]){
                                    chamfer(lid_thickness/2, lid_total_z + 3);
                                }
                            }
                        }
                        translate([0, lid_total_y, 0]){
                            rotate([0,0,-90]){
                                chamfer(lid_thickness/2, lid_total_z + 3);
                            }
                        }
                    }
                        
                }
            }
        }
        translate([lid_total_x/2 - 5, lid_thickness, lid_total_z - 1]){
            cube([10, 0.5, 1]);
        }
        translate([lid_thickness, lid_total_y/2 - 5, lid_total_z - 1]){
            cube([0.5, 10, 1]);
        }
        translate([lid_total_x/2 - 5, lid_total_y - lid_thickness - 0.5, lid_total_z - 1]){
            cube([10, 0.5, 1]);
        }
        translate([lid_total_x - lid_thickness - 0.5, lid_total_y/2 - 5, lid_total_z - 1]){
            cube([0.5, 10, 1]);
        }
        
    }
}


housing_lid();