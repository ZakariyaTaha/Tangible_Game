import java.util.Collections; //<>//
import gab.opencv.*;

OpenCV opencv;

TwoDThreeD converter;
PVector rotations;

PImage img;
PImage imgT;
PImage imgD;
PImage houghImg;

//Scrollbar
HScrollbar hs;
float scrollPos;
HScrollbar hs2;
float scrollPos2;
HScrollbar hs3;
float scrollPos3;
HScrollbar hs4;
float scrollPos4;
HScrollbar hs5;
float scrollPos5;
HScrollbar hs6;
float scrollPos6;

float[][] GaussianKernel = { { 9, 12, 9 }, 
  { 12, 15, 12 }, 
  { 9, 12, 9 }};
float GaussianFactor = 99.f;

// Blob Detection
BlobDetection Blob = new BlobDetection();
// Discretization
float discretizationStepsPhi = 0.06f;
float discretizationStepsR = 2.5f;
int minVotes=50;
int rDim =0;  // hough before creating image or these values will be 0
int phiDim = 0;

// Hough
List<PVector> houghList;

// Quad Graph
QuadGraph quadGraph = new QuadGraph();
List<PVector> quadList = new ArrayList<PVector>();

void settings() {
  size(1500, 400);
}
void setup() {
  opencv = new OpenCV(this, 100, 100);
  
  img = loadImage("board1.jpg");

  // Les scrollbar pour le blurr et detectEdges 

  hs = new HScrollbar(2*width/3, height-30, width/3, 20);
  hs2 = new HScrollbar(2*width/3, height-60, width/3, 20);
  hs3 = new HScrollbar(2*width/3, height-90, width/3, 20);
  hs4 = new HScrollbar(2*width/3, height-120, width/3, 20);
  hs5 = new HScrollbar(2*width/3, height-150, width/3, 20);
  hs6 = new HScrollbar(2*width/3, height-180, width/3, 20);


  noLoop(); // no interactive behaviour: draw() will be called only once.
}
void draw() {

  PImage img2 = img.copy();
  img2.loadPixels();  
  imgD = pipeline(img2);
  // image(imgD, 0, 0);
  quadList = quadGraph.findBestQuad(houghList, img.width, img.height, 10000000, 10000, false);
  displayLines(houghList, quadList, img);
  img2.resize(500,400);
  img2 = scharr(img2);
  image(img2, width/3,0);
  imgT = img.copy();
  thresholdHSB(imgT, 88, 141, 88, 255, 15, 150);
  imgT = convolute(imgT, GaussianKernel, GaussianFactor);
  imgT = Blob.findConnectedComponents(imgT, false);
  image(imgT, 2*width/3,0);
  
  converter = new TwoDThreeD(img.width, img.height, 0);  /// Peut-etre faut-il diviser par 3 ? (pour les coordonnées aussi d'ailleurs)
 /* println(quadList);
  List<PVector> points2D = new ArrayList<PVector>();
  for(int i=0; i<quadList.size();++i){
    PVector temp = new PVector(quadList.get(i).x, quadList.get(i).y);
    points2D.add(temp);
  }
  println(points2D);
  rotations = converter.get3DRotations(points2D);
  */
  rotations = converter.get3DRotations(quadList);
  println(rotations);
}
PImage threshold(PImage img, int threshold) {

  PImage result = createImage(img.width, img.height, RGB);
  for (int i = 0; i < img.width * img.height; i++) {
    if (brightness(img.pixels[i])< threshold) {
      result.pixels[i] = color(0, 0, 0);
    } else {
      result.pixels[i] = img.pixels[i];
    }
  }
  result.updatePixels();
  return result;
}
PImage thresholdInverted(PImage img, int threshold) {

  PImage result = createImage(img.width, img.height, RGB);
  for (int i = 0; i < img.width * img.height; i++) {
    if (brightness(img.pixels[i])>threshold) {
      result.pixels[i] = color(0, 0, 0);
    } else {
      result.pixels[i] = img.pixels[i];
    }
  }
  result.updatePixels();
  return result;
}

