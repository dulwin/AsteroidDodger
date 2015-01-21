import android.view.WindowManager;     // keep screen on
import android.os.Bundle;
void onCreate( Bundle bundle ) {
    super.onCreate( bundle );
    getWindow( ).addFlags( WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON );
}

import android.view.MotionEvent;
String touchAction;                    // UP, DOWN, MOVE based on touch
float touchX;                          // x location of touch 
float touchY;                          // y location of touch

import android.content.Context;        // required imports for sensor data
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

SensorManager sensorManager;          // keep track of sensor
SensorListener sensorListener;        // special class for noting sensor changes
Sensor accelerometer;                 // Sensor object for accelerometer
float[] accelData;                    // x,y,z sensor data

SplashScreen splash;
StatsBar stats;
PauseScreen pause;
Ship ship;
GameOver gameOver;
ArrayList<Asteroid> asteroids;        // array of asteriods - size of array
                                      // varies based on level
ArrayList<Point> spawnPoints;         // array of points for asteroids to spawn
                                      // - size varies based on level
float maxSize;                        // maximum size of an asteroid based on
                                      // level
String gameState;                     // state of game - PAUSE, SPLASH,
                                      // GAMEPLAY, HIGHSCORES, INSTRUCTIONS
int level;

void setup( ) {
    splash = new SplashScreen( );
    stats = new StatsBar( );
    pause = new PauseScreen( );
    gameOver = new GameOver( );
    smooth( );

    touchAction = "";
    orientation( PORTRAIT );
    sensorManager = ( SensorManager )getSystemService( Context.SENSOR_SERVICE );
    sensorListener = new SensorListener( );
    accelerometer = sensorManager.getDefaultSensor( Sensor.TYPE_ACCELEROMETER );
    sensorManager.registerListener( sensorListener, accelerometer, SensorManager.SENSOR_DELAY_GAME );

    // the ship is 1/8 the width of the screen
    ship = new Ship( width/8 );

    gameState = "SPLASH";

    spawnPoints = new ArrayList<Point>( );
    asteroids = new ArrayList<Asteroid>( );
    gridMaker( 12 );
    for ( int i = 0; i < 12; i ++ ) {
        Asteroid ast = new Asteroid( random( maxSize/3, maxSize/1.5 ), random( 0, 2 ) );
        Point tempPoint = spawnPoints.get( i );
        ast.location = new PVector( tempPoint.x, tempPoint.y );
        asteroids.add( ast );
    }
}

void draw( ) {
    background( 0, 64, 128 );
    if ( gameState == "GAMEPLAY" ) {
        println( ship.health + ", " + stats.health.factor );
        
        /****************COLLISIONS****************/
        shipWallCollision( );
        asteroidWallCollision( );
        asteroidAsteroidCollision( );
        asteroidShipCollision( );

        /******************MOVING******************/
        if (ship.collision == false) {
            touchEvent( );
        }
        tiltEvent( );

        moveAsteroids( );
        moveShip( );

        /*****************DRAWING*****************/
        drawShip( );
        drawAsteroids( );
        stats.draw( );
    }
    else if ( gameState == "PAUSE" ) {
        drawShip( );
        drawAsteroids( );

        pause.draw( );
    }
    else if ( gameState == "SPLASH" ) {
        asteroidWallCollision( );
        asteroidAsteroidCollision( );
        moveAsteroids( );

        drawAsteroids( );
        splash.draw( );
    }
    else if ( gameState == "GAMEOVER" ) {
        drawAsteroids( );
        gameOver.draw( );
    }
}

/************************GAMEPLAY***********************************/

void levelChange( ) {
    int astNum;
    level ++;
    spawnPoints.clear( );
    asteroids.clear( );
    if ( level % 7 == 0 ) ship.health = 200;
    if ( level > 1 ) astNum = level * 2;
    else astNum = 1;
    gridMaker( astNum );

    println( "///////////LEVEL: " + level + " //////////" );

    for ( int i = 0; i < astNum; i++ ) {
        Asteroid ast = new Asteroid( random( maxSize/3, maxSize/1.5 ), random( 0, 2 ) );
        Point tempPoint = spawnPoints.get( i );
        ast.location = new PVector( tempPoint.x, tempPoint.y );
        asteroids.add( ast );
    }

    ship.theta = 0;
    ship.velocity =new PVector( 0, -1 );
    ship.location = new PVector( width/2, height );
}

