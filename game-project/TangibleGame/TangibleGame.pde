import gab.opencv.*; //<>//
import processing.video.*;

Movie cam;

// Ball
Ball ball;

// Box
float widthPlate = 450;
float heightPlate = 330;
int epaisseurPlate = 30;

// Cylinder
Cylinder cylinderMouse;
float cylinderBaseSize = 25;
float cylinderHeight = 30; 
ArrayList<PVector> cylindersList = new ArrayList<PVector>();

// ParticleSystem
ParticleSystem ps;

// Robotnik
PShape robotnik;

//Scrollbar
HScrollbar hs;
float scrollPos;

// Surfaces
PGraphics gameSurface;
PGraphics scoreBoardBackground;

PGraphics topView;
float topViewWidth = 150;
float topViewBallRadius = 2*20/3;
float topViewCylinderRadius = 2*cylinderBaseSize/3;

PGraphics scoreBoard;
float scoreBoardWidth = 150;

PGraphics barChart;
float barChartWidth = 660;
float barChartCounter = 0;
float maxNbOfScores = 120;

int marginBottom = 150;

// Scores array
ArrayList<Float> scoresHistory = new ArrayList<Float>();

// Thresholding 
Thresholding imgproc;
PImage img;

void settings() {
  size(1000, 800, P3D);
}
void setup () {
  cam = new Movie(this, "testvideo.avi");
  cam.loop();
  cam.speed(0.1);
  opencv = new OpenCV(this, 100, 100);
  //PImage imgG = loadImage("board2.jpg");
  img = loadImage("board1.jpg");
  imgproc = new Thresholding();
  String []args = {"Image processing window"};
  PApplet.runSketch(args, imgproc);

  gameSurface = createGraphics(width, height-marginBottom, P3D);
  scoreBoardBackground = createGraphics(width, marginBottom, P3D);
  topView = createGraphics((int)topViewWidth, marginBottom, P2D);
  scoreBoard = createGraphics((int)scoreBoardWidth, marginBottom-10, P2D);
  barChart = createGraphics((int)barChartWidth, marginBottom-10, P2D);
  ball = new Ball();
  robotnik = loadShape("robotnik.obj");
  robotnik.scale(50);
  hs = new HScrollbar(10+topViewWidth+10+scoreBoardWidth+30, height-25, (int)barChartWidth, 15);
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  img = cam.get();
  // Thresholding
  PVector rot = imgproc.getRotation(img);
  rotateWithController(rot);
  // Jeu
  drawGame();
  image(gameSurface, 0, 0);
  // Partie du bas : 
  // background
  drawScoreBackground();
  image(scoreBoardBackground, 0, height-marginBottom);
  // vue du dessus du plateau
  drawTopView();
  image(topView, 10, height-marginBottom);
  // cadre pour score
  rect(10+topViewWidth+8, height-marginBottom+4, (int)scoreBoardWidth+4, marginBottom-8);
  // score
  drawScoreBoard();
  image(scoreBoard, 10+topViewWidth+10, height-marginBottom+4);  
  // cadre pour BarChat
  rect(10+topViewWidth+10+scoreBoardWidth+28, height-marginBottom+4, (int)barChartWidth, marginBottom-8);
  // bar chart
  drawBarChart();
  image(barChart, 10+topViewWidth+10+scoreBoardWidth+30, height-marginBottom+4);
  // Scrollbar
  hs.update();
  hs.display();
  scrollPos = hs.getPos();
}


