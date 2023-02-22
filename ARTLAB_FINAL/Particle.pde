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
  color col;
  float tx, ty;

  Particle(float x, float y, float r_, color c_) {
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

  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    pushMatrix();
    translate(pos.x, pos.y);
    fill(r, g, b);
    noStroke();      
    ellipse(0, 0, rad*2, rad*2);

    popMatrix();
  }

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