/***************************SHIP*************************************/

void moveShip( ) {
    ship.theta += ship.rotSpeed;          // rotate the ship
    ship.location.add(ship.velocity);     // move the ship based on its velocity
}

void drawShip( ) {
    pushMatrix( );
    translate( ship.location.x, ship.location.y );
    rotate( ship.theta );
    ship.draw( );
    popMatrix( );
}

void touchEvent( ) {
    // if the screen is touched
    if ( touchAction == "MOVE" || touchAction == "DOWN" &&  touchY > height/1.25 ) {
        // turn thrust on
        ship.thrustVis = true;
        
        // when thrust is on make the ship faster
        ship.velocity.x = sin( ship.theta ) * 4;
        ship.velocity.y = -cos(ship.theta) * 4;
    }
    else if (touchAction == null || touchAction == "UP" && ship.collision == false) {
        ship.thrustVis = false;
        ship.velocity.x = sin( ship.theta ) * 2;
        ship.velocity.y = -cos( ship.theta ) * 2;
    }
}

void tiltEvent( ) {
    if ( accelData != null ) {
        if ( accelData[0] < -1.5 || accelData[0] > 1.5 ) {
            // tilted to the right past a certain degree 
            // rotate ship to the right
            ship.rotSpeed = ( ( accelData[0] - 0.5 )/100 ) * -1;
        } 
        else {
            // if the ship is near flat
            // don't rotate the ship
            ship.rotSpeed = 0;
        }
    }

    if ( ship.theta > TWO_PI || ship.theta < -TWO_PI ) {
        // limit the angle of the ship between 0 & 360
        // if it exceeds that limit return it back to 0
        ship.theta = 0;
    }
}

void shipWallCollision( ) {
    if ( ship.location.x - ship.size/2 < 0 ) {
        // if the ship is off the left side of the screen
        // return it back on to the screen and make xSpeed = 0
        ship.location.x = 0 + ship.size/2;
        ship.velocity.x *= -1;
    }
    else if ( ship.location.x + ship.size/2 > width ) {    
        // if off right side of screen
        // return and xSpeed = 0
        ship.location.x = width - ship.size/2;
        ship.velocity.x *= -1;
    }

    if (ship.location.y < 0 + stats.h) {
        // if the ship reaches the top of the screen
        // the level is complete
        ship.velocity.y *= 5;
        ship.velocity.x *= 5;
        levelChange( );
    }
    else if ( ship.location.y > height ) {
        // if the ship is off the bottom of the screen
        // let it go half off and make the ySpeed = 0
        ship.location.y = ship.location.y - ( ship.location.y - height );
        ship.velocity.y *= -1;
    }
}

/*****************************ASTEROID***************************************/

void moveAsteroids( ) {
    for ( int i = 0 ; i < asteroids.size( ); i++ ) {
        Asteroid ast = asteroids.get( i );
        ast.location.add( ast.velocity );
        ast.theta += ast.rotSpeed;
    }
}

void drawAsteroids( ) {
    for ( int i = 0 ; i < asteroids.size( ); i++ ) {
        Asteroid ast = asteroids.get( i );
        pushMatrix( );
        translate( ast.location.x, ast.location.y );
        rotate( ast.theta );
        ast.draw( );
        popMatrix( );
    }
}

void asteroidWallCollision( ) {
    for ( int i = 0 ; i < asteroids.size(); i++ ) {
        Asteroid ast = asteroids.get( i );
        if ( ast.location.x >= width - ast.radius ) {
            // checks if the asteroid has left the screen from the right,
            // if so returns to the left
            ast.location.x = width- ast.radius;
            ast.velocity.x *= -1;
        }
        else if ( ast.location.x <= 0 + ast.radius ) {
            // checks if the asteroid has left the screen from the left,
            // if so returns to the right
            ast.location.x = 0 +  ast.radius;
            ast.velocity.x *= -1;
        }

        if ( ast.location.y  >= height - ast.radius ) {
            // checks if the asteroid has hit the bottom,
            // inverse the speed
            ast.location.y = height - ast.radius;
            ast.velocity.y *= -1;
        }
        else if ( ast.location.y  <= 0 + ast.radius + stats.h ) {
            // checks if the asteroid has hit the top,
            // inverse the speed
            ast.location.y = 0 + ast.radius + stats.h;
            ast.velocity.y *= -1;
        }
    }
}

