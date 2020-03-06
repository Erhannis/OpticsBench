/**
A carriage, designed for running on angle aluminum.
Currently set up for 8x 686 bearings.
Could probably move opposing bearing to middle and use 6x instead.
Printed at -0.08mm horizontal extrusion (Cura).
*/

use <deps.link/erhannisScad/misc.scad>
use <deps.link/scadFluidics/common.scad>

$fn=60;
BIG = 1000;

INCH = 25.4;

HOLE_D = 0.2645*INCH;
GRID = 1*INCH;
BOARD_T = 4.14;

PEG_D = HOLE_D*0.9;
PEG_CAP_H = PEG_D/2;
PEG_ENCASED_H = BOARD_T*2;
PEG_UNENCASED_H = BOARD_T*1.5;
PEG_TAPER_H = BOARD_T*0.5;
PEG_TAPER_D = PEG_D*0.8;
PEG_H = PEG_TAPER_H+PEG_UNENCASED_H+PEG_ENCASED_H+PEG_CAP_H;

TARGET_DZ = GRID*1.5; // Z-level of the target plane of light on the bench, measured from the top of the base block surface.
TARGET_SZ = GRID; // Z-size of the target area of light on the bench, when it matters.

BLOCK_H = BOARD_T;

module peg(d=PEG_D, cap_h=PEG_CAP_H, encased_h=PEG_ENCASED_H, unencased_h=PEG_UNENCASED_H, taper_h=PEG_TAPER_H, taper_d=PEG_TAPER_D) {
  cylinder(h=taper_h, d1=taper_d, d2=d);
  translate([0,0,taper_h]) cylinder(h=unencased_h, d=d);
  translate([0,0,taper_h+unencased_h]) cylinder(h=encased_h, d=d);
  translate([0,0,taper_h+unencased_h+encased_h]) cylinder(h=cap_h, d1=d, d2=0);
}

/**
Base of an optics bench component.  Has peg holes at each of the four corners.
`sx` Integer.  Number of grid holes to span in X.
`sy` Integer.  Number of grid holes to span in Y.
`grid_dx` Grid x-spacing.
`grid_dy` Grid y-spacing.
`block_sz` Thickness of base.
`peg_d` Peg diameter.
`peg_cap_h` Peg cap height.
`peg_encased_h` Height of encased segment of peg.
`peg_unencased_h` Height of unencased segment of peg.
`peg_taper_h` Height of tapering bottom segment of peg.
`peg_taper_d` Small diameter of tapering bottom segment of peg.
`center` Whether to center the base.  If true, the origin touches the center-top point of the base block.

This module accepts children.  They are left as-is, except that the peg hole is subtracted from them, and anything below the bottom of the base is removed.
*/
module opticsBase(sx=1, sy=1, grid_dx=GRID, grid_dy=GRID, block_sz=BLOCK_H, peg_d=PEG_D, peg_cap_h=PEG_CAP_H, peg_encased_h=PEG_ENCASED_H, peg_unencased_h=PEG_UNENCASED_H, peg_taper_h=PEG_TAPER_H, peg_taper_d=PEG_TAPER_D, center=true) {
  translate(center ? [-sx*grid_dx/2,-sy*grid_dy/2,-block_sz] : [0,0,0]) {
    difference() {
      union() {
        translate(center ? [sx*grid_dx/2,sy*grid_dy/2,block_sz] : [0,0,0]) children();
        difference() { // Make rounded corners
          translate([-peg_d,-peg_d,0]) cube([grid_dx*sx+peg_d*2, grid_dy*sy+peg_d*2, block_sz]);
          for (x = [0,1]) for (y = [0,1]) {
           translate([x*sx*grid_dx,y*sy*grid_dy,0]) mirror([1-x,1-y,0]) cube([peg_d,peg_d,block_sz]);
          }
        }
        for (x = [0,sx]) for (y = [0,sy]) {
          translate([x*grid_dx,y*grid_dy,0]) cylinder(h=peg_encased_h+peg_d, d=peg_d*2);
        }
      }
      for (x = [0,sx]) for (y = [0,sy]) {
        translate([x*grid_dx,y*grid_dy,0]) translate([0,0,-peg_unencased_h-peg_taper_h]) peg(d=peg_d,cap_h=peg_cap_h,encased_h=peg_encased_h,unencased_h=peg_unencased_h,taper_h=peg_taper_h,taper_d=peg_taper_d);
      }
      OZm();
    }
  }
}

peg();

* opticsBase(sx=1,sy=1) { // Screen
  translate([0,0,1*INCH]) cube([GRID,3,2*INCH],center=true);
}

* opticsBase(sx=1,sy=1) { // Laser mount
  translate([0,0,TARGET_DZ]) {
    LASER_OD = 6;
    LASER_ID = 5;
    GROOVE_W = 1;
    CLIP_T = 2;
    CLIP_L = 5;
    CUTOFF = 0.65;

    difference() {
      union() {
        difference() {
          rotate([0,90,0]) cylinder(d=LASER_OD+CLIP_T,h=GROOVE_W,center=true);
          rotate([0,90,0]) cylinder(d=LASER_ID,h=GROOVE_W,center=true);
        }
        difference() {
          union() {
            translate([0,0,-TARGET_DZ]) cylinder(d=5,h=TARGET_DZ);
            rotate([0,90,0]) cylinder(d=LASER_OD+CLIP_T,h=CLIP_L,center=true);
          }
          rotate([0,90,0]) cylinder(d=LASER_OD,h=CLIP_L,center=true);
        }
      }
      OZp([0,0,CUTOFF*LASER_OD-(LASER_OD/2)]);
    }
  }
}

