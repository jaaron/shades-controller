
d0 = 10;
h1 = 30;
theta = 60;

thickness = 5;
hook = 10;

p  = 138 + 2*thickness;
/*

difference(){
polygon([[0,0], [d0 + p*cos(theta), 0], [d0, p*sin(theta)], [0,p*sin(theta)]]);
polygon([[thickness,thickness], [d0 + p*cos(theta)-thickness, thickness], 
         [d0, p*sin(theta) - thickness], [thickness, p*sin(theta) - thickness]]);
}

*/

module chamfer(r,h){
    difference(){
        cube([r+1,r+1,h]);
        translate([0,0,-1]){
            cylinder(r=r, h=h+2, $fn=64);
        }
    }
}


difference(){
    union(){
        translate([p*cos(theta) + d0,0,0]){
            rotate([0,0,90-theta]){
                cube([thickness, p, thickness]);
                translate([thickness, 0, 0]){
                    cube([thickness, thickness, thickness]);
                    translate([thickness, 0, 0]){
                        intersection(){
                            translate([0,thickness, 0]){
                                cylinder(r = thickness, h=thickness);
                            }
                            cube([thickness, 2*thickness, thickness]);
                        }
                    }
                }
                translate([thickness, p - thickness, 0]){
                    cube([thickness, thickness, thickness]);
                    translate([thickness, 0, 0]){
                        intersection(){
                            cylinder(r = thickness, h=thickness);
                            translate([0,-thickness, 0]){
                                cube([thickness, 2*thickness, thickness]);
                            }
                        }
                    }
                }
            }
        }
        cube([p*cos(theta) + d0, thickness, thickness]);
        cube([thickness, p*sin(theta) + h1, thickness]);
        translate([0,p*sin(theta)-thickness,0]){
            cube([d0 + thickness, thickness, thickness]);
        }
        
        translate([0,thickness, 0]){
            rotate([0,0,-45]){
                cube([thickness, 75, thickness]);
            }
        }
        translate([0,55,0]){
            cube([55, thickness, thickness]);
        }
        
        translate([0, p*sin(theta) + h1, 0]){
            difference(){
                union(){
                    translate([hook/2, hook/2, 0]){
                        cylinder(r = hook/2, h=thickness, $fn=128);
                    }
                    cube([hook, hook/2, thickness]);
                }
                translate([thickness, -1, -1]){
                    cube([(hook - thickness)/2, 1+hook/2, thickness + 2]);
                }
            }
            /*
            difference(){
                cylinder(r = hook, h = thickness, $fn = 128);
                translate([0,0,-1]){
                    cylinder(r = thickness, h = thickness + 2, $fn=128);
                    translate([-(hook+1), -hook, 0]){
                        cube([2*hook - thickness + 1, hook, thickness+2]);
                    }
                }
            }
            */
        }
    }
    translate([thickness, thickness, -1]){
        rotate([0,0,180])
            chamfer(thickness,thickness+2);
    }
}