void thresholdHSB(PImage img, int minH, int maxH, int minS, int maxS, int minB, int maxB) {
  // PImage img = img.copy();
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
boolean imagesEqual(PImage img1, PImage img2) {
  if (img1.width != img2.width || img1.height != img2.height)
    return false;
  for (int i = 0; i < img1.width*img1.height; i++)
    //assuming that all the three channels have the same value
    if (red(img1.pixels[i]) != red(img2.pixels[i])) {
      println( img1.pixels[i] + " but " + img2.pixels[i] + " and i = " + i);
      return false;
    }
  return true;
}

PImage convolute(PImage img, float[][] kernel, float normFactor) {
  // float normFactor = 200*scrollPos;
  // create a greyscale image (type: ALPHA) for output
  PImage result = createImage(img.width, img.height, ALPHA);

  // pixels by brightness (The implementations assume that the input image is in gray-scale, hence get the value of each pixel using the function brightness().)
  float[] pixelsByBrightness = new float[img.pixels.length];

  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      pixelsByBrightness[y*img.width+x] = brightness(img.pixels[y*img.width+x]);
    }
  }
  result.loadPixels();
  for (int x = 1; x < img.width-1; x++) {
    for (int y = 1; y < img.height-1; y++) {
      int intensity = 0;
      for (int a = x-1; a<= x+1; a++) {
        for (int b = y-1; b <= y+1; b++) {
          float brightness = pixelsByBrightness[b*img.width+a];
          intensity += brightness * kernel[a-x+1][b-y+1];
        }
      }
      int pixelValue = int(float(intensity)/normFactor);
      result.pixels[y*img.width+x] = color((pixelValue), (pixelValue), (pixelValue));
    }
  }

  result.updatePixels();
  return result;
}

PImage scharr(PImage img) {
  float[][] vKernel = {
    { 3, 0, -3 }, 
    { 10, 0, -10 }, 
    { 3, 0, -3 } };
  float[][] hKernel = {
    { 3, 10, 3 }, 
    { 0, 0, 0 }, 
    { -3, -10, -3 } };
  PImage result = createImage(img.width, img.height, ALPHA);
  // clear the image
  for (int i = 0; i < img.width * img.height; i++) {
    result.pixels[i] = color(0);
  }
  float max=0;
  float[] buffer = new float[img.width * img.height];
  // *************************************
  // Implement here the double convolution
  // *************************************

  float[] pixelsByBrightness = new float[img.pixels.length];
  for (int i = 0; i<pixelsByBrightness.length; ++i) {
    pixelsByBrightness[i] = color(0, 0, 0);
  }
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      pixelsByBrightness[y*img.width+x] = brightness(img.pixels[y*img.width+x]);
    }
  }
  result.loadPixels();

  for (int x = 1; x < img.width-1; x++) {
    for (int y = 1; y < img.height-1; y++) {
      float sum_h = 0;
      float sum_v = 0;
      for (int a = x-1; a<= x+1; a++) {
        for (int b = y-1; b <= y+1; b++) {
          float brightness = pixelsByBrightness[b*img.width+a];
          sum_h += brightness * hKernel[a-x+1][b-y+1];
          sum_v += brightness * vKernel[a-x+1][b-y+1];
        }
      }
      float sum = sqrt(pow(sum_h, 2) + pow(sum_v, 2));
      buffer[y*img.width+x] = sum;
      if (sum>max) max=sum;
    }
  }
  for (int y = 1; y < img.height - 1; y++) { // Skip top and bottom edges
    for (int x = 1; x < img.width - 1; x++) { // Skip left and right
      int val=(int) ((buffer[y * img.width + x] / max)*255);
      result.pixels[y * img.width + x]=color(val);
    }
  }
  return result;
}


