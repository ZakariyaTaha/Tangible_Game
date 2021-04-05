class Ball { 
  PVector location;
  PVector velocity;
  PVector gravityForce;
  PVector friction;
  float gravityConstant = 0.9;
  float radius = 20;
  float elasticity = 0.8;


  Ball() {
    location = new PVector(0, 0, 0);  //changer location et vitesse en fct de l'angle
    velocity = new PVector(0, 0, 0);
    gravityForce = new PVector(0, 0, 0);
    friction = new PVector(0, 0, 0);
  }
  void update() {
    gravityForce.x = sin(rotateSizeZ) * gravityConstant;
    gravityForce.z = sin(-rotateSizeX) * gravityConstant;
    float normalForce = 1;
    float mu = 0.01;
    float frictionMagnitude = normalForce * mu;
    friction = velocity.copy();
    friction.mult(-1);
    friction.normalize();
    friction.mult(frictionMagnitude);

    velocity.add(gravityForce);
    velocity.add(friction);
    location.add(velocity);
  }
  void display() {
    gameSurface.pushMatrix();
    gameSurface.stroke(0);
    gameSurface.strokeWeight(0);
    gameSurface.fill(255, 255, 0); // Yellow
    gameSurface.translate(location.x, location.y, location.z);
    gameSurface.sphere(radius);
    gameSurface.popMatrix();
  }

  void checkEdges() {
    if (location.x > (widthPlate/2)-radius) {
      location.set(new PVector((widthPlate/2)-radius, location.y, location.z));
      velocity.x = velocity.x * -1;
      velocity.mult(elasticity);
    }
    if (location.x < -(widthPlate/2)+radius) {
      location.set(new PVector(-(widthPlate/2)+radius, location.y, location.z));
      velocity.x = velocity.x * -1;
      velocity.mult(elasticity);
    }
    if (location.z > (heightPlate/2)-radius) {
      location.set(new PVector(location.x, location.y, (heightPlate/2)-radius));
      velocity.z = velocity.z * -1;
      velocity.mult(elasticity);
    }
    if (location.z < -(heightPlate/2)+radius) {
      location.set(new PVector(location.x, location.y, -(heightPlate/2)+radius));
      velocity.z = velocity.z * -1;
      velocity.mult(elasticity);
    }
  }


  void checkCylinderCollision(ArrayList<PVector> cylindersList, ArrayList<Cylinder> cylList) {
    // Detection de la collision avec un cylindre
    for (int i = 0; i < cylindersList.size(); i++) {
      PVector curr = cylindersList.get(i);
      PVector diff = new PVector(location.x-(curr.x-width/2), location.z-(curr.y-height/2));
      // Si la norme du vecteur qui part du centre du cylindre au centre de la balle est plus 
      // petit que le rayon de la balle + celui du cylindre : il y a une collision !
      if (diff.mag() < radius+cylinderBaseSize) {
        diff.normalize();
        PVector oldDiff = diff.copy().mult(radius+cylinderBaseSize);
        PVector center = new PVector(width/2, height/2).mult(-1);
        PVector distCenterCyl = center.add(curr);
        PVector newLoc = distCenterCyl.add(oldDiff);
        PVector velOp = new PVector(velocity.x, velocity.z);
        diff.mult(2*velOp.dot(diff));
        velOp.sub(diff);
        velocity.x = velOp.x;
        velocity.y = 0;
        velocity.z = velOp.y;
        velocity.mult(elasticity);
        location.set(newLoc.x, 0, newLoc.y);
        cylList.get(i).setIsDead();
        break;
      }
    }
  }
}