/**
This is a Thing Holder, a holder of things.
Atop its stem is a 90* angle, facing upward to hold potentially cylindrical objects.
It has a top plane that slots into the sconce, to keep Things in place.
*/
union() {
  SQ2 = sqrt(2);
  SQ12 = sqrt(1/2);
  SLOT_W = 2.5;
  DEFAULT_DZ = 10; // The height, from the inside corner of the sconce, at which the center of a default Thing rests if placed in the sconce.
  SCONCE_T = 5; // Thickness of the sconce (?)
  SCONCE_SZ = 20; // How tall the sconce is, measured from the inside corner
  SCONCE_SX = 20; // How long the sconce is
  BRACE_T = 2;

  SCONCE_S = SCONCE_SZ*SQ2;
  SCONCE_DZ = SCONCE_SZ-DEFAULT_DZ;

  * opticsBase(sx=1,sy=1) { // Thing Holder base
    translate([0,0,TARGET_DZ]) {
      difference() {
        union() {
          difference() {
            union() {
              // Pole
              translate([0,0,-TARGET_DZ]) cylinder(d=5,h=TARGET_DZ);
              // Sconce
              translate([0,0,SCONCE_DZ]) rotate([45,0,0]) rotate([0,90,0]) cube([SCONCE_S+SCONCE_T*2,SCONCE_S+SCONCE_T*2,SCONCE_SX],center=true);
              // Brace
              translate([0,0,SCONCE_DZ-((SCONCE_S+SCONCE_T*2)*SQ12)]) rotate([0,45,0]) cube([SCONCE_SX*SQ12,BRACE_T,SCONCE_SX*SQ12],center=true);
              translate([0,0,SCONCE_DZ-((SCONCE_S+SCONCE_T*2)*SQ12)]) translate([0,0,SCONCE_T*SQ12/2]) cube([SCONCE_SX,BRACE_T,SCONCE_T*SQ12],center=true);
            }
            // Sconce inside
            translate([0,0,SCONCE_DZ]) rotate([45,0,0]) rotate([0,90,0]) cube([SCONCE_S,SCONCE_S,SCONCE_SX],center=true);
            // Sconce slots
            cmirror([1,0,0]) for (dx = [0:SLOT_W*2:SCONCE_SX/2-SLOT_W]) {
              translate([dx,0,-SCONCE_SZ+SCONCE_DZ]) translate([0,0,BIG/2]) cube([SLOT_W,BIG,BIG],center=true);
            }
          }
        }
        OZp([0,0,SCONCE_DZ]);
        //OYp();
      }
    }
  }

  TOP_SZ = SLOT_W;
  
  // Thing Holder top
  * mirror([0,0,1]) difference() {
    translate([0,0,-TOP_SZ]) union() {
      cmirror([1,0,0]) for (dx = [0:SLOT_W*2:SCONCE_SX/2-SLOT_W]) {
        translate([dx,0,TOP_SZ/2]) cube([SLOT_W,(SCONCE_SZ+SCONCE_T*SQ2)*2,TOP_SZ],center=true);
      }
      translate([-(SCONCE_SX/2-SLOT_W),0,0]) rotate([45,0,0]) cube([(SCONCE_SX/2-SLOT_W)*2,BIG,BIG]);
    }
    OZp();
  }
}

* opticsBase(sx=1,sy=1) { // Mirror holder
  ANGLE_Z = 45;
  
  SQ2 = sqrt(2);
  SQ12 = sqrt(1/2);
  SLOT_W = 1;
  DEFAULT_DZ = 10; // The height, from the inside corner of the sconce, at which the center of a default Thing rests if placed in the sconce.
  SCONCE_T = 2.5; // Thickness of the sconce (?)
  SCONCE_SZ = 10; // How tall the sconce is, measured from the inside corner
  SCONCE_SX = 3*SLOT_W; // How long the sconce is
  BRACE_T = 2;

  SCONCE_S = SCONCE_SZ*SQ2;
  SCONCE_DZ = SCONCE_SZ-DEFAULT_DZ;

  rotate([0,0,ANGLE_Z]) translate([0,0,TARGET_DZ]) {
    difference() {
      union() {
        difference() {
          union() {
            // Pole
            translate([0,0,-TARGET_DZ]) cylinder(d=5,h=TARGET_DZ);
            // Sconce
            translate([0,0,SCONCE_DZ]) rotate([45,0,0]) rotate([0,90,0]) cube([SCONCE_S+SCONCE_T*2,SCONCE_S+SCONCE_T*2,SCONCE_SX],center=true);
            // Brace
            translate([0,0,SCONCE_DZ-((SCONCE_S+SCONCE_T*2)*SQ12)]) rotate([0,45,0]) cube([SCONCE_SX*SQ12,BRACE_T,SCONCE_SX*SQ12],center=true);
            translate([0,0,SCONCE_DZ-((SCONCE_S+SCONCE_T*2)*SQ12)]) translate([0,0,SCONCE_T*SQ12/2]) cube([SCONCE_SX,BRACE_T,SCONCE_T*SQ12],center=true);
          }
          // Sconce inside
          translate([0,0,SCONCE_DZ]) rotate([45,0,0]) rotate([0,90,0]) cube([SCONCE_S,SCONCE_S,SCONCE_SX+GRID],center=true);
          // Sconce slots
          cmirror([1,0,0]) for (dx = [0:SLOT_W*2:SCONCE_SX/2-SLOT_W]) {
            translate([dx,0,-SCONCE_SZ+SCONCE_DZ]) translate([0,0,BIG/2]) cube([SLOT_W,BIG,BIG],center=true);
          }
        }
      }
      OZp([0,0,SCONCE_DZ]);
      //OYp();
    }
  }
}