List<PVector> hough(PImage edgeImg, int nLines) {
  edgeImg.loadPixels();
  edgeImg.resize(500,400);
  // dimensions of the accumulator
  phiDim = (int) (Math.PI / discretizationStepsPhi +1);
  //The max radius is the image diagonal, but it can be also negative
  rDim = (int) ((sqrt(edgeImg.width*edgeImg.width +
    edgeImg.height*edgeImg.height) * 2) / discretizationStepsR +1);
  // pre-compute the sin and cos values
  float[] tabSin = new float[phiDim]; 
  float[] tabCos = new float[phiDim];
  float ang = 0;
  float inverseR = 1.f / discretizationStepsR;
  for (int accPhi = 0; accPhi < phiDim; ang += discretizationStepsPhi, accPhi++) {
    // we can also pre-multiply by (1/discretizationStepsR) since we need it in the Hough loop 
    tabSin[accPhi] = (float) (Math.sin(ang) * inverseR);
    tabCos[accPhi] = (float) (Math.cos(ang) * inverseR);
  }
  // our accumulator
  int[] accumulator = new int[phiDim * rDim];
  // Fill the accumulator: on edge points (ie, white pixels of the edge
  // image), store all possible (r, phi) pairs describing lines going
  // through the point
  for (int y = 0; y < edgeImg.height; y++) {
    for (int x = 0; x < edgeImg.width; x++) {
      // Are we on an edge?
      if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {
        for (int phi=0; phi<phiDim; ++phi) {
          float r = x*tabCos[phi] + y*tabSin[phi];
          r += rDim/2;
          accumulator[(int) (phi * rDim + r)]++;
        }
      }
    }
  }
  houghImg = createImage(rDim, phiDim, ALPHA);
  for (int i = 0; i < accumulator.length; i++) {
    houghImg.pixels[i] = color(min(255, accumulator[i]));
  }
  // You may want to resize the accumulator to make it easier to see:
  houghImg.resize(400, 400);
  houghImg.updatePixels();

  // n-best Lines
  /**
   ArrayList<Integer> bestCandidates = new ArrayList<Integer>();
   ArrayList<PVector> lines= new ArrayList<PVector>();
   for (int idx = 0; idx < accumulator.length; idx++) {
   if (accumulator[idx] > minVotes) {
   // first, compute back the (r, phi) polar coordinates:
   bestCandidates.add(idx);
   }
   }
   **/
  //Local maxima

  int sizeRegion = 10;
  ArrayList<Integer> bestCandidates = new ArrayList<Integer>();
  ArrayList<PVector> lines= new ArrayList<PVector>();
  for (int idx = 0; idx < accumulator.length; idx++) {
    if (accumulator[idx] > minVotes) {
      int nbMoreVotes = 0;
      for (int i = idx-sizeRegion/2; i < idx+sizeRegion/2; i++) {
        if (i >= sizeRegion/2 && i < accumulator.length-sizeRegion/2) {
          if (accumulator[i] > accumulator[idx]) {
            nbMoreVotes++;
          }
        }
      }
      if (nbMoreVotes == 0) {
        bestCandidates.add(idx);
      }
      // first, compute back the (r, phi) polar coordinates:
    }
  }
  Collections.sort(bestCandidates, new HoughComparator(accumulator));
  for (int i = 0; i < min(nLines, bestCandidates.size()); i++) {
    int idx = bestCandidates.get(i);
    int accPhi = (int) (idx / (rDim));
    int accR = idx - (accPhi) * (rDim);
    float r = (accR - (rDim) * 0.5f) * discretizationStepsR;
    float phi = accPhi * discretizationStepsPhi;
    lines.add(new PVector(r, phi));
  }
  return lines;
}


PImage pipeline(PImage img) {
  PImage result = createImage(img.width, img.height, ALPHA);
   // thresholdHSB(img, (int)(255*scrollPos), (int)(255*scrollPos2), (int)(255*scrollPos3), (int)(255*scrollPos4), (int)(255*scrollPos5), (int)(255*scrollPos6)); // only hue
  // thresholdHSB(img, (int)(255*scrollPos), (int)(255*scrollPos2), 100, 255, 45, 150);
  // println((int)(255*scrollPos)+ " " + (int)(255*scrollPos2) + " " + (int)(255*scrollPos3) + " " + (int)(255*scrollPos4) + " " + (int)(255*scrollPos5) + " " + (int)(255*scrollPos6));
   // thresholdHSB(img, 79, 141, 100, 255, 20, 150); 
  thresholdHSB(img, 88, 141, 88, 255, 15, 150);
  result = convolute(img, GaussianKernel, GaussianFactor);
  result = Blob.findConnectedComponents(result, true); // Il y avait img et pas result, mais ça a pas l'air de changer grand chose
  result = scharr(result);
  result = threshold(result, 210); // 200 à la place de 100 enlève tous les petites taches blanches au milieu du cadre
  houghList = hough(result, 7);
  result.updatePixels();
  return result;
}

void displayLines(List<PVector> lines, List<PVector> quadL, PImage edgeImg) {
  edgeImg.loadPixels();
  edgeImg.resize(500,400);
  image(edgeImg, 0, 0);
  for (int idx = 0; idx < lines.size(); idx++) {
    PVector line=lines.get(idx);
    float r = line.x;
    float phi = line.y;
    // Cartesian equation of a line: y = ax + b
    // in polar, y = (-cos(phi)/sin(phi))x + (r/sin(phi))
    // => y = 0 : x = r / cos(phi)
    // => x = 0 : y = r / sin(phi)
    // compute the intersection of this line with the 4 borders of
    // the image
    int x0 = 0;
    int y0 = (int) (r / sin(phi));
    int x1 = (int) (r / cos(phi));
    int y1 = 0;
    int x2 = edgeImg.width;
    int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi));
    int y3 = edgeImg.width;
    int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));
    // Finally, plot the lines
    stroke(204, 102, 0);
    if (y0 > 0) {
      if (x1 > 0)
        line(x0, y0, x1, y1);
      else if (y2 > 0)
        line(x0, y0, x2, y2);
      else
        line(x0, y0, x3, y3);
    } else {
      if (x1 > 0) {
        if (y2 > 0)
          line(x1, y1, x2, y2);
        else
          line(x1, y1, x3, y3);
      } else
        line(x2, y2, x3, y3);
    }
  }
  for (int idx = 0; idx < quadL.size(); idx++) {
    PVector quad=quadL.get(idx);
    stroke(0);
    fill(color(random(0, 255), random(0, 255), random(0, 255), 150));
    circle(quad.x, quad.y, 45);
  }
}