void asteroidAsteroidCollision( ) {
    // for every asteroid
    for ( int i = 0; i < asteroids.size( ); i++ ) {
        for ( int j = 0; j < asteroids.size( ); j++ ) {
            // compare it to every other asteroid
            if ( i != j ) {
                Asteroid ast1 = asteroids.get( i );
                Asteroid ast2 = asteroids.get( j );

                ast1.checkCollision( ast2 );
            }
        }
    }
}

/****************************ASTEROID SHIP************************/

void asteroidShipCollision( ) {
    for ( int i = 0; i < asteroids.size( ); i++ ) {
        Asteroid ast = asteroids.get( i );
        ship.checkCollision( ast );
    }
}

/************************MISC********************************/

float gridMaker( int numOfAst ) {
    // divides screen up into equal square grids ensuring asteroids cannot
    // start on top of each other and maximizes size of asteroid based on
    // asteroids being displayed on screen

    int counter = 0;

    float x = width, y = height - stats.h, n = numOfAst;

    // maximum squares that can be fit on the x-axis
    float partsX = ceil( sqrt( n * x / y ) );
    float sizeX, sizeY;

    if ( floor( partsX * y / x ) * partsX < n )
        sizeX =y / ceil( partsX * y / x );
    else
        sizeX= x / partsX;
    float partsY = ceil( sqrt( n * y / x ) );

    if ( floor( partsY * x / y ) * partsY < n )
        sizeY = x / ceil( x * partsY / y );
    else
        sizeY = y / partsY;
    maxSize = max( sizeX, sizeY );

    for ( int i = 0; i < partsY; i++ ) {
        for ( int j = 0; j < partsX; j++ ) {
            if ( n != 2 ) {
                float a = 0 + ( j * maxSize ) + ( maxSize / 2 );
                float b = 0 + ( i * maxSize ) + ( maxSize / 2 ) + stats.h;
                spawnPoints.add( new Point( a, b ) );

                counter++;
            }
            else {
                float a = 0 + ( i * maxSize ) + ( maxSize / 2 );
                float b = 0 + ( j * maxSize ) + ( maxSize / 2 ) + stats.h;
                spawnPoints.add( new Point( a, b ) );

                counter++;
            }

            if ( counter == n )
                break;
        }
        if ( counter == n )
            break;
    }

    return maxSize;
}

/*********************CLASSES*************************/

class SplashScreen {
    Button play, ins, high;

    SplashScreen( ) {
        play = new Button( width/2, height/2, width/1.8, height/18, color( 143, 0, 90 ), color( 93, 0, 58 ), "PLAY" );
        ins = new Button( width/2, height/2 + height/9, width/1.8, height/18, color( 0, 134, 45 ), color( 0, 87, 30 ), "INSTRUCTIONS" );
        high = new Button( width/2, height/2 + ( 2 * height/9 ), width/1.8, height/18, color( 183, 139, 0 ), color( 119, 91, 0 ), "HIGH SCORES" );
    }

    void draw( ) {
        fill( 255 );
        textAlign( CENTER );
        textSize( 100 );
        text( "Asteroid", width/2, height/4 );
        text( "Dodger", width/2, height/3 );

        // PLAY
        play.display( );
        if ( play.touch( ) ) {   
            background( 0 );
            levelChange( );
            gameState = "GAMEPLAY";
        }

        ins.touch( );
        ins.display( );

        high.touch( );
        high.display( );
    }
}

class StatsBar {
    Indicator health;
    Indicator fuel;
    Button pause;
    float x, y, w, h;

