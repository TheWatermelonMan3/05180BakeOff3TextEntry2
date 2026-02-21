import java.util.Arrays;
import java.util.Collections;
import java.util.Random;

String[] phrases; //contains all of the phrases
int totalTrialNum = 2; //the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; //the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; //a running total of the number of errors (when hitting next)
String currentPhrase = ""; //the current target phrase
String currentTyped = ""; //what the user has typed so far
final int DPIofYourDeviceScreen = 250; //you will need to look up the DPI or PPI of your device to make sure you get the right scale. Or play around with this value.
final float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
final int buttonHorizontalOffset = (int) (DPIofYourDeviceScreen * 0.33);
final int wideHorizontalOffset = (int) (DPIofYourDeviceScreen * 0.50);
final int buttonVerticalOffset = (int) (DPIofYourDeviceScreen * 0.25);
final int singleButtonWidth = (int) (DPIofYourDeviceScreen * 0.28);
final int wideButtonWidth = (int) (DPIofYourDeviceScreen * 0.45);
final int singleButtonHeight = (int) (DPIofYourDeviceScreen * 0.20);
int lastClick = -1000;
int lastClickedButton = -1;

String [] nineKeys = {"abc", "def", "ghi",
                      "jkl", "mno", "pqr",
                      "stu", "vwx", "yz  "};
int [] nineKeySelect = {0, 0, 0, 1, 1, 1, 2, 2, 1};

String caratString(int n) {
  if (n == 0) return "^__";
  if (n == 1) return "_^_";
  return "__^";
}

PImage watch;
PImage finger;

class ButtonBound {
  int x = 0;
  int y = 0;
  int w = 0;
  int h = 0;
  
  ButtonBound(int x, int y, int w, int h){
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
}

ButtonBound getButtonBound(int n) {
  if (n < 12) {
    int col = n % 3;
    int row = n / 3;
    return new ButtonBound(width/2 + ((col-1)*buttonHorizontalOffset) - (singleButtonWidth/2),
                           height/2 + ((int) ((row-1.5)*buttonVerticalOffset)) - (singleButtonHeight/2),
                           singleButtonWidth,
                           singleButtonHeight);
  }
  int col = n - 9;
  int row = 3;
  return new ButtonBound(width/2 + ((int) ((col-0.5)*wideHorizontalOffset)) - (wideButtonWidth/2),
                         height/2 + ((int) ((row-1.5)*buttonVerticalOffset)) - (singleButtonHeight/2),
                         wideButtonWidth,
                         singleButtonHeight);
}

//Variables for my silly implementation. You can delete this:
char currentLetter = 'a';

//You can modify anything in here. This is just a basic implementation.
void setup()
{
  //noCursor();
  watch = loadImage("watchhand3smaller.png");
  //finger = loadImage("pngeggSmaller.png"); //not using this
  phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases), new Random()); //randomize the order of the phrases with no seed
  //Collections.shuffle(Arrays.asList(phrases), new Random(100)); //randomize the order of the phrases with seed 100; same order every time, useful for testing
 
  orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device
  size(800, 800); //Sets the size of the app. You should modify this to your device's native size. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", 20)); //set the font to arial 24. Creating fonts is expensive, so make difference sizes once in setup, not draw
  noStroke(); //my code doesn't use any strokes
}

//You can modify anything in here. This is just a basic implementation.
void draw()
{
  background(255); //clear background
  
   //check to see if the user finished. You can't change the score computation.
  if (finishTime!=0)
  {
    fill(0);
    textAlign(CENTER);
    text("Trials complete!",400,200); //output
    text("Total time taken: " + (finishTime - startTime),400,220); //output
    text("Total letters entered: " + lettersEnteredTotal,400,240); //output
    text("Total letters expected: " + lettersExpectedTotal,400,260); //output
    text("Total errors entered: " + errorsTotal,400,280); //output
    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    text("Raw WPM: " + wpm,400,300); //output
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    text("Freebie errors: " + nf(freebieErrors,1,3),400,320); //output
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    text("Penalty: " + penalty,400,340);
    text("WPM w/ penalty: " + (wpm-penalty),400,360); //yes, minus, because higher WPM is better
    return;
  }
  
  drawWatch(); //draw watch background
  fill(100);
  rect(width/2-sizeOfInputArea/2, height/2-sizeOfInputArea/2, sizeOfInputArea, sizeOfInputArea); //input area should be 1" by 1"
  

  if (startTime==0 & !mousePressed)
  {
    fill(128);
    textAlign(CENTER);
    text("Click to start time!", 280, 150); //display this messsage until the user clicks!
  }

  if (startTime==0 & mousePressed)
  {
    nextTrial(); //start the trials!
  }

  if (startTime!=0)
  {
    //feel free to change the size and position of the target/entered phrases and next button 
    textAlign(LEFT); //align the text left
    fill(128);
    text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, 70, 50); //draw the trial count
    fill(128);
    text("Target:   " + currentPhrase, 70, 100); //draw the target string
    text("Entered:  " + currentTyped +"|", 70, 140); //draw what the user has entered thus far

    //example design draw code
    for (int i = 0; i < 12; i++) {
      if (i < 9 && (lastClickedButton != i || millis() >= lastClick + 1000)) nineKeySelect[i] = 0;
      ButtonBound thisbutton = getButtonBound(i);
      if (i < 9) {
        if (lastClickedButton == i && millis() < lastClick + 1000){
          if(mousePressed && didMouseClick(thisbutton.x,thisbutton.y,thisbutton.w,thisbutton.h)) fill(155,55,0);
          else fill(255,155,0);
        } else {
          if(mousePressed && didMouseClick(thisbutton.x,thisbutton.y,thisbutton.w,thisbutton.h)) fill(155,155,0);
          else fill(255,255,0);
        }
      } else if (i == 9) {
        if(mousePressed && didMouseClick(thisbutton.x,thisbutton.y,thisbutton.w,thisbutton.h)) fill(155,0,0);
        else fill(255,0,0);
      } else if (i == 10) {
        if(mousePressed && didMouseClick(thisbutton.x,thisbutton.y,thisbutton.w,thisbutton.h)) fill(0,55,155);
        else fill(0,155,255);
      } else if (i == 11) {
        if(mousePressed && didMouseClick(thisbutton.x,thisbutton.y,thisbutton.w,thisbutton.h)) fill(0,155,0);
        else fill(0,255,0);
      }
      rect(thisbutton.x, thisbutton.y, thisbutton.w, thisbutton.h);
      textAlign(CENTER);
      fill(0);
      if (i < 9) {
        text(nineKeys[i], thisbutton.x + thisbutton.w/2, thisbutton.y + thisbutton.h/2);
        text(caratString(nineKeySelect[i]), thisbutton.x + thisbutton.w/2, thisbutton.y + thisbutton.h);
      } else if (i == 9) {
        text("DEL", thisbutton.x + thisbutton.w/2, thisbutton.y + thisbutton.h/2);
      } else if (i == 10) {
        text("space", thisbutton.x + thisbutton.w/2, thisbutton.y + thisbutton.h/2);
      } else if (i == 11) {
        text("ENTER", thisbutton.x + thisbutton.w/2, thisbutton.y + thisbutton.h/2);
      }
    }
  }
 
 
  //drawFinger(); //no longer needed as we'll be deploying to an actual touschreen device
}

