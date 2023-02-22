import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 
import shiffman.box2d.*; 
import org.jbox2d.common.*; 
import org.jbox2d.dynamics.joints.*; 
import org.jbox2d.collision.shapes.*; 
import org.jbox2d.collision.shapes.Shape; 
import org.jbox2d.common.*; 
import org.jbox2d.dynamics.*; 
import org.jbox2d.dynamics.contacts.*; 
import ddf.minim.*; 
import processing.video.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class ARTLAB_FINAL extends PApplet {

/**
  Code: Property of Zoe Valladares
  Photographs: Property of Zoe Valladares
  Audio: Property of Zoe Valladares
  
  Contributors: Ian McDermott (https://github.com/ianmcdermott)
*/



// Physics Engine









// Sound and Audio Tools

Minim minim;
AudioPlayer player;

// Video and Motion Detection Tools

Capture video;

PImage img;
int imageScale = 3;
int cols, rows;
Box2DProcessing box2d;
Box box;
Spring spring;
ArrayList < Particle > particles;
PImage[] imgs = new PImage[20];
int imgsIndex = 0;
AudioPlayer[] players = new AudioPlayer[20];

float xoff = 0;
float yoff = 1000;

PImage prev;
float threshold = 25;
float motionX = 0;
float motionY = 0;
float lerpX = 0;
float lerpY = 0;

int frameCounter = 0;
float lerpX2, lerpY2;


public void setup() {
  minim = new Minim(this);
  
  String[] cameras = Capture.list();
  printArray(cameras);

  /**
    * Cycle through the camera list to choose one that matches:
    * 640 x 360
    * If none are found choose the default camera.
  */
  int cameraCount = 0;
  while (cameraCount < cameras.length && video == null) {
    if (cameras[cameraCount].contains("size=640x360,fps=15")) {
      println("Found size=640x360, assigning");
      video = new Capture(this, cameras[cameraCount]);
    }
    cameraCount++;
  } 
  if (video == null) {
    println("Default camera");
    video = new Capture(this, cameras[0]);
  }
  video.start();
  prev = createImage(video.height, video.width, RGB);

  noCursor();
  
  /**
    * Initialize the visuals and sound:
    * Images from ../images/pngx800
    * Audio from ../AUDIO2/
    *
    * Images are compressed to 533x800 px for efficiency
  */
  for (int i = 0; i < 20; i++) {
    imgs[i] = loadImage("../images/pngx800/" + i + ".png");
    players[i] = minim.loadFile("../AUDIO2/" + i + ".mp3");
  }


  /**
    * Initialize:
    * Physics
    * Invisible box for collision
  */
  cols = width / imageScale;
  rows = height / imageScale;
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.listenForCollisions();
  box = new Box(width / 2, height / 2);
  particles = new ArrayList < Particle > ();
  box2d.setGravity(0, 0);
  spring = new Spring();
  spring.bind(width / 2, height / 2, box);
}


public void captureEvent(Capture video) {
  prev.copy(video, 0, 0, video.width, video.height, 0, 0, prev.width, prev.height);
  prev.updatePixels();
  video.read();
}


public void draw() {
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
      int currentColor = video.pixels[loc];
      
      int r1 = (currentColor >> 16) & 0xFF;  // Faster way of getting red(argb)
      int g1 = (currentColor >> 8) & 0xFF;   // Faster way of getting green(argb)
      int b1 = currentColor & 0xFF;          // Faster way of getting blue(argb)
      
      int prevColor = prev.pixels[loc];
      
      int r2 = (prevColor >> 16) & 0xFF;  // Faster way of getting red(argb)
      int g2 = (prevColor >> 8) & 0xFF;   // Faster way of getting green(argb)
      int b2 = prevColor & 0xFF;          // Faster way of getting blue(argb)
      
      float d = distSq(r1, g1, b1, r2, g2, b2);
      if (d > threshold * threshold) {
        avgX += width - x;
        avgY += y;
        cnt++;
      } else {
      }
    }
  }
  //println("Particle Size: " +particles.size() + " avg: " + avgX + " : " + avgY);

  updatePixels();
  
  if (cnt > 800) {
    motionX = avgX / cnt;
    motionY = avgY / cnt;
  }
  lerpX = lerp(lerpX, motionX, 0.1f);
  lerpY = lerp(lerpY, motionY, 0.1f);
  
  /**
    * Ian McDermott:
    * For some reason the collision object 
    * seemed to be hanging out mostly on the left side,
    * by doubling the width in the map statement below 
    * (533*2), it seems more evenly distributed
  */
  lerpX2 = map(lerpX, 0, 640, 0, 533*2);
  lerpY2 = map(lerpY, 0, 360, 0, 800);

  box.body.setLinearVelocity(new Vec2(lerpX, lerpY));

  playAudio();

  if (particles.size() < 2) {
    for (int i = 0; i < cols; i += 2) {   
      for (int j = 0; j < rows; j += 2) {    
        int x = i * imageScale;
        int y = j * imageScale;
        int c = imgs[imgsIndex].get(x, y);
        particles.add(new Particle(x, y, imageScale, c));
        //println(counter + " :: "+ x+y*width + " :: "+ i+j*width);
      }
    }
  }
  
  box2d.step();

  int counter = 0;
  if (cnt > 200) {
    spring.update(lerpX2, lerpY2);
  }
  
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.display();
    
    if (!p.origin()) {
      counter++;
    }
  }
  if (counter > particles.size() * 0.99f) {
    for (Particle p : particles) {
      p.attract();
    }
  }
  //println("FR" + ":" + frameRate + ": " + frameCount);
  //println(counter);
  //println(particles.size() - counter);

  if (!players[imgsIndex].isPlaying()) {
    updateColors();
  }
}