    StatsBar( ) {
        health = new Indicator( width/2.5, height/40, width/5, width/15, "Health", color( 0, 195, 34 ), 1 );
        fuel = new Indicator( width/1.5, height/40, width/5, width/15, "Fuel", color( 62, 202, 232 ), 1 );
        pause = new Button( width/1.1, height/50, width/15, width/15, color( 0, 158, 142 ), color( 0, 103, 92 ), "||" );
        x = 0;
        y = 0;
        w = width;
        h = height/20;
    }

    void draw( ) {
        rectMode( CORNER );
        noStroke( );
        fill( 0, 100 );
        rect( x, y, w, h );
        fill( 255 );
        textAlign( CORNER );
        textSize( w/20 );
        text( "Level: " + level, w/30, h/1.33 );

        pause.display( );
        if ( pause.touch( ) )
            gameState = "PAUSE";

        health.display( );

        fuel.display( );
    }
}

class Indicator {
    float x, y, w, h, factor;
    String text;
    color clr;

    Indicator ( float a, float b, float c, float d, String t, color cr, float f ) {
        x = a;
        y = b;
        w = c;
        h = d;
        text = t;
        clr = cr;
        factor = f;
    }

    void display( ) {

        noFill( );
        stroke( 255, 160 );
        rectMode( CORNER );
        strokeWeight( 2 );
        rect ( x-w/2, y-h/2, w, h );

        fill( clr, 175 );
        noStroke( );
        rect( x-w/2 + 2.5, y-h/2 + 2.5, ( w * factor ) - 5, h - 5 );
        fill( 255 );
        textAlign( CENTER );
        text ( text, x, y + ( h/4 ) );
    }
}

class GameOver {
    Button home, high, restart;

    GameOver( ) {
        home =  new Button ( width/2, height/1.5, width/1.8, height/18, color( 219, 0, 88 ), color( 142, 0, 57 ), "HOME" );
        restart = new Button ( width/2, height/1.5 + ( height/9 ), width/1.8, height/18, color( 117, 9, 170 ), color( 95, 37, 128 ), "RESTART" );
        high = new Button ( width/2, height/1.5 + ( 2 * height/9 ), width/1.8, height/18, color( 183, 139, 0 ), color( 119, 91, 0 ), "HIGH SCORES" );
    }

    void draw( ) {
        fill( 0, 50 );
        rectMode( CORNER );
        rect( 0, 0, width, height );

        fill( 255 );
        textAlign( CENTER );
        textSize( width/7.2 );
        text( "Game Over", width/2, height/4 );
        textSize( width/14.4 );
        text( "Level: " + level, width/2, height/4 + ( width/7.2 ) );
        text( "Score: ", width/2, height/4 + ( 2 * width/7.2 ) );

        home.display( );
        if ( home.touch( ) ) {
            spawnPoints.clear( );
            asteroids.clear( );
            gridMaker( 12 );
            for ( int i = 0; i < 12; i++ ) {
                Asteroid ast = new Asteroid( random( maxSize/3, maxSize/1.5 ), random( 0, 2 ) );
                Point tempPoint = spawnPoints.get( i );
                ast.location = new PVector( tempPoint.x, tempPoint.y );
                asteroids.add( ast );
            }
            level = 0;
            ship.health = 200;
            gameState = "SPLASH";
        }

        restart.display( );
        restart.touch( );

        high.display( );
        high.touch( );
    }
}

class PauseScreen {
    Button unpause, quit;

    PauseScreen( ) {
        unpause = new Button ( width/2, height/2, width/1.8, height/18, color( 0, 164, 128 ), color( 0, 107, 83 ), "RESUME" );
        quit  = new Button( width/2, height/2 + height/9, width/1.8, height/18, color( 139, 66, 214 ), color( 92, 13, 172 ), "QUIT" );
    }

