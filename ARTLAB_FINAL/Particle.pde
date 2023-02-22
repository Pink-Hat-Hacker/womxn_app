// The Nature of Code
// <http://www.shiffman.net/teaching/nature>
// Spring 2010
// Box2DProcessing example

// A circular particle

class Particle {

  int r, g, b;

  // We need to keep track of a Body and a radius
  Body body;

  float rad;

  color col;

  float tx, ty;

  Particle(float x, float y, float r_, color c_) {
    tx = x;
    ty = y;

    rad = r_;
    // This function puts the particle in the Box2d world
    makeBody(x, y, rad);
    body.setUserData(this);

    // Using "right shift" as a faster technique than red(), green(), and blue()
    col = c_;
    r = (col >> 16) & 0xFF;  // Faster way of getting red(argb)
    g = (col >> 8) & 0xFF;   // Faster way of getting green(argb)
    b = col & 0xFF;          // Faster way of getting blue(argb)
  }

  // This function removes the particle from the box2d world
  void killBody() {
    box2d.destroyBody(body);
  }


  boolean origin() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    if (pos.x >= tx - rad*.9 && pos.x <= + rad*.9 && pos.y >= ty - rad*.9 &&  pos.y <= ty + rad*.9)  return true;
    else  return false;
  }
  
  void updateColor(color c) {
    r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
    g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
    b = c & 0xFF;          // Faster way of getting blue(argb)  }
  }
  
  void attract() {
    //Vec2 pos = box2d.getBodyPixelCoord(body);

    //if (pos.x <= tx - rad*.9 && pos.x >= tx + rad*.9 && pos.y <= ty - rad*.9 &&  pos.y >= ty + rad*.9) { 
    //println("made it to attract");
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
    // }
  }

  // 
  void display() {
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    pushMatrix();
    translate(pos.x, pos.y);
    fill(r, g, b);
    //stroke(0);
    //strokeWeight(1);
    //ellipse(0, 0, r*2, r*2);

    //color c = img.get(x, y); 
    //fill(c);   
    noStroke();      
    ellipse(0, 0, rad*2, rad*2);

    popMatrix();
  }

  // Here's our function that adds the particle to the Box2D world
  void makeBody(float x, float y, float rad) {
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
    fd.friction = 0.1;
    fd.restitution = 0.01;

    //Attach fixture to body
    body.createFixture(fd);
    body.setLinearVelocity(new Vec2(0, 0));
  }
}
