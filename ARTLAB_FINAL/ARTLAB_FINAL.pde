// Basic example of controlling an object with our own motion (by attaching a MouseJoint)
// Also demonstrates how to know which object was hit
PImage img;
// Size of each cell in the grid, ratio of window size to video size
int imageScale = 3;
// Number of columns and rows in the system
int cols, rows;
import shiffman.box2d.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.collision.shapes.Shape;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;
import java.util.*;
//sound
import ddf.minim.*;
Minim minim;
AudioPlayer player;
// A reference to our box2d world
Box2DProcessing box2d;
// Just a single box this time
Box box;
Spring spring;
// An ArrayList of particles that will fall on the surface
ArrayList < Particle > particles;
//Arraylist of images
PImage[] imgs = new PImage[20];
int imgsIndex = 0;
AudioPlayer[] players = new AudioPlayer[20];
// Perlin noise values
float xoff = 0;
float yoff = 1000;
//MOTION DETECTOR
import processing.video.*;
Capture video;
PImage prev;
float threshold = 25;
float motionX = 0;
float motionY = 0;
float lerpX = 0;
float lerpY = 0;
// update - Framecounter
int frameCounter = 0;
float lerpX2, lerpY2;


void setup() {
  // we pass this to Minim so that it can load files from the data directory
  minim = new Minim(this);
  size(533, 800);
  String[] cameras = Capture.list();
  printArray(cameras);

  //  *°*°*°*°*°*°*°*°*°*°
  // Cycle through each camera option, find one that matches 640x360 dimensions
  int cameraCount = 0;
  while (cameraCount < cameras.length && video == null) {
    println("Trying camera count " + cameraCount);
    println("Camera " + cameraCount + ": " + cameras[cameraCount]);
    //Check if you have a camera feed that is 640x360 and running at 15 fps which might be faster
    // If your camera doesn't have 15 fps as an option you'll need to change what's in "contains"
    if (cameras[cameraCount].contains("size=640x360,fps=15")) {
      // if we find the right camera, assign it to the video variable
      // By making the video variable no longer null, the while loop exits
      println("Found size=640x360, assigning");
      video = new Capture(this, cameras[cameraCount]);
    }
    println("Next camera");
    cameraCount++;
  }
  // if the while loop didn't find a 640x360 camera, just assign it to a default, 
  if (video == null) {
    println("Default camera");
    video = new Capture(this, cameras[0]);
  }
  video.start();
  // Hard-Assigning the dimensions of 640x360, if the camera defaults to a feed that doesn't have  
  // these dimensions, you'll need to adjust the dimensions below to match
  // You used 640x360 because it was more efficient
  println("Create Image");
  prev = createImage(video.height, video.width, RGB);

  //   *°*°*°*°*°*°*°*°*°*°


  noCursor();

  for (int i = 0; i < 20; i++) {
    imgs[i] = loadImage("../images/pngx800/" + i + ".png");

    //**PLAY AUDIO
    players[i] = minim.loadFile("../AUDIO2/" + i + ".mp3");
  }
  //img = loadImage("graphic(3).png");
  //MOTION DETECTOR


  // Initialize columns and rows  
  cols = width / imageScale;
  rows = height / imageScale;
  //size(400,300);
  //smooth();
  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  // Turn on collision listening!
  box2d.listenForCollisions();
  // Make the box
  box = new Box(width / 2, height / 2);
  // Create the empty list
  particles = new ArrayList < Particle > ();
  box2d.setGravity(0, 0);
  //sound
  // update - bind the spring to the box
  spring = new Spring();
  spring.bind(width / 2, height / 2, box);
}


void captureEvent(Capture video) {
  prev.copy(video, 0, 0, video.width, video.height, 0, 0, prev.width, prev.height);
  prev.updatePixels();
  video.read();
}