    void draw( ) {
        fill( 0, 50 );
        rectMode( CORNER );
        rect( 0, 0, width, height );

        fill( 255 );
        textAlign( CENTER );
        textSize( 100 );
        text( "Paused", width/2, height/4 );

        unpause.display( );
        if ( unpause.touch( ) )
            gameState = "GAMEPLAY";

        quit.display( );
        if ( quit.touch( ) ) {
            spawnPoints.clear( );
            asteroids.clear( );
            gridMaker( 12 );
            for ( int i = 0; i < 12; i++ ) {
                Asteroid ast = new Asteroid( random( maxSize/3, maxSize/1.5 ), random( 0, 2 ) );
                Point tempPoint = spawnPoints.get( i );
                ast.location = new PVector( tempPoint.x, tempPoint.y );
                asteroids.add( ast );
            }
            ship.health = 200;
            gameState = "SPLASH";
            level = 0;
        }
    }
}

class Button {
    float x, y, w, h, y2;
    color clr, shadClr;
    String text;

    Button ( float a, float b, float c, float d, color clr1, color clr2, String str ) {
        x = a;
        y = b;
        w = c;
        h = d;
        clr = clr1;
        shadClr = clr2;
        text = str;
        y2 = y + ( h / 4 );
    }

    void display( ) {
        rectMode( CENTER );
        noStroke( );
        fill( shadClr );
        rect( x, y2, w, h, 50 );
        fill( clr );
        rect( x, y, w, h, 50 );
        fill( 255 );
        textAlign( CENTER );
        textSize( h/1.5 );
        text( text, x, y + ( h / 4 ) );
    }

    boolean touch( ) {
        if ( touchAction == "DOWN" ) {
            if ( touchX >= x - w/2 && touchX <= x + w/2 && touchY >= y - h/2 && touchY <= y + h/2 ) {
                y = y2;
            }
        }
        else if ( touchAction == "UP" ) {
            y = y2 - ( h / 4 );

            if ( touchX >= x - w/2 && touchX <= x + w/2 && touchY >= y - h/2 && touchY <= y + h/2 ) {
                return true;
            }
        }
        return false;
    }
}

class Ship {
    float size;
    color clr;
    boolean thrustVis, collision;
    PVector location;
    PVector velocity;
    float theta;
    float rotSpeed;
    float mass;
    float health;

    Ship( float s ) {
        size = s;
        clr = color(4, 200, 255);
        thrustVis = false;
        location = new PVector( width/2, height );
        velocity = new PVector( 0, -1 );
        theta = 0;
        rotSpeed = 0;
        mass = ( PI * pow( size/2, 2 ) ) / 1.6;
        collision = false;
        health = 200;
    }

    void draw( ) {
        display( );
    }

    void display( ) {
        // start with ship at origin
        translate(0 - size/2, 0-size/2);

        stroke( 125, 249, 255, 150 );
        fill( 125, 249, 255, 20 );
        ellipseMode( CENTER );
        ellipse( size/2, size/2, size, size );

        pushMatrix( );
        translate( 0, 0 - size/6 );
        beginShape( );
        fill( 84 );
        noStroke( );
        
        // right body
        vertex( size/2, size/5.5 );
        bezierVertex( size/1.5, size/4.0, size/1.5, size/2.75, size/1.45, size/1.83 );
        
        // right wing
        vertex( size/1.45, size/1.83 );
        bezierVertex( size/1.45, size/1.5, size/1.2, size/1.38, size/1.1, size/1.22 );
        vertex( size/1.1, size/1.22 );
        
        // tail
        vertex( size/1.1, size/1.07 );
        bezierVertex( size/1.57, size, size/2.75, size, size/8.6, size/1.07 );
        vertex( size/8.8, size/1.07 );
        
        // left wing
        vertex( size/8.8, size/1.22 );
        bezierVertex( size/5.5, size/1.38, size/3.23, size/1.5, size/3.14, size/1.83 );
        
        // left body
        vertex( size/3.14, size/1.83 );
        bezierVertex( size/2.9, size/2.75, size/2.9, size/4.0, size/2, size/5.5 );
        vertex( size/2, size/5.5 );
        endShape( );

        stroke( 0, 125 );
        noFill( );
        strokeWeight( 2 );
        
        // ship engine outline left
        beginShape( );
        vertex( size/2.75, size/1.5 );
        bezierVertex( size/2.32, size/1.3, size/2.32, size/1.1, size/2.31, size/1.07 ); 
        vertex( size/2.32, size/1.07 );
        endShape( );
        
        // ship engine outline right
        beginShape( );
        vertex( size/1.57, size/1.5 );
        bezierVertex( size/1.78, size/1.3, size/1.78, size/1.1, size/1.77, size/1.07 );
        vertex( size/1.77, size/1.07 );
        endShape( );
        
        // ship engine hole
        fill( 0 );
        noStroke( );
        ellipseMode( CENTER );
        ellipse( size/2, size/1.06, size/7, size/12 );

        // window
        fill( 0, 104, 139 );
        noStroke( );
        beginShape( );
        line( size/2.6, size/2.2, size/1.6, size/2.2 );
        bezier( size/2.6, size/2.2, size/2.6, size/6, size/1.6, size/6, size/1.6, size/2.2 );
        endShape( );

        // thrust only displayed if the mouse is pressed
        if ( thrustVis == true ) {
            beginShape( );
            rectMode( CENTER );
            noStroke( );
            for ( float i = 0; i < 30; i++ ) {
                if ( i < 30 )
                    fill(clr, 120 - (i*4));
                    
                rect(size/2, size/1.06+i, size/8, 1);
            }
            endShape( );
        }
        popMatrix( );
    }

