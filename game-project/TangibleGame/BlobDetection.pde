import java.util.ArrayList; //<>// //<>// //<>// //<>//
import java.util.List;
import java.util.TreeSet;
class BlobDetection {

  PImage findConnectedComponents(PImage input, boolean onlyBiggest) {
    PImage result = createImage(input.width, input.height, ALPHA);

    // First pass: label the pixels and store labels' equivalences
    int [] labels = new int [input.width*input.height];
    List<TreeSet<Integer>> labelsEquivalences = new ArrayList<TreeSet<Integer>>();
    int currentLabel = 1;
    List<Integer> labelsEquivalencesChanged = new ArrayList<Integer>();
    color black = color(0, 0, 0);
    color white = color (255, 255, 255);
    for (int y=0; y<input.height; ++y) {
      for (int x=0; x<input.width; ++x) {

        int smallestLabel = input.width*input.height + 1;
        if (input.pixels[y * input.width + x] == white) {
          if (x>0) {
            if (labels[y * input.width + (x-1)]>0) {
              if (labels[y * input.width + (x-1)] < smallestLabel) {
                smallestLabel = labels[y * input.width + (x-1)];
              }
              labelsEquivalencesChanged.add(labels[y * input.width + (x-1)]);
            }
          }
          if (y>0) {
            if (x>0) {
              if (labels[(y-1) * input.width + (x-1)]>0 ) {
                if (labels[(y-1) * input.width + (x-1)] < smallestLabel) {
                  smallestLabel = labels[(y-1) * input.width + (x-1)];
                } 
                labelsEquivalencesChanged.add(labels[(y-1) * input.width + (x-1)]);
              }
            }
            if (labels[(y-1) * input.width + x]>0) {
              if (labels[(y-1) * input.width + x] < smallestLabel) {
                smallestLabel = labels[(y-1) * input.width + x];
              }
              labelsEquivalencesChanged.add(labels[(y-1) * input.width + x]);
            }
            if (x<input.width-1) {
              if (labels[(y-1) * input.width + (x+1)]>0) {
                if (labels[(y-1) * input.width + (x+1)] < smallestLabel) {
                  smallestLabel = labels[(y-1) * input.width + (x+1)];
                }
                labelsEquivalencesChanged.add(labels[(y-1) * input.width + (x+1)]);
              }
            }
          }
          if  (smallestLabel < input.width*input.height+1) { // Si un smallestLabel a été trouvé, la condition est respectée
            labels[y * input.width + x] = smallestLabel;
            for (int i = 0; i < labelsEquivalencesChanged.size(); ++i) {
              int currLabel = labelsEquivalencesChanged.get(i);
              for (int j = 0; j < labelsEquivalencesChanged.size(); ++j) {
                //TreeSet<Integer> temp = labelsEquivalences.get(labelsEquivalencesChanged.get(j)-1);
                //temp.add(currLabel);
                //labelsEquivalences.remove(labelsEquivalencesChanged.get(j)-1);
                // labelsEquivalences.add(labelsEquivalencesChanged.get(j)-1, temp); // Ce qui est censé marcher
                //labelsEquivalences.add(temp);  // Ce qui marche pour board 3 mais faux (en + marche pas pour board4)
                labelsEquivalences.get(labelsEquivalencesChanged.get(j)-1).add(currLabel);
              }
            }
            labelsEquivalencesChanged.clear();
          } else { // Sinon on lui assigne un nouveau label et on ajoute un TreeSet dans la liste
            labels[y * input.width + x] = currentLabel;
            labelsEquivalences.add(new TreeSet<Integer>());
            labelsEquivalences.get(currentLabel-1).add(currentLabel);
            currentLabel++;
          }
        }
      }
    }

    for (int i = 1; i < labelsEquivalences.size()+1; ++i) {
      for (int j = 0; j < labelsEquivalences.size(); ++j) {
        if (labelsEquivalences.get(j).contains(i)) {
          labelsEquivalences.get(j).addAll(labelsEquivalences.get(i-1));
        }
      }
    }
    // Second pass: re-label the pixels by their equivalent class
    // if onlyBiggest==true, count the number of pixels for each label

    int [] counterPixelsByLabels = new int[currentLabel-1];
    for (int y=0; y<input.height; ++y) {
      for (int x=0; x<input.width; ++x) {
        if (labels[y * input.width + x] > 0) {
          labels[y * input.width + x] = (labelsEquivalences.get(labels[y * input.width + x]-1)).first();
          if (onlyBiggest == true) {
            counterPixelsByLabels[labels[y * input.width + x]-1]++;
          }
        }
      }
    }
    // Finally:
    // if onlyBiggest==false, output an image with each blob colored in one uniform color
    // if onlyBiggest==true, output an image with the biggest blob in white and others in black
    result.loadPixels();
    if (onlyBiggest==true) {
      int biggestBlobSize = 0;
      int biggestBlobLabel = -1;
      for (int i=0; i<counterPixelsByLabels.length; ++i) { // length == currentLabel-2 normalement
        if (biggestBlobSize < counterPixelsByLabels[i]) {
          biggestBlobSize = counterPixelsByLabels[i];
          biggestBlobLabel = i+1;
        }
      }
      for (int y=0; y<input.height; ++y) {
        for (int x=0; x<input.width; ++x) {
          if (labels[y * input.width + x] == biggestBlobLabel) {
            result.pixels[y * input.width + x] = white;
          } else {
            result.pixels[y * input.width + x] = black;
          }
        }
      }
    } else {
      color [] colorByLabels = new color[currentLabel-1];
      for (int i=0; i<colorByLabels.length; ++i) { 
        colorByLabels[i] = color(random(0, 255), random(0, 255), random(0, 255));
      }
      for (int y=0; y<input.height; ++y) {
        for (int x=0; x<input.width; ++x) {
          if (labels[y * input.width + x] > 0) {
            result.pixels[y * input.width + x] = colorByLabels[labels[y * input.width + x]-1];
          } else {
            result.pixels[y * input.width + x] = black;
          }
        }
      }
    }

    return result;
  }
}