void draw() {
  background(0);
  video.loadPixels();
  prev.loadPixels();
  threshold = 50;
  int cnt = 0;
  float avgX = 0;
  float avgY = 0;
  loadPixels();
  // Begin loop to walk through every pixel
  for (int x = 0; x < video.width; x++) {
    for (int y = 0; y < video.height; y++) {
      int loc = x + y * video.width;
      // What is current color
      color currentColor = video.pixels[loc];
      // *°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°
      int r1 = (currentColor >> 16) & 0xFF;  // Faster way of getting red(argb)
      int g1 = (currentColor >> 8) & 0xFF;   // Faster way of getting green(argb)
      int b1 = currentColor & 0xFF;          // Faster way of getting blue(argb)

      //float r1 = red(currentColor);
      //float g1 = green(currentColor);
      //float b1 = blue(currentColor);
      // *°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°
      // *°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°
      color prevColor = prev.pixels[loc];
      int r2 = (prevColor >> 16) & 0xFF;  // Faster way of getting red(argb)
      int g2 = (prevColor >> 8) & 0xFF;   // Faster way of getting green(argb)
      int b2 = prevColor & 0xFF;          // Faster way of getting blue(argb)
      //float r2 = red(prevColor);
      //float g2 = green(prevColor);
      //float b2 = blue(prevColor);
      // *°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°*°
      float d = distSq(r1, g1, b1, r2, g2, b2);
      if (d > threshold * threshold) {
        //stroke(255);
        //strokeWeight(1);
        //point(x, y);
        avgX += width - x;
        avgY += y;
        cnt++;
        // update - don't need to display pixels here or after the else
        //pixels[loc] = color(255);
      } else {
        //pixels[loc] = color(0);
      }
    }
  }
  //println("Particle Size: " +particles.size() + " avg: " + avgX + " : " + avgY);

  updatePixels();
  // We only consider the color found if its color distance is less than 10. 
  // This threshold of 10 is arbitrary and you can adjust this number depending on how accurate you require the tracking to be.
  if (cnt > 800) {
    motionX = avgX / cnt;
    motionY = avgY / cnt;
    // Draw a circle at the tracked pixel
  }
  lerpX = lerp(lerpX, motionX, 0.1);
  lerpY = lerp(lerpY, motionY, 0.1);
  
 //   *°*°*°*°*°*°*°*°*°*°
//For some reason the collision object seemed to be hanging out mostly on the left side,
// by doubling the width in the map statement below (533*2), it seems more evenly distributed
  lerpX2 = map(lerpX, 0, 640, 0, 533*2);
  lerpY2 = map(lerpY, 0, 360, 0, 800);
   //   *°*°*°*°*°*°*°*°*°*°
   
//Debugging Ellipse to show where motion is translating
//stroke(255, 0, 0);
//ellipse(lerpX2, lerpY2, 30, 30);
  box.body.setLinearVelocity(new Vec2(lerpX, lerpY));

  playAudio();

  if (particles.size() < 2) {
    //int counter = 0;
    for (int i = 0; i < cols; i += 2) {
      // Begin loop for rows    
      for (int j = 0; j < rows; j += 2) {
        // Where are you, pixel-wise?      
        int x = i * imageScale;
        int y = j * imageScale;
        color c = imgs[imgsIndex].get(x, y);
        particles.add(new Particle(x, y, imageScale, c));
        //counter++;
        //println(counter + " :: "+ x+y*width + " :: "+ i+j*width);
      }
    }
  }
  // We must always step through time!
  box2d.step();

  int counter = 0;
  if (cnt > 200) {
    spring.update(lerpX2, lerpY2);
    //} else {
    //  spring.update(width/2, height + 400);
  }
  //// Look at all particles
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.display();
    // Particles that leave the screen, we delete them
    // (note they have to be deleted from both the box2d world and our list
    if (!p.origin()) {
      counter++;
    }
  }
  if (counter > particles.size() * 0.99) {
    //frameCounter++;
    //if (frameCounter > 200) {
    //println("here");
    for (Particle p : particles) { //int i = particles.size() - 1; i>= 0) {
      //p.fd.density = 1;
      // println("in the loop");
      p.attract();
    }
    //  frameCounter = 0;
    //}
  }
  //box.display();
  //println("FR" + ":" + frameRate + ": " + frameCount);
  //println(counter);
  //println(particles.size() - counter);

  if (!players[imgsIndex].isPlaying()) {

    updateColors();
  }
  //println(frameRate);
}



//**PLAY AUDIO
void playAudio() {
  //if (players[imgsIndex].position() == players[imgsIndex].length()) {
  //  //players[imgsIndex].rewind();
  //  players[imgsIndex].play();
  //  } else {
  //  players[imgsIndex].play();
  //}
}



float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

void updateColors() {
  //rewind tracks so they're ready for the next time they're played
  players[imgsIndex].rewind();
  //Pause the rewound track so it doesn't set off the isPlaying function
  players[imgsIndex].pause();
  imgsIndex++;
  if (imgsIndex > 19) {
    imgsIndex = 0;
  }
  // Play the next track
  players[imgsIndex].play();


  //for(Particle p : particles){
  //  p.killBody();
  //  particles.remove(p);
  //}
  for (int i = particles.size()-1; i >= 0; i--) {
    //Particle p = particles.get(i);
    //p.killBody();
    particles.get(i).killBody();
    particles.remove(i);
  }
  //int pixelCounter = 0;
  //int counter = 0;
  for (int i = 0; i < cols; i += 2) {
    // Begin loop for rows    
    for (int j = 0; j < rows; j += 2) {
      // Where are you, pixel-wise?      
      int x = i * imageScale;
      int y = j * imageScale;
      color c = imgs[imgsIndex].get(x, y);
      particles.add(new Particle(x, y, imageScale, c));
      //counter++;
    }
  }
  //}

  players[imgsIndex].play();
}
