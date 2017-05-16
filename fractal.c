#include <stdlib.h>
#include <iostream.h>
#include "glaux.h" //For auxiliary functions.
#include "gltk.h" //For mouse functions.
#include "/usr/pvm3/include/pvm3.h"
const int PIXELS = 600;
//Holds the size of the window
const int NPROCESS = 20; //Holds the number of PVM slaves
int NumberDone[NPROCESS]; //A record of the progress of each slave
float X1,Y1, X2,Y2;
//Define the viewing rectangle
/* A palette of colors */
float palette[17][3] = {{0.1,0.2,0.3}, {0.5,0.2,0.7}, {0.3,0.8,0.1}, {0.9,0.3,0.5},
{0.8,0.6,0.5}, {0.1,0.7,0.4}, {0.5,0.8,0.3}, {0.7,0.4,0.8},
{0.1,0.2,0.3}, {0.5,0.2,0.7}, {0.3,0.8,0.1}, {0.9,0.3,0.5},
{0.8,0.6,0.5}, {0.1,0.7,0.4}, {0.5,0.8,0.3}, {0.7,0.4,0.8},
{1.0,1.0,1.0} };
static void SetArray(float yarray[]) {
/* Initializes the arrays */
int i;
//Divides the window into areas for each slave
for (i=0;i<NPROCESS+1;i++) {
yarray[i] = Y1 + ((float)i/NPROCESS)*(Y2-Y1);
}

for (i=0;i<NPROCESS;i++)
{ NumberDone[i] = 0; }
}
static void DrawRow(int data[], int who) {
/* Draws one row using data from a slave program */
int ypos,i;
//Get the y position of the row
ypos = who*(PIXELS/NPROCESS) + NumberDone[who];
//Draw the points
for (i=0;i<PIXELS;i++) {
glColor3fv(palette[data[i]]);
glBegin(GL_POINTS);
glVertex2i(i,ypos);
glEnd();
}
glFlush();
//Increment the progress record
NumberDone[who] += 1;
}
static void DrawStuff() {
/* Broadcasts window data to PVM slaves,
Receives the appropriate colors back
And draws the Mandelbrot set
*/
int mytid,who,i,nhost,narch,msgtype,numt,nproc,
tids[NPROCESS], data[PIXELS];
float yarray[NPROCESS+1];
struct pvmhostinfo *hostp[NPROCESS];
mytid = pvm_mytid();
//Request NPROCESS slaves
if ( pvm_parent() != PvmNoParent) {
pvm_config( &nhost, &narch, hostp );
nproc = nhost;
if (nproc > NPROCESS) nproc = NPROCESS;
}

//If problems, quit the program
numt = pvm_spawn("mandslave", (char**)0,0,"",NPROCESS,tids);
if (numt < NPROCESS) {
cout << "MandMaster: PVM error\n";
for (i=0; i<numt; i++) {
pvm_kill(tids[i]);
}
pvm_exit();
exit(0);
}
SetArray(yarray);
/*Start PVM stuff*/
pvm_initsend(PvmDataDefault);
pvm_pkint(tids,NPROCESS,1); //Send task ID's
pvm_pkfloat(&X1,1,1);
pvm_pkfloat(&X2,1,1);
//Send the x positions
pvm_pkfloat(yarray,NPROCESS+1,1); //Send the y positions
pvm_mcast(tids, NPROCESS, 0);
msgtype=5;
for (i=0;i<PIXELS;i++) {
//Get an array of
pvm_recv( -1, msgtype);
//color values back,
pvm_upkint( &who, 1, 1);
pvm_upkint(data, PIXELS, 1);
DrawRow(data,who);
//Draw them on screen.
}
pvm_exit();
}
static void SmallZoom(int x,int y) {
/* Zooms in on a relatively small area of the viewing window. */
int zm = PIXELS/60;
//The size of the zoom
glColor3f(1.0,0.0,0.0);
glBegin(GL_QUADS);
glVertex2i(x-zm,(PIXELS-y)-zm); //Draw a red rectangle to indicate
glVertex2i(x-zm,(PIXELS-y)+zm); //where zooming is taking place

glVertex2i(x+zm,(PIXELS-y)+zm);
glVertex2i(x+zm,(PIXELS-y)-zm);
glEnd;
double Xsave,Xavg,Ysave,Yavg;
Xsave = X1;
Xavg = (X2 - X1);
Ysave = Y1;
Yavg = (Y2 - Y1);
X1 = Xsave+(x-zm)*((Xavg)/PIXELS); //Set new viewing rectangle
X2 = Xsave+(x+zm)*((Xavg)/PIXELS); //By converting from pixel
Y1 = Ysave+((PIXELS-y)-zm)*((Yavg)/PIXELS); //coords to real coords.
Y2 = Ysave+((PIXELS-y)+zm)*((Yavg)/PIXELS);
}
static void LargeZoom(int x,int y) {
/* Zooms in on a relatively large area of the viewing window. */
int zm = PIXELS/12;
//Size of the zoom
glColor3f(1.0,0.0,0.0);
glBegin(GL_QUADS);
glVertex2i(x-zm,(PIXELS-y)-zm); //Draw a red rectangle to indicate
glVertex2i(x-zm,(PIXELS-y)+zm); //where zooming is taking place
glVertex2i(x+zm,(PIXELS-y)+zm);
glVertex2i(x+zm,(PIXELS-y)-zm);
glEnd;
double Xsave,Xavg,Ysave,Yavg;
Xsave = X1;
Xavg = (X2 - X1);
Ysave = Y1;
Yavg = (Y2 - Y1);
X1 = Xsave+(x-zm)*((Xavg)/PIXELS); //Set new viewing rectangle
X2 = Xsave+(x+zm)*((Xavg)/PIXELS); //by converting from pixel
Y1 = Ysave+((PIXELS-y)-zm)*((Yavg)/PIXELS); //coords to real coords
Y2 = Ysave+((PIXELS-y)+zm)*((Yavg)/PIXELS);
}
static GLenum MousePressed(int x,int y, GLenum button) {

	/* This procedure manages the mouse calls */
if (button & TK_LEFTBUTTON)
{ SmallZoom(x,y); }
//Left button activates a small zoom.
if (button & TK_RIGHTBUTTON)
{ LargeZoom(x,y); }
return GL_TRUE;
//Right button activates a large zoom.
//The mouse toolkit wants a boolean return.
}
static void Restore(...) {
/* Resets the viewing window to its initial values */
/* Used to zoom back out once you have zoomed in. */
X1 = -2; //These coordinates are a good window
X2 = 0.6; //for the Mandelbrot set.
Y1 = -1.5;
Y2 = 1.5;
}
static void Init() {
/* Sets initial viewing window, and clears the screen */
X1 = -2;
Y1 = -1.5;
X2 = 0.6;
Y2 = 1.5;
glClearColor(0.0, 0.0, 0.0, 1.0);
glClear(GL_COLOR_BUFFER_BIT);
}
static void DisplayStuff(...) {
/* Calls the drawing function, then displays the result to the screen. */
DrawStuff();
glFlush();
auxSwapBuffers();
}
static void Reshape(int w, int h) {
/* Mystical Magical stuff */
glViewport(0,0,(GLint)w,(GLint)h);

glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho(0,PIXELS,0,PIXELS,-1,1);
glMatrixMode(GL_MODELVIEW);
}
int main(int argc, char **argv) {
/* Window Initialization and Main Loop */
auxInitDisplayMode(AUX_RGBA);
auxInitPosition(100,50,PIXELS,PIXELS);
if (auxInitWindow("Mandelbrot Set") == GL_FALSE)
{ auxQuit(); }
Init();
auxExposeFunc(Reshape);
auxReshapeFunc(Reshape);
auxKeyFunc(AUX_r,Restore);
tkMouseDownFunc(MousePressed);
auxMainLoop(DisplayStuff);
}