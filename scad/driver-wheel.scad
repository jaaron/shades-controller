difference(){
    cylinder(r=13, h=12, $fn=128);
    union(){
        translate([0,0,6]){
            rotate_extrude(convexity=10, $fn=8){
                translate([13,0,0]){
                    circle(r=5,$fn=128);
                }
            }
        }
        translate([0,0,-2]){
            difference(){
                cylinder(r1=3, r2=2.5,h=20, $fn=128);
                translate([-3.2,0,6]){
                    cube([4,6,32], center=true);
                }
            }
        }
    }  
}