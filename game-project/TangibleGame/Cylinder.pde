class Cylinder {
  float cylinderBaseSize = 25; 
  float cylinderHeight = 30; 
  int cylinderResolution = 40;
  PVector location = new PVector(0, 0, 0);

  PShape openCylinder = new PShape();
  PShape bottomCylinder = new PShape();
  PShape topCylinder = new PShape();
  PShape cylinder = new PShape();

  float angle; 

  float[] x = new float[cylinderResolution + 1]; 
  float[] y = new float[cylinderResolution + 1];

  boolean isDead = false;

  Cylinder(PVector pos) {
    this.location.x = pos.x;
    this.location.y = pos.y;
    this.location.z = cylinderHeight/2;
    cylinder = gameSurface.createShape(GROUP);
    //get the x and y position on a circle for all the sides 
    for (int i = 0; i < x.length; i++) { 
      angle = (TWO_PI / cylinderResolution) * i; 
      x[i] = sin(angle) * cylinderBaseSize; 
      y[i] = cos(angle) * cylinderBaseSize;
    }

    gameSurface.stroke(0);
    gameSurface.strokeWeight(1);
    gameSurface.fill(255, 0, 0); // red

    topCylinder = gameSurface.createShape();
    topCylinder.beginShape(TRIANGLE_FAN);
    topCylinder.vertex(0, 0, cylinderHeight); 
    for (int i = 0; i < x.length; i++) { 
      topCylinder.vertex(x[i], y[i], cylinderHeight);
    } 
    topCylinder.endShape();
    cylinder.addChild(topCylinder);

    openCylinder = gameSurface.createShape(); 
    openCylinder.beginShape(QUAD_STRIP); //draw the border of the cylinder
    for (int i = 0; i < x.length; i++) { 
      openCylinder.vertex(x[i], y[i], 0); 
      openCylinder.vertex(x[i], y[i], cylinderHeight);
    } 
    openCylinder.endShape();
    cylinder.addChild(openCylinder);

    bottomCylinder = gameSurface.createShape();
    bottomCylinder.beginShape(TRIANGLE_FAN);
    bottomCylinder.vertex(0, 0, 0); 
    for (int i = 0; i < x.length; i++) { 
      bottomCylinder.vertex(x[i], y[i], 0);
    } 
    bottomCylinder.endShape();
    cylinder.addChild(bottomCylinder);
  }

  void setIsDead() {
    isDead = true;
  }

  void display() {
    // Cylinders
    gameSurface.pushMatrix();
    gameSurface.translate(location.x, location.y, location.z);
    gameSurface.shape(cylinder);
    gameSurface.popMatrix();
  }
}