void drawGame() {
  gameSurface.beginDraw();

  gameSurface.background(100);
  gameSurface.fill(0);
  gameSurface.text("RotationX :", 5, 15, 0);
  gameSurface.text(rotateSizeX, 70, 15, 0);  // RotationX and RotationY valeurs selon pdf  ne correspondent pas ( à corriger ? )
  gameSurface.text("RotationY :", 150, 15, 0);
  gameSurface.text(rotateSizeZ, 220, 15, 0);
  gameSurface.text("Speed :", 300, 15, 0);
  gameSurface.text(ball.velocity.mag(), 350, 15, 0);
  gameSurface.text("Ball location :", 5, 45, 0);
  gameSurface.text(ball.location.x + " - " + ball.location.y + " - " + ball.location.z, 90, 45, 0);
  gameSurface.text("Ball velocity :", 5, 75, 0);
  gameSurface.text(ball.velocity.x + " - " + ball.velocity.y + " - " + ball.velocity.z, 90, 75, 0);

  if (keyPressed == true && keyCode == SHIFT) {
    cylinderMouse = new Cylinder(new PVector(0, 0));
    // Plateau
    gameSurface.pushMatrix();
    gameSurface.translate(width/2, height/2, 0);
    gameSurface.stroke(0);
    gameSurface.strokeWeight(1);
    gameSurface.fill(153);
    gameSurface.rect(-widthPlate/2, -heightPlate/2, widthPlate, heightPlate);
    //Affichage de la balle
    gameSurface.rotateX(-PI/2);
    ball.display();
    gameSurface.popMatrix();

    // Cylindre qui se déplace avec la souris
    gameSurface.pushMatrix();
    gameSurface.translate(mouseX, mouseY, 0); 
    cylinderMouse.display();
    gameSurface.popMatrix();

    //Affichage des cylindres
    if (ps != null) {
      for (int i = 0; i < ps.particles.size(); i++) {
        ps.particles.get(i).display();
      }
    }
  } else {
    gameSurface.pushMatrix();
    gameSurface.translate(width/2, height/2, 0);
    gameSurface.rotateX(rotateSizeX);
    gameSurface.rotateZ(rotateSizeZ);
    gameSurface.stroke(0);
    gameSurface.strokeWeight(1);
    gameSurface.fill(153);
    gameSurface.box(widthPlate, epaisseurPlate, heightPlate);
    gameSurface.translate(0, -ball.radius-epaisseurPlate/2, 0);
    ball.update();
    ball.checkEdges();
    if (ps != null) {
      ball.checkCylinderCollision(ps.particlesVector, ps.particles);
    }
    ball.display();
    gameSurface.popMatrix();

    //Affichage des cylindres (Peut etre a modifier) et de Robotnik
    if (ps != null && !ps.particleEnd) {
      gameSurface.pushMatrix();
      gameSurface.translate(width/2, height/2, 0);
      gameSurface.rotateX(rotateSizeX+PI/2);
      gameSurface.rotateY(rotateSizeZ);
      gameSurface.translate(-width/2, -height/2, 0);
      // Par defaut le frameRate est 60fps
      if (frameCount % 30 == 0) {
        ps.addParticle();
      }
      ps.run();
      gameSurface.popMatrix();

      // Robotnik
      gameSurface.pushMatrix();
      gameSurface.translate(width/2, height/2, 0);
      gameSurface.rotateX(PI+rotateSizeX);
      gameSurface.rotateY(PI);
      gameSurface.rotateZ(rotateSizeZ);
      // Le vector origin represente le cylindre principale !
      gameSurface.translate((width/2)-ps.origin.x, cylinderHeight, ps.origin.y-(height/2));
      gameSurface.shape(robotnik);
      gameSurface.popMatrix();
    }
  }

  gameSurface.endDraw();
}

void drawScoreBackground() {
  scoreBoardBackground.beginDraw();
  scoreBoardBackground.background(200);
  scoreBoardBackground.endDraw();
}

void drawTopView() {
  topView.beginDraw();
  topView.background(0, 50, 150);
  // Display ball
  float ballX = map(ball.location.x, -(widthPlate/2)+ball.radius, (widthPlate/2)-ball.radius, topViewBallRadius/2, topViewWidth-topViewBallRadius/2);
  float ballY = map(ball.location.z, -(heightPlate/2)+ball.radius, (heightPlate/2)-ball.radius, topViewBallRadius/2, topViewWidth-topViewBallRadius/2);
  topView.fill(0, 150, 0);
  topView.ellipse(ballX, ballY, topViewBallRadius, topViewBallRadius);

  // Display cylinders A CORRIGER LA POSITION DES CYLINDRES 
  // Le vector origin represente le cylindre principale !
  if (ps != null && !ps.particleEnd) {
    float currCylX = map(ps.origin.x, width/2-widthPlate/2+cylinderBaseSize, width/2+widthPlate/2-cylinderBaseSize, topViewCylinderRadius/2, topViewWidth-topViewCylinderRadius/2);
    float currCylY = map(ps.origin.y, height/2-heightPlate/2+cylinderBaseSize, height/2+heightPlate/2-cylinderBaseSize, topViewCylinderRadius/2, topViewWidth-topViewCylinderRadius/2);
    topView.fill(255, 0, 0);
    topView.ellipse(currCylX, currCylY, topViewCylinderRadius, topViewCylinderRadius);
    for (int i = 1; i < ps.particles.size(); i++) {
      currCylX = map(ps.particlesVector.get(i).x, width/2-widthPlate/2+cylinderBaseSize, width/2+widthPlate/2-cylinderBaseSize, topViewCylinderRadius/2, topViewWidth-topViewCylinderRadius/2);
      currCylY = map(ps.particlesVector.get(i).y, height/2-heightPlate/2+cylinderBaseSize, height/2+heightPlate/2-cylinderBaseSize, topViewCylinderRadius/2, topViewWidth-topViewCylinderRadius/2);
      topView.fill(255);
      topView.ellipse(currCylX, currCylY, topViewCylinderRadius, topViewCylinderRadius);
    }
  }
  topView.endDraw();
}

