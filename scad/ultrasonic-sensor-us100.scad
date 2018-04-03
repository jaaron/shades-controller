internal_length = 46;
internal_width = 22;
internal_height = 16;

/*
length = 51;
width  = 25;
height = 20;
*/
thickness = 2;

step_down       = 6;
cut_length      = 14;
step_down_depth = 9.5;


length = internal_length + 2*thickness;
width = internal_width + 2*thickness;
height = internal_height + thickness + step_down;

gap = 1;

base = false;
shell = true;
if(base){
    difference(){
        translate([-(width/2), -(length/2), 0]){
            cube([width, length, height]);
        }
        union(){
            translate([-(internal_width/2), -(internal_length/2), thickness + step_down]){
                cube([internal_width,internal_length, height + 5]);
            }
            translate([width/2 - step_down_depth,-(cut_length/2),thickness]){
                cube([10, cut_length,height + step_down]);
            }
        }
    }
}

if(shell){
    shell_width = width + 2*(thickness + gap);
    shell_length = length + 2*(thickness + gap);
    shell_height = height + gap + thickness;
    
    lense_true_radius = 8; 
    lense_far_y_offset = 19;
    lense_inner_y_offset = lense_far_y_offset - (2*lense_true_radius);
    
    lense_far_x_offset = 19;
    lense_inner_x_offset = lense_far_x_offset - (2*lense_true_radius); /* = 9 */
    
    lense_hole_radius = lense_true_radius + 0.5;
    lense_hole_y_offset = lense_inner_y_offset - 0.5;
    lense_hole_x_offset = lense_inner_x_offset - 0.5;
    
    shell_wing_length = 16;
    screw_hole_radius = 2;
    
    difference(){
        translate([-shell_width/2, -shell_length/2, shell_height -thickness]){    
            cube([shell_width, shell_length, thickness]);
            translate([0,0,-height]){        
                cube([shell_width, thickness, height]);
                translate([0,shell_length - thickness,0]){
                    cube([shell_width,thickness,height]);
                }
                cube([thickness, shell_length, height]);
                translate([shell_width - thickness, 0, (thickness + step_down)]){
                    cube([thickness, shell_length, height - (thickness + step_down)]);
                    translate([-(thickness + gap), (shell_length - cut_length)/2 + gap, gap]){
                        cube([thickness + gap, cut_length - (2*gap), height - (thickness + step_down + gap)]);
                    }
                }
        
            }
            translate([0,-shell_wing_length, -height]){
                difference(){
                    cube([shell_width, shell_wing_length, thickness]);
                    translate([shell_width/2, shell_wing_length/2, -1]){
                        cylinder(r = screw_hole_radius, h = thickness + 2, $fn=64);
                    }
                }
            }
            translate([0,shell_length, -height]){
                difference(){
                    cube([shell_width, shell_wing_length, thickness]);
                    translate([shell_width/2, shell_wing_length/2, -1]){
                        cylinder(r = screw_hole_radius, h = thickness + 2, $fn=64);
                    }
                }
            }
        }
        union(){
            translate([ (internal_width/2) - (lense_hole_x_offset + lense_hole_radius),
                        -(internal_length/2) + lense_hole_radius + lense_hole_y_offset, height]){
                cylinder(r=lense_hole_radius, h=10, $fn=64);
            }
            translate([(internal_width/2) - (lense_hole_x_offset + lense_hole_radius),
                        internal_length/2 - (lense_hole_radius + lense_hole_y_offset), height]){
                cylinder(r=lense_hole_radius, h=10, $fn=64);
            }
        }
    }
    }