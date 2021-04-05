// A class to describe a group of Particles //<>// //<>// //<>//
class ParticleSystem { 
  ArrayList<Cylinder> particles; 
  ArrayList<PVector> particlesVector;
  PVector origin;
  boolean particleEnd = false;
  float score = 0;
  float lastScore = 0;

  ParticleSystem(PVector origin) {
    this.origin = origin.copy();
    particles = new ArrayList<Cylinder>(); 
    particlesVector = new ArrayList<PVector>();
    particles.add(new Cylinder(origin));
    particlesVector.add(origin);
  }

  void addParticle() { 
    if (!particleEnd) {
      PVector center;
      int numAttempts = 100;
      for (int i=0; i<numAttempts; i++) {
        // Pick a cylinder and its center.
        int index = int(random(particles.size()));
        center = particles.get(index).location.copy();
        // Try to add an adjacent cylinder.
        float angle = random(TWO_PI);
        center.x += sin(angle) * 2*cylinderBaseSize; 
        center.y += cos(angle) * 2*cylinderBaseSize; 
        if (checkPosition(center)) {
          // new cylinder created => lose points
          lastScore = -20;
          score += lastScore;
          particles.add(new Cylinder(center));
          particlesVector.add(center);
          break;
        }
      }
    }
  }
  // Check if a position is available, i.e.
  // - would not overlap with particles that are already created
  // (for each particle, call checkOverlap())
  // - is inside the board boundaries 
  boolean checkPosition(PVector center) {
    for (int i = 0; i < particles.size(); i++) {
      if (checkOverlap(particles.get(i).location, center)) {
        return false;
      }
    }
    if (center.x < (width/2+widthPlate/2)-cylinderBaseSize && center.x > (width/2-widthPlate/2)+cylinderBaseSize 
      &&  center.y < (height/2+heightPlate/2)-cylinderBaseSize && center.y > (height/2-heightPlate/2)+cylinderBaseSize) {
      // Si la position du cylindre est pas sur la balle (Peut etre a ameliorer)
      PVector diffBall = new PVector((center.x-width/2)-ball.location.x, (center.y-height/2)-ball.location.z);
      PVector diffCyl = new PVector(0, 0);
      boolean collCyl = false;
      for (int i = 0; i < particlesVector.size(); i++) {
        diffCyl.set(center.x-particlesVector.get(i).x, center.y-particlesVector.get(i).y);
        if (diffCyl.mag() < 2*cylinderBaseSize) {
          collCyl =  true;
        }
      }
      // Si le cylindre n'entre pas en collision avec la balle ou les autres cylindres
      if (!(diffBall.mag() < ball.radius+cylinderBaseSize) && collCyl == false) {
        return true;
      }
    }
    return false;
  }
  // Check if a particle with center c1
  // and another particle with center c2 overlap.
  boolean checkOverlap(PVector c1, PVector c2) {
    PVector dist = new PVector(c1.x - c2.x, c1.y - c2.y);
    if (dist.mag() < cylinderBaseSize*2) {
      return true;
    }
    return false;
  }
  // Iteratively update and display every particle,
  // and remove them from the list if their lifetime is over. 
  void run() {
    for (int i = 0; i<particles.size(); i++) {
      Cylinder p = particles.get(i);
      p.display();
      if (p.isDead) {
        lastScore = ball.velocity.mag()*4;
        score += lastScore;
        if (i == 0) {
          particles.clear();
          particlesVector.clear();
          particleEnd = true;
          break;
        } else {
          particles.remove(i);
          particlesVector.remove(i);
        }
      }
    }
  }
}