void drawScoreBoard() { // A faire equilibrer les scores
  scoreBoard.beginDraw();
  scoreBoard.background(200);
  scoreBoard.fill(0);
  scoreBoard.text("Total Score :", 5, 15);
  scoreBoard.text("Velocity :", 5, 65);
  scoreBoard.text(ball.velocity.mag(), 5, 80);
  scoreBoard.text("Last Score :", 5, 120);
  if (ps != null) {
    scoreBoard.text(ps.score, 5, 30);
    scoreBoard.text(ps.lastScore, 5, 135);
  }
  scoreBoard.stroke(255); 

  scoreBoard.endDraw();
}

void drawBarChart() {
  barChart.beginDraw();
  barChart.background(255);
  barChart.translate(0, (marginBottom-10)/2);
  if (scoresHistory.size() > maxNbOfScores) {
    scoresHistory.clear();
  }
  if (frameCount % 60 == 0 && ps != null) { // Sur de la condition ?
    scoresHistory.add(ps.score);
  }
  if (scoresHistory.size() > 0) {
    for (int j=0; j<scoresHistory.size(); ++j) {
      for (int i=0; i< abs((int)(scoresHistory.get(j) / 20)); ++i) {
        barChart.stroke(0);
        if (scoresHistory.get(j) > 0) {
          barChart.fill(128, 0, 128);
          barChart.rect(barChartCounter*(barChartWidth/maxNbOfScores), -i*scrollPos*(marginBottom-10)/30, (barChartWidth/maxNbOfScores), scrollPos*(marginBottom-10)/30);
        } else {
          barChart.fill(128, 0, 128);
          barChart.rect(barChartCounter*(barChartWidth/maxNbOfScores), i*scrollPos*(marginBottom-10)/30, (barChartWidth/maxNbOfScores), scrollPos*(marginBottom-10)/30);
        }
      }
      ++barChartCounter;
    }
  }
  barChartCounter = 0;
  barChart.endDraw();
}

void thresholdHSB(PImage img, int minH, int maxH, int minS, int maxS, int minB, int maxB) {
  img.loadPixels();
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      if (hue(img.pixels[y*img.width+x])>maxH || hue(img.pixels[y*img.width+x])<minH
        || saturation(img.pixels[y*img.width+x]) > maxS || saturation(img.pixels[y*img.width+x])<minS
        || brightness(img.pixels[y*img.width+x])>maxB || brightness(img.pixels[y*img.width+x])<minB) {
        img.pixels[y*img.width+x] = color(0, 0, 0);
      } else {
        img.pixels[y*img.width+x] = color(255, 255, 255);
      }
    }
  }

  img.updatePixels();
}

float rotateSizeX = 0;
float rotateSizeZ = 0;
float divider = 50; // speed of the rotation increase when it decrease

void mouseDragged() 
{ 
  if (mouseY - pmouseY < 0 && rotateSizeX < PI/3) {
    rotateSizeX += PI/divider;
  } else if (mouseY - pmouseY > 0 && rotateSizeX>-PI/3) {
    rotateSizeX -= PI/divider;
  } else if (mouseX - pmouseX < 0 && rotateSizeZ>-PI/3) {
    rotateSizeZ -= PI/divider;
  } else if (mouseX - pmouseX > 0 && rotateSizeZ<PI/3) {
    rotateSizeZ += PI/divider;
  }
}

void mouseWheel(MouseEvent event)
{
  float e = event.getCount();
  if (e < 0 && divider < 100) {
    divider += 5;
  } else if (e > 0 && divider > 10) {
    divider -= 5;
  }
}

void mouseClicked() {
  if (keyPressed == true && keyCode == SHIFT) {
    // Si la position du cylindre est sur la plateforme
    if (mouseX < (width/2+widthPlate/2)-cylinderBaseSize && mouseX > (width/2-widthPlate/2)+cylinderBaseSize 
      &&  mouseY < (height/2+heightPlate/2)-cylinderBaseSize && mouseY > (height/2-heightPlate/2)+cylinderBaseSize) {
      // Si la position du cylindre est pas sur la balle (Peut etre a ameliorer)
      PVector diffBall = new PVector((mouseX-width/2)-ball.location.x, (mouseY-height/2)-ball.location.z);
      // Si le cylindre n'entre pas en collision avec la balle ou les autres cylindres
      //     if (!(diffBall.mag() < ball.radius+cylinderBaseSize) && collCyl == false) {
      if (!(diffBall.mag() < ball.radius+cylinderBaseSize)) {
        PVector posCylinder = new PVector(mouseX, mouseY);
        ps = new ParticleSystem(posCylinder);
      }
    }
  }
}

void rotateWithController(PVector rot) { 
  float controllerRotationX = rot.x;
  float controllerRotationY = rot.y;
  rotateSizeX = controllerRotationX;
  rotateSizeZ = controllerRotationY;
}
