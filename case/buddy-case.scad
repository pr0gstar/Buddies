// Desk Buddy / Music Buddy case for the 2.4" "Cheap Yellow Display"
// (ESP32-2432S024R, TZT, USB-C). Parametric, OpenSCAD.
//
// part = "desk_front" | "desk_back" | "stand" | "music_front" | "music_back" | "preview_desk" | "preview_music"
//
// Coordinates: looking at the display, USB-C on the RIGHT edge,
// X right, Y up, origin = bottom-left corner of the PCB, Z = depth (0 = front face, +Z = backwards).
// Positions come from the manufacturer drawing (holes 3.2 mm from the edges, 68 x 36.5 mm apart)
// and from photos (connectors, buttons). Check them with a test print before printing everything.

part = "preview_desk";

/* [Measure these on your board] */
disp_t      = 4.2;   // display module thickness above the PCB front (glass to PCB)
touch_gap   = 0.4;   // gap so the bezel never presses the resistive touch panel
btn_h       = 2.5;   // height of the BOOT button above the PCB back side

/* [Battery (music buddy)] */
batt        = [45, 30, 10];   // LiPo L x W x H
batt_tol    = 1.0;

/* [Case] */
wall        = 2.0;
front_t     = 1.6;
back_t      = 2.0;
clr         = 0.5;     // PCB to inner wall
r_corner    = 3.0;
lip_h       = 2.0;
lip_t       = 1.2;
fit         = 0.2;     // lid lip clearance
desk_back_clear  = 7.5;   // free space behind the PCB (desk buddy)
music_back_clear = 6.0;   // space behind the PCB before the battery (music buddy)
bat_plug_extra   = 7.0;   // room above the board edge for the battery plug (music buddy)
tilt        = 15;      // stand angle, degrees backwards

$fn = 48;

// ---------- board ----------
bw = 74.4; bh = 42.9; pcb_t = 1.6;
holes = [[3.2, 3.2], [3.2, 39.7], [71.2, 3.2], [71.2, 39.7]];
active = [48.96, 36.72];
active_c = [39.9, bh/2];
ldr  = [7.0, 36.9];       // light sensor, front side
led  = [70.4, 34.0];      // RGB LED, front side
boot = [16.5, 40.1];      // BOOT button, back side (RST sits at X 13.3, not exposed)
usbc_y = 18.8;            // USB-C centre on the right edge, back side
sw1_x  = [53.8, 58.4];    // battery slide switch, top edge, back side
bat_x  = [59.3, 69.5];    // battery connector + plug, top edge

post_h = disp_t + touch_gap;
zP = front_t + post_h;    // PCB front
zB = zP + pcb_t;          // PCB back

function zE(music) = zB + (music ? music_back_clear + batt[2] + batt_tol + 1 : desk_back_clear);

x0 = -clr - wall; x1 = bw + clr + wall;
y0 = -clr - wall; y1 = bh + clr + wall;
W = x1 - x0; H = y1 - y0;

module rrect(p0, p1, r) {
  translate([p0[0] + r, p0[1] + r]) offset(r = r) square([p1[0] - p0[0] - 2*r, p1[1] - p0[1] - 2*r]);
}
module inner2d() { rrect([-clr, -clr], [bw + clr, bh + clr], max(0.5, r_corner - wall)); }
module outer2d() { rrect([x0, y0], [x1, y1], r_corner); }

// ---------- front shell ----------
module front_shell(music) {
  ze = zE(music);
  difference() {
    union() {
      linear_extrude(ze) outer2d();
      if (music) hood_outer(ze);
    }
    // cavity
    translate([0, 0, front_t]) linear_extrude(ze) inner2d();
    if (music) hood_inner(ze);
    // display window with chamfer
    for (s = [0, 1]) hull() {
      translate([active_c[0], active_c[1], front_t]) cube([active[0] + 1.6, active[1] + 1.6, 0.02], center = true);
      translate([active_c[0], active_c[1], 0]) cube([active[0] + 1.6 + 2*front_t, active[1] + 1.6 + 2*front_t, 0.02], center = true);
    }
    translate([active_c[0], active_c[1], front_t]) cube([active[0] + 1.6, active[1] + 1.6, 1], center = true);
    // light sensor + LED windows
    for (p = [ldr, led]) translate([p[0], p[1], -1]) cylinder(d = 3.2, h = front_t + 2);
    // USB-C (right wall)
    translate([bw - 1, usbc_y - 6.5, zB - 2]) cube([wall + clr + 2, 13, 7.5]);
    // battery switch slot (top wall) - only useful with a battery
    if (music) translate([sw1_x[0], bh - 1, zB - 0.5]) cube([sw1_x[1] - sw1_x[0], wall + clr + 2, 4.5]);
  }
  // screw posts (M3 self-tapping, or M2.5 with insert-free thread)
  for (h = holes) translate([h[0], h[1], front_t - 0.01])
    difference() { cylinder(d = 6, h = post_h); cylinder(d = 2.5, h = post_h + 1); }
}

// bump-out above the battery connector so the plug fits
module hood_outer(ze) {
  translate([bat_x[0] - 1.2, bh, front_t]) cube([bat_x[1] - bat_x[0] + 2.4, bat_plug_extra + clr + 1.2, ze - front_t]);
}
module hood_inner(ze) {
  translate([bat_x[0], bh - 1, front_t + 0.01]) cube([bat_x[1] - bat_x[0], bat_plug_extra + clr + 1, ze]);
}

