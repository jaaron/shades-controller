include <settings.scad>

module thumbscrew_plate(){
    difference(){
        cube([thumbscrew_plate_w, thumbscrew_plate_l, thumbscrew_plate_thickness]);
        union(){
            translate([thumbscrew_plate_w/2, thumbscrew_radius+right_thumbscrew_offset-0.5, -1]){
                cylinder(r = thumbscrew_radius, h = 2*thumbscrew_plate_thickness, $fn=128);
                translate([0,0,thumbscrew_plate_thickness-thumbscrew_plate_inset_h + 1]){
                    cylinder(r=thumbscrew_plate_inset_r, h=thumbscrew_plate_thickness, $fn=6);
                }
            }
            translate([thumbscrew_plate_w/2, thumbscrew_plate_l-(thumbscrew_radius+left_thumbscrew_offset-0.5), -1]){
                cylinder(r = thumbscrew_radius, h = 2*thumbscrew_plate_thickness, $fn = 128);
                translate([0,0, thumbscrew_plate_thickness-thumbscrew_plate_inset_h + 1]){
                    cylinder(r=thumbscrew_plate_inset_r, h=thumbscrew_plate_thickness, $fn=6);
                }
            }
        }
    }
}

thumbscrew_plate();