//**PLAY AUDIO
public void playAudio() {
  //if (players[imgsIndex].position() == players[imgsIndex].length()) {
  //  //players[imgsIndex].rewind();
  //  players[imgsIndex].play();
  //  } else {
  //  players[imgsIndex].play();
  //}
}



public float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

public void updateColors() {
  players[imgsIndex].rewind();
  
  players[imgsIndex].pause();
  imgsIndex++;
  if (imgsIndex > 19) {
    imgsIndex = 0;
  }
  
  players[imgsIndex].play();
  
  for (int i = particles.size()-1; i >= 0; i--) {
    particles.get(i).killBody();
    particles.remove(i);
  }
  for (int i = 0; i < cols; i += 2) {    
    for (int j = 0; j < rows; j += 2) {    
      int x = i * imageScale;
      int y = j * imageScale;
      int c = imgs[imgsIndex].get(x, y);
      particles.add(new Particle(x, y, imageScale, c));
    }
  }
  players[imgsIndex].play();
}
/**
* Property of: Zoe Valladares
* 
* Code sampled from D. Shiffman
*
* The Nature of Code - Spring 2012
* Box2DProcessing example
* <http://www.shiffman.net/teaching/nature>
* 
* A Box
*/

class Box {
  Body body;
  float w;
  float h;

  Box(float x_, float y_) {
    float x = x_;
    float y = y_;
    w = 20;
    h = 20;
    makeBody(new Vec2(x, y), w, h);
    body.setUserData(this);
  }

  public void killBody() {
    box2d.destroyBody(body);
  }

  public boolean contains(float x, float y) {
    Vec2 worldPoint = box2d.coordPixelsToWorld(x, y);
    Fixture f = body.getFixtureList();
    boolean inside = f.testPoint(worldPoint);
    return inside;
  }

  public void display() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float a = body.getAngle();

    rectMode(PConstants.CENTER);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-a);
    fill(175);
    stroke(0);
    rect(0, 0, w, h);
    popMatrix();
  }

  public void makeBody(Vec2 center, float w_, float h_) {
    // Define and create the body
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(center));
    body = box2d.createBody(bd);

    // Define a polygon (this is what we use for a rectangle)
    PolygonShape sd = new PolygonShape();
    float box2dW = box2d.scalarPixelsToWorld(w_/2);
    float box2dH = box2d.scalarPixelsToWorld(h_/2);
    sd.setAsBox(box2dW, box2dH);

    // Define a fixture
    FixtureDef fd = new FixtureDef();
    fd.shape = sd;
    // Parameters that affect physics
    fd.density = 1;
    fd.friction = 0.3f;
    fd.restitution = 0.5f;

    body.createFixture(fd);

    // Give it some initial random velocity
    body.setAngularVelocity(random(-5, 5));
  }
}
/**
* Property of: Zoe Valladares
* 
* Code sampled from D. Shiffman
*
* The Nature of Code - Spring 2012
* Box2DProcessing example
* <http://www.shiffman.net/teaching/nature>
* 
* A circular particle
*/

class Particle {

  int r, g, b;
  Body body;
  float rad;
  int col;
  float tx, ty;

  Particle(float x, float y, float r_, int c_) {
    tx = x;
    ty = y;

    rad = r_;
    makeBody(x, y, rad);
    body.setUserData(this);

    col = c_;
    r = (col >> 16) & 0xFF;  // Faster way of getting red(argb)
    g = (col >> 8) & 0xFF;   // Faster way of getting green(argb)
    b = col & 0xFF;          // Faster way of getting blue(argb)
  }

  public void killBody() {
    box2d.destroyBody(body);
  }


  public boolean origin() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    if (pos.x >= tx - rad*.9f && pos.x <= + rad*.9f && pos.y >= ty - rad*.9f &&  pos.y <= ty + rad*.9f)  return true;
    else  return false;
  }
  
  public void updateColor(int c) {
    r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
    g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
    b = c & 0xFF;          // Faster way of getting blue(argb)  }
  }
  
  public void attract() {
    // From BoxWrap2D example
    Vec2 worldTarget = box2d.coordPixelsToWorld(tx, ty);   
    Vec2 bodyVec = body.getWorldCenter();
    // First find the vector going from this body to the specified point
    worldTarget.subLocal(bodyVec);
    // Then, scale the vector to the specified force
    worldTarget.normalize();
    worldTarget.mulLocal((float) 50);
    // Now apply it to the body's center of mass.
    body.applyForce(worldTarget, bodyVec);
    if (origin()) {
      body.setLinearVelocity(new Vec2(0, 0));
    }
  }

  public void display() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    pushMatrix();
    translate(pos.x, pos.y);
    fill(r, g, b);
    noStroke();      
    ellipse(0, 0, rad*2, rad*2);

    popMatrix();
  }

  public void makeBody(float x, float y, float rad) {
    // Define a body
    BodyDef bd = new BodyDef();
    // Set its position
    bd.position = box2d.coordPixelsToWorld(x, y);
    bd.type = BodyType.DYNAMIC;
    body = box2d.createBody(bd);

    // Make the body's shape a circle
    CircleShape cs = new CircleShape();
    cs.m_radius = box2d.scalarPixelsToWorld(rad);

    FixtureDef fd = new FixtureDef();
    fd.shape = cs;
    //Parameters that affect physics
    fd.density = 10;
    fd.friction = 0.1f;
    fd.restitution = 0.01f;

    //Attach fixture to body
    body.createFixture(fd);
    body.setLinearVelocity(new Vec2(0, 0));
  }
}
/**
* Property of: Zoe Valladares
* 
* Code sampled from D. Shiffman
*
* The Nature of Code - Spring 2012
* Box2DProcessing example
* <http://www.shiffman.net/teaching/nature>
* 
* Class to describe the spring joint (displayed as a line)
*/

class Spring {
  MouseJoint mouseJoint;

  Spring() {
    mouseJoint = null;
  }

  /**
    * If it exists we set its target to the mouse location 
  */
  public void update(float x, float y) {
    if (mouseJoint != null) {
      // Always convert to world coordinates!
      Vec2 mouseWorld = box2d.coordPixelsToWorld(x,y);
      mouseJoint.setTarget(mouseWorld);
    }
  }

  public void display() {
    if (mouseJoint != null) {
      // We can get the two anchor points
      Vec2 v1 = new Vec2(0,0);
      mouseJoint.getAnchorA(v1);
      Vec2 v2 = new Vec2(0,0);
      mouseJoint.getAnchorB(v2);
      // Convert them to screen coordinates
      v1 = box2d.coordWorldToPixels(v1);
      v2 = box2d.coordWorldToPixels(v2);
      // And just draw a line
      stroke(0);
      strokeWeight(1);
      line(v1.x,v1.y,v2.x,v2.y);
    }
  }

  /**
    * This is the key function where
    * we attach the spring to an x,y location
    * and the Box object's location
  */
  public void bind(float x, float y, Box box) {
    // Define the joint
    MouseJointDef md = new MouseJointDef();
    
    // Body A is just a fake ground body for simplicity (there isn't anything at the mouse)
    md.bodyA = box2d.getGroundBody();
    // Body 2 is the box's boxy
    md.bodyB = box.body;
    // Get the mouse location in world coordinates
    Vec2 mp = box2d.coordPixelsToWorld(x,y);
    // And that's the target
    md.target.set(mp);
    // Some stuff about how strong and bouncy the spring should be
    md.maxForce = 100000.0f * box.body.m_mass;
    md.frequencyHz = 500.0f;
    md.dampingRatio = 0.999f;

    mouseJoint = (MouseJoint) box2d.world.createJoint(md);
  }

  public void destroy() {
    // We can get rid of the joint when the mouse is released
    if (mouseJoint != null) {
      box2d.world.destroyJoint(mouseJoint);
      mouseJoint = null;
    }
  }

}
  public void settings() {  size(533, 800); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#030303", "--stop-color=#cccccc", "ARTLAB_FINAL" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