// ---------- back covers ----------
// printed lying flat, outside face down (z = 0 is the outside)
module lip(music) {
  translate([0, 0, back_t - 0.01]) linear_extrude(lip_h)
    difference() { offset(delta = -fit) inner2d(); offset(delta = -fit - lip_t) inner2d(); }
  if (music) translate([bat_x[0] + fit, bh, back_t - 0.01])
    difference() {
      cube([bat_x[1] - bat_x[0] - 2*fit, bat_plug_extra + clr - fit, lip_h]);
      translate([lip_t, -1, -1]) cube([bat_x[1] - bat_x[0] - 2*fit - 2*lip_t, bat_plug_extra + clr - fit - lip_t + 1, lip_h + 2]);
    }
}

// cover is built mirrored in X: seen from behind, the board's left/right swap
module back_cover(music) {
  ze = zE(music);
  depth_to_btn = ze - zB - btn_h;            // cover inner face to BOOT top
  mirror([1, 0, 0]) translate([-bw, 0, 0]) {
    difference() {
      union() {
        linear_extrude(back_t) outer2d();
        if (music) translate([bat_x[0] - 1.2, bh, 0]) cube([bat_x[1] - bat_x[0] + 2.4, bat_plug_extra + clr + 1.2, back_t]);
        lip(music);
        if (music) battery_tray();
      }
      if (!music) {
        // U-cut flexure tongue over BOOT (root towards the bottom)
        tw = 4; tl = 13; s = 0.8;
        translate([boot[0] - tw/2 - s, boot[1] + 1.5 - tl, -1])
          difference() { cube([tw + 2*s, tl + s, back_t + 2]); translate([s, -1, -1]) cube([tw, tl + 1, back_t + 4]); }
        // thin the tongue
        translate([boot[0] - tw/2, boot[1] + 1.5 - tl, -1]) cube([tw, tl, 1 + back_t - 1.2]);
        // vent slots
        for (i = [0:4]) translate([30 + i*6, 12, -1]) cube([2, 18, back_t + 2]);
      } else {
        // pin hole for BOOT
        translate([boot[0], boot[1], -1]) cylinder(d = 2.2, h = ze);
      }
    }
    if (!music) // nub that presses BOOT
      translate([boot[0], boot[1], back_t - 0.01]) cylinder(d = 2.6, h = depth_to_btn - 0.6);
    else        // guide tube for a paper clip
      translate([boot[0], boot[1], back_t - 0.01]) difference() {
        cylinder(d = 4.6, h = depth_to_btn - 1);
        translate([0, 0, -1]) cylinder(d = 2.2, h = depth_to_btn + 2);
      }
  }
}

module battery_tray() {
  pl = batt[0] + batt_tol; pw = batt[1] + batt_tol; ph = batt[2] + batt_tol;
  cx = 37; cy = 19.5;    // keep clear of the BOOT tube and the corner screws
  translate([cx - pl/2, cy - pw/2, back_t - 0.01]) difference() {
    translate([-1.2, -1.2, 0]) cube([pl + 2.4, pw + 2.4, ph]);
    cube([pl, pw, ph + 1]);
    // cable exit towards the battery connector (top right seen from the front)
    translate([pl - 2, pw - 8, 2]) cube([4, 8, ph]);
  }
}

// ---------- stand (desk buddy) ----------
module case_envelope(d, c = 0) {
  translate([x0 - c, -c, -c]) cube([W + 2*c, d + 2*c, H + 2*c]);
}
module stand() {
  d = zE(false) + back_t;           // case depth incl. cover
  lift = d * sin(tilt) + 2;
  sw = W - 14;                      // narrower than the case: USB-C stays free
  difference() {
    hull() {
      translate([x0 + 7, -4, 0]) cube([sw, d * cos(tilt) + 26, 4]);              // base
      translate([0, 0, lift]) rotate([-tilt, 0, 0]) {
        translate([x0 + 7, -3, -lift]) cube([sw, 3, lift + 7]);                  // front lip
        translate([x0 + 7, d, -lift]) cube([sw, 4, lift + 28]);                  // back rest
      }
    }
    translate([0, 0, lift]) rotate([-tilt, 0, 0]) case_envelope(d, 0.4);
    // cable channel / weight saving under the case
    translate([x0 + 17, 6, -1]) cube([sw - 20, d * cos(tilt) - 6, 3]);
  }
}

// ---------- output ----------
if (part == "desk_front")  front_shell(false);
if (part == "desk_back")   back_cover(false);
if (part == "music_front") front_shell(true);
if (part == "music_back")  back_cover(true);
if (part == "stand")       stand();
if (part == "preview_desk") {
  d = zE(false) + back_t;
  stand();
  translate([0, 0, d * sin(tilt) + 2]) rotate([-tilt, 0, 0])
    multmatrix([[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, -y0], [0, 0, 0, 1]]) {
      color("gold") front_shell(false);
      translate([0, 0, zE(false) + back_t]) mirror([0, 0, 1]) mirror([1, 0, 0]) translate([-bw, 0, 0]) color("tomato") back_cover(false);
    }
}
if (part == "preview_music") {
  front_shell(true);
  translate([0, 0, zE(true) + back_t]) mirror([0, 0, 1]) mirror([1, 0, 0]) translate([-bw, 0, 0]) color("tomato") back_cover(true);
}