    void checkCollision( Asteroid other ) {
        // get distances between the balls components
        PVector bVect = PVector.sub(other.location, location);

        // calculate magnitude of the vector separating the balls
        float bVectMag = bVect.mag( );

        if ( bVectMag < size/2 + other.radius )  {
            collision = true;
            thrustVis = false;
            touchAction = "UP";

            //calculate health deduction
            health -= (other.mass/mass) * sqrt(level);

            // get angle of bVect
            float theta  = bVect.heading();
            // precalculate trig values
            float sine = sin(theta);
            float cosine = cos(theta);

            /* bTemp will hold rotated ball positions. You 
            just need to worry about bTemp[1] position*/
            PVector[ ] bTemp = {
                new PVector( ), new PVector( )
            };

            /* this ball's position is relative to the other
            so you can use the vector between them (bVect) as the 
            reference point in the rotation expressions.
            bTemp[0].position.x and bTemp[0].position.y will initialize
            automatically to 0.0, which is what you want
            since b[1] will rotate around b[0] */
            bTemp[1].x  = cosine * bVect.x + sine * bVect.y;
            bTemp[1].y  = cosine * bVect.y - sine * bVect.x;

            // rotate Temporary velocities
            PVector[ ] vTemp = {
                new PVector( ), new PVector( )
            };

            vTemp[0].x  = cosine * velocity.x + sine * velocity.y;
            vTemp[0].y  = cosine * velocity.y - sine * velocity.x;
            vTemp[1].x  = cosine * other.velocity.x + sine * other.velocity.y;
            vTemp[1].y  = cosine * other.velocity.y - sine * other.velocity.x;

            /* Now that velocities are rotated, you can use 1D
            conservation of momentum equations to calculate 
            the final velocity along the x-axis. */
            PVector[ ] vFinal = {  
                new PVector( ), new PVector( )
            };

            // final rotated velocity for b[0]
            vFinal[0].x = ((mass - other.mass) * vTemp[0].x + 2 * other.mass * vTemp[1].x) / (mass + other.mass);
            vFinal[0].y = vTemp[0].y;

            // final rotated velocity for b[0]
            vFinal[1].x = ((other.mass - mass) * vTemp[1].x + 2 * mass * vTemp[0].x) / (mass + other.mass);
            vFinal[1].y = vTemp[1].y;

            // hack to avoid clumping
            bTemp[0].x += vFinal[0].x;
            bTemp[1].x += vFinal[1].x;

            /* Rotate ball positions and velocities back
            Reverse signs in trig expressions to rotate 
            in the opposite direction */
            // rotate balls
            PVector[ ] bFinal = { 
                new PVector( ), new PVector( )
            };

            bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
            bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
            bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
            bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;

            // update balls to screen position
            other.location.x = location.x + bFinal[1].x;
            other.location.y = location.y + bFinal[1].y;

            location.add(bFinal[0]);

            // update velocities
            velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
            velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
            other.velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
            other.velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;

            stats.health.factor = health/200;

            if ( stats.health.factor <= 0.02 ) {
                stats.health.factor = 0;
                health = 0;
                gameState = "GAMEOVER";
            }
        }
        else if ( collision == true && touchAction == "DOWN" ) {
            collision = false;
        }
    }
}