//my terrible implementation you can entirely replace
boolean didMouseClick(float x, float y, float w, float h) //simple function to do hit testing
{
  return (mouseX > x && mouseX<x+w && mouseY>y && mouseY<y+h); //check to see if it is in button bounds
}

//my terrible implementation you can entirely replace
void mousePressed()
{
  for (int i = 0; i < 12; i++) {
      ButtonBound thisbutton = getButtonBound(i);
      if (didMouseClick(thisbutton.x, thisbutton.y, thisbutton.w, thisbutton.h)){
        if (i < 9) {
          if (lastClickedButton != i || millis() >= lastClick + 1000){
            currentTyped +=nineKeys[i].charAt(nineKeySelect[i]);
          } else if (currentTyped.length() > 0) {
            currentTyped = currentTyped.substring(0, currentTyped.length()-1) + nineKeys[i].charAt(nineKeySelect[i]);
          }
          if (i == 9) nineKeySelect[i] = (nineKeySelect[i] + 1) % 2;
          else nineKeySelect[i] = (nineKeySelect[i] + 1) % 3;
          lastClickedButton = i;
          lastClick = millis();
        } else if (i == 9 && currentTyped.length() > 0) {
          currentTyped = currentTyped.substring(0, currentTyped.length()-1);
        } else if (i == 10) {
          currentTyped += " ";
        } else if (i == 11) {
          nextTrial();
        }
      }
    }
}


void nextTrial()
{
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime!=0 && finishTime==0) //in the middle of trials
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    System.out.println("Target phrase: " + currentPhrase); //output
    System.out.println("Phrase length: " + currentPhrase.length()); //output
    System.out.println("User typed: " + currentTyped); //output
    System.out.println("User typed length: " + currentTyped.length()); //output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + (millis()-lastTime)); //output
    System.out.println("Time taken since beginning: " + (millis()-startTime)); //output
    System.out.println("==================");
    lettersExpectedTotal+=currentPhrase.trim().length();
    lettersEnteredTotal+=currentTyped.trim().length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (currTrialNum == totalTrialNum-1) //check to see if experiment just finished
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime)); //output
    System.out.println("Total letters entered: " + lettersEnteredTotal); //output
    System.out.println("Total letters expected: " + lettersExpectedTotal); //output
    System.out.println("Total errors entered: " + errorsTotal); //output

    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    
    System.out.println("Raw WPM: " + wpm); //output
    System.out.println("Freebie errors: " + freebieErrors); //output
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    System.out.println("==================");

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime==0) //first trial starting now
  {
    System.out.println("Trials beginning! Starting timer..."); //output we're done
    startTime = millis(); //start the timer!
  } 
  else
    currTrialNum++; //increment trial number

  lastTime = millis(); //record the time of when this trial ended
  currentTyped = ""; //clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  //currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}

//probably shouldn't touch this - should be same for all teams.
void drawWatch()
{
  float watchscale = DPIofYourDeviceScreen/138.0; //normalizes the image size
  pushMatrix();
  translate(width/2, height/2);
  scale(watchscale);
  imageMode(CENTER);
  image(watch, 0, 0);
  popMatrix();
}

//probably shouldn't touch this - should be same for all teams.
void drawFinger()
{
  float fingerscale = DPIofYourDeviceScreen/150f; //normalizes the image size
  pushMatrix();
  translate(mouseX, mouseY);
  scale(fingerscale);
  imageMode(CENTER);
  image(finger,52,341);
  if (mousePressed)
     fill(0);
  else
     fill(255);
  ellipse(0,0,5,5);

  popMatrix();
  }
  

//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}
