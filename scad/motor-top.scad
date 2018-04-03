    difference(){
        cube([60, 15, 26]);
        translate([-5,0,13]){
            rotate([0,90,0]){
                cylinder(r=13, h=70, $fn=128);
            }
        }
    }