class Asteroid {
    float astNum, astSize, theta, radius, mass, rotSpeed;
    color clr;
    PVector location;
    PVector velocity;

    Asteroid ( float aS, float aN ) {
        astSize = aS;
        astNum = aN;
        clr = color(205, 133, 63);
        
        // random velocity
        velocity = new PVector(random(-1, 1), random(-1, 1));
        
        //random starting orientation
        theta = random(TWO_PI);
        
        radius = astSize/2;
        mass = PI * pow(radius, 2);
        rotSpeed = random(-0.01, 0.01);
    }

    void checkCollision( Asteroid other ) {
        // get distances between the balls components
        PVector bVect = PVector.sub( other.location, location );

        // calculate magnitude of the vector separating the balls
        float bVectMag = bVect.mag( );

        if ( bVectMag < radius-5 + other.radius-5 ) {
            // get angle of bVect
            float theta  = bVect.heading( );
            // precalculate trig values
            float sine = sin( theta );
            float cosine = cos( theta );

            /* bTemp will hold rotated ball positions. You 
            just need to worry about bTemp[1] position*/
            PVector[ ] bTemp = {
                new PVector( ), new PVector( )
            };

            /* this ball's position is relative to the other
            so you can use the vector between them (bVect) as the 
            reference point in the rotation expressions.
            bTemp[0].position.x and bTemp[0].position.y will initialize
            automatically to 0.0, which is what you want
            since b[1] will rotate around b[0] */
            bTemp[1].x  = cosine * bVect.x + sine * bVect.y;
            bTemp[1].y  = cosine * bVect.y - sine * bVect.x;

            // rotate Temporary velocities
            PVector[ ] vTemp = {
                new PVector( ), new PVector( )
            };

            vTemp[0].x  = cosine * velocity.x + sine * velocity.y;
            vTemp[0].y  = cosine * velocity.y - sine * velocity.x;
            vTemp[1].x  = cosine * other.velocity.x + sine * other.velocity.y;
            vTemp[1].y  = cosine * other.velocity.y - sine * other.velocity.x;

            /* Now that velocities are rotated, you can use 1D
            conservation of momentum equations to calculate 
            the final velocity along the x-axis. */
            PVector[] vFinal = {  
                new PVector(), new PVector()
            };

            // final rotated velocity for b[0]
            vFinal[0].x = ((mass - other.mass) * vTemp[0].x + 2 * other.mass * vTemp[1].x) / (mass + other.mass);
            vFinal[0].y = vTemp[0].y;

            // final rotated velocity for b[0]
            vFinal[1].x = ((other.mass - mass) * vTemp[1].x + 2 * mass * vTemp[0].x) / (mass + other.mass);
            vFinal[1].y = vTemp[1].y;

            // hack to avoid clumping
            bTemp[0].x += vFinal[0].x;
            bTemp[1].x += vFinal[1].x;

            /* Rotate ball positions and velocities back
            Reverse signs in trig expressions to rotate 
            in the opposite direction */
            // rotate balls
            PVector[] bFinal = { 
                new PVector(), new PVector()
            };

            bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
            bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
            bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
            bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;

            // update balls to screen position
            other.location.x = location.x + bFinal[1].x;
            other.location.y = location.y + bFinal[1].y;

            location.add(bFinal[0]);

            // update velocities
            velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
            velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
            other.velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
            other.velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;
        }
    }

    void draw( ) {
        display( );
    }

    void display( ) {

        noStroke( );
        fill( clr );

        if ( astNum <= 1 ) {
            // asteroid shape number 1
            
            // translate to 0,0 so that when rotating it rotates 
            // around that point
            translate( 0 - astSize/2, 0 - astSize/2 );
            beginShape( );                                                                                         
            vertex( astSize/2, 0 );
            bezierVertex( astSize/1.4, astSize/20, astSize/1.67, astSize/25, astSize/1.43, astSize/10 );
            vertex( astSize/1.43, astSize/10 );
            bezierVertex( astSize/1.43, astSize/10, astSize/1.25, astSize/8, astSize/1.11, astSize/3.33 );
            vertex( astSize/1.11, astSize/3.33 );
            bezierVertex( astSize, astSize/2.85, astSize, astSize/2.35, astSize, astSize/2 );
            vertex( astSize, astSize/2 );
            bezierVertex( astSize, astSize/1.67, astSize/1.18, astSize/1.33, astSize/1.25, astSize/1.18 );
            vertex( astSize/1.25, astSize/1.18 );
            bezierVertex( astSize/1.4, astSize/1.05, astSize/1.67, astSize/1.11, astSize/2, astSize );
            vertex( astSize/2, astSize );
            bezierVertex( astSize/2, astSize, astSize/4, astSize, astSize/6.67, astSize/1.43 );
            vertex( astSize/6.67, astSize/1.43 );
            vertex( 0, astSize/2 );
            bezierVertex( 0, astSize/2, astSize/25, astSize/10, astSize/3.33, astSize/10 );
            vertex( astSize/3.33, astSize/10 );
            vertex( astSize/2, 0 );
            endShape( );
        }
        else {
            translate( 0 - ( astSize/2 ), 0 - ( astSize/2 ) );
            beginShape( );
            vertex( astSize/2, 0 );
            bezierVertex( astSize/2, 0, astSize/1.43, 0, astSize/1.25, astSize/10 );
            vertex( astSize/1.25, astSize/10 );
            bezierVertex( astSize/1.25, astSize/10, astSize/1.05, astSize/3.33, astSize/1.11, astSize/2.5 );
            vertex( astSize/1.11, astSize/2.5 );
            vertex( astSize, astSize/2 );
            bezierVertex( astSize/1.11, astSize/1.67, astSize/1.11, astSize/1.25, astSize/1.25, astSize/1.11 );
            vertex( astSize/1.25, astSize/1.11 );
            bezierVertex( astSize/1.25, astSize/1.11, astSize/1.43, astSize, astSize/2, astSize );
            vertex( astSize/2, astSize );
            vertex( astSize/5, astSize/1.25 );
            bezierVertex( astSize/5, astSize/1.25, 0, astSize/1.43, 0, astSize/2 );
            vertex( 0, astSize/2 );
            bezierVertex( 0, astSize/2, 0, astSize/2.5, astSize/10, astSize/3.33 );
            vertex( astSize/10, astSize/3.33 );
            bezierVertex( astSize/10, astSize/3.33, astSize/5, astSize/5, astSize/3.33, astSize/5 );
            vertex( astSize/3.33, astSize/5 );
            vertex( astSize/2, 0 );
            endShape( );
        }
    }
}

class Point {
    float x;
    float y;

    Point ( float a, float b ) {
        x = a;
        y = b;
    }
}

/****************************ANDROID SENSOR AND TOUCH **********************/

class SensorListener implements SensorEventListener {
    void onSensorChanged( SensorEvent event )  {
        if ( event.sensor.getType( ) == Sensor.TYPE_ACCELEROMETER ) {
            accelData = event.values;
        }
    }
    
    void onAccuracyChanged( Sensor sensor, int accuracy ) {
        // required for code to work
    }
}

//overrides the built-in method, then sends the data on after we capture it
@Override
public boolean dispatchTouchEvent( MotionEvent event ) {
    // get the x,y coordinates of the touch
    touchX = event.getX( );
    touchY = event.getY( );

    // get action code (up, down, move ...)
    int action = event.getActionMasked( );

    if ( action == MotionEvent.ACTION_DOWN ) {
        touchAction = "DOWN";
    }
    else if ( action == MotionEvent.ACTION_UP ) {
        touchAction = "UP";
    }
    else if ( action == MotionEvent.ACTION_MOVE ) {
        touchAction = "MOVE";
    }
    else {
        touchAction = "OTHER CODE (" + action + ") at " + 
                        touchX + ", " + touchY;
    }
    
     // pass data along when done!
    return super.dispatchTouchEvent(event);
}