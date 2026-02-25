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
final int firstHorizontalOffset = (int) (DPIofYourDeviceScreen * 0.1);
final int secondHorizontalOffset = (int) (DPIofYourDeviceScreen * 0.111);
final int thirdHorizontalOffset = (int) (DPIofYourDeviceScreen * 0.143);
final int wideHorizontalOffset = (int) (DPIofYourDeviceScreen * 0.33);
final int buttonVerticalOffset = (int) (DPIofYourDeviceScreen * 0.25);
final int firstButtonWidth = (int) (DPIofYourDeviceScreen * 0.08);
final int secondButtonWidth = (int) (DPIofYourDeviceScreen * 0.091);
final int thirdButtonWidth = (int) (DPIofYourDeviceScreen * 0.123);
final int wideButtonWidth = (int) (DPIofYourDeviceScreen * 0.28);
final int singleButtonHeight = (int) (DPIofYourDeviceScreen * 0.20);
int lastClick = -1000;
int lastClickedButton = -1;

String [] alphabet = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"};

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
  if (n < 10) {
    int col = n;
    int row = 0;
    return new ButtonBound(width/2 + (int) ((col-4.5)*firstHorizontalOffset) - (firstButtonWidth/2),
                           height/2 + ((int) ((row-1.5)*buttonVerticalOffset)) - (singleButtonHeight/2),
                           firstButtonWidth,
                           singleButtonHeight);
  } else if (n < 19) {
    int col = n - 10;
    int row = 1;
    return new ButtonBound(width/2 + (int) ((col-4)*secondHorizontalOffset) - (secondButtonWidth/2),
                           height/2 + ((int) ((row-1.5)*buttonVerticalOffset)) - (singleButtonHeight/2),
                           secondButtonWidth,
                           singleButtonHeight);
  } else if (n < 26) {
    int col = n - 19;
    int row = 2;
    return new ButtonBound(width/2 + (int) ((col-3)*thirdHorizontalOffset) - (thirdButtonWidth/2),
                           height/2 + ((int) ((row-1.5)*buttonVerticalOffset)) - (singleButtonHeight/2),
                           thirdButtonWidth,
                           singleButtonHeight);
  }
  int col = n - 26;
  int row = 3;
  return new ButtonBound(width/2 + ((int) ((col-1)*wideHorizontalOffset)) - (wideButtonWidth/2),
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
  background(255);
  
  if (finishTime!=0)
  {
    fill(0);
    textAlign(CENTER);
    text("Trials complete!",400,200);
    text("Total time taken: " + (finishTime - startTime),400,220);
    text("Total letters entered: " + lettersEnteredTotal,400,240);
    text("Total letters expected: " + lettersExpectedTotal,400,260);
    text("Total errors entered: " + errorsTotal,400,280);
    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f);
    text("Raw WPM: " + wpm,400,300);
    float freebieErrors = lettersExpectedTotal*.05;
    text("Freebie errors: " + nf(freebieErrors,1,3),400,320);
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    text("Penalty: " + penalty,400,340);
    text("WPM w/ penalty: " + (wpm-penalty),400,360);
    return;
  }
  
  drawWatch();
  fill(100);
  rect(width/2-sizeOfInputArea/2, height/2-sizeOfInputArea/2, sizeOfInputArea, sizeOfInputArea);

  if (startTime==0 & !mousePressed)
  {
    fill(128);
    textAlign(CENTER);
    text("Click to start time!", 280, 150);
  }
  if (startTime==0 & mousePressed)
  {
    nextTrial();
  }
  if (startTime!=0)
  {
    textAlign(LEFT);
    fill(128);
    text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, 70, 50);
    text("Target:   " + currentPhrase, 70, 100);
    text("Entered:  " + currentTyped +"|", 70, 140);

    // Input area bounds
    float ax = width/2 - sizeOfInputArea/2;
    float ay = height/2 - sizeOfInputArea/2;
    float aw = sizeOfInputArea;
    float ah = sizeOfInputArea;

    // Split input area: top 60% = letters/row buttons, bottom 40% = utility buttons
    float topH    = ah * 0.6;
    float bottomH = ah * 0.4;
    float bottomY = ay + topH;

    if (lastClickedButton == -1)
    {
      // ---- TOP LEVEL: 3 row selector buttons stacked in top area ----
      float rowBH = topH / 3;
      String[] rowLabels = {"QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"};
      for (int r = 0; r < 3; r++)
      {
        float bx = ax;
        float by = ay + r * rowBH;
        fill(200, 200, 0);
        rect(bx, by, aw, rowBH);
        fill(0);
        textAlign(CENTER);
        text(rowLabels[r], bx + aw/2, by + rowBH/2 + 7);
      }

      // Bottom area: DEL | SPACE | ENTER
      float utilW = aw / 3;
      fill(255, 0, 0);
      rect(ax,             bottomY, utilW, bottomH);
      fill(0, 155, 255);
      rect(ax + utilW,     bottomY, utilW, bottomH);
      fill(0, 255, 0);
      rect(ax + 2*utilW,   bottomY, utilW, bottomH);
      fill(0);
      textAlign(CENTER);
      text("DEL",   ax + utilW/2,       bottomY + bottomH/2 + 7);
      text("SPACE", ax + utilW*1.5,     bottomY + bottomH/2 + 7);
      text("ENTER", ax + utilW*2.5,     bottomY + bottomH/2 + 7);
    }
    else
    {
      // ---- EXPANDED ROW: individual letter buttons in top area ----
      int start = 0, end = 0;
      if (lastClickedButton == 0){ start=0;  end=10; }
      if (lastClickedButton == 1){ start=10; end=19; }
      if (lastClickedButton == 2){ start=19; end=26; }
      int count = end - start;
      float letterW = aw / count;

      for (int i = 0; i < count; i++)
      {
        float bx = ax + i * letterW;
        fill(255, 255, 0);
        rect(bx, ay, letterW, topH);
        fill(0);
        textAlign(CENTER);
        text(alphabet[start+i], bx + letterW/2, ay + topH/2 + 7);
      }

      // Bottom area: BACK | DEL | SPACE | ENTER
      float utilW = aw / 4;
      fill(180, 100, 255);   // back = purple
      rect(ax,           bottomY, utilW, bottomH);
      fill(255, 0, 0);
      rect(ax + utilW,   bottomY, utilW, bottomH);
      fill(0, 155, 255);
      rect(ax + 2*utilW, bottomY, utilW, bottomH);
      fill(0, 255, 0);
      rect(ax + 3*utilW, bottomY, utilW, bottomH);
      fill(0);
      textAlign(CENTER);
      text("BACK",  ax + utilW*0.5, bottomY + bottomH/2 + 7);
      text("DEL",   ax + utilW*1.5, bottomY + bottomH/2 + 7);
      text("SPACE", ax + utilW*2.5, bottomY + bottomH/2 + 7);
      text("ENTER", ax + utilW*3.5, bottomY + bottomH/2 + 7);
    }
  }
}

//my terrible implementation you can entirely replace
boolean didMouseClick(float x, float y, float w, float h) //simple function to do hit testing
{
  return (mouseX > x && mouseX<x+w && mouseY>y && mouseY<y+h); //check to see if it is in button bounds
}

//my terrible implementation you can entirely replace
void mousePressed()
{
  if (startTime==0) return;

  // Input area bounds
  float ax = width/2 - sizeOfInputArea/2;
  float ay = height/2 - sizeOfInputArea/2;
  float aw = sizeOfInputArea;
  float ah = sizeOfInputArea;

  float topH    = ah * 0.6;
  float bottomH = ah * 0.4;
  float bottomY = ay + topH;

  if (lastClickedButton == -1)
  {
    // ---- TOP LEVEL: check row selector buttons ----
    float rowBH = topH / 3;
    for (int r = 0; r < 3; r++)
    {
      if (didMouseClick(ax, ay + r * rowBH, aw, rowBH))
      {
        lastClickedButton = r;
        return;
      }
    }

    // Bottom: DEL | SPACE | ENTER
    float utilW = aw / 3;
    if (didMouseClick(ax,           bottomY, utilW, bottomH) && currentTyped.length()>0)
    {
      currentTyped = currentTyped.substring(0, currentTyped.length()-1);
      return;
    }
    if (didMouseClick(ax + utilW,   bottomY, utilW, bottomH))
    {
      currentTyped += " ";
      return;
    }
    if (didMouseClick(ax + 2*utilW, bottomY, utilW, bottomH))
    {
      nextTrial();
      return;
    }
  }
  else
  {
    // ---- EXPANDED ROW: check letter buttons ----
    int start = 0, end = 0;
    if (lastClickedButton == 0){ start=0;  end=10; }
    if (lastClickedButton == 1){ start=10; end=19; }
    if (lastClickedButton == 2){ start=19; end=26; }
    int count = end - start;
    float letterW = aw / count;

    for (int i = 0; i < count; i++)
    {
      if (didMouseClick(ax + i * letterW, ay, letterW, topH))
      {
        currentTyped += alphabet[start+i];
        lastClickedButton = -1; // auto-collapse after letter entry
        return;
      }
    }

    // Bottom: BACK | DEL | SPACE | ENTER
    float utilW = aw / 4;
    if (didMouseClick(ax,           bottomY, utilW, bottomH))
    {
      lastClickedButton = -1; // BACK: return to row selector
      return;
    }
    if (didMouseClick(ax + utilW,   bottomY, utilW, bottomH) && currentTyped.length()>0)
    {
      currentTyped = currentTyped.substring(0, currentTyped.length()-1);
      return;
    }
    if (didMouseClick(ax + 2*utilW, bottomY, utilW, bottomH))
    {
      currentTyped += " ";
      return;
    }
    if (didMouseClick(ax + 3*utilW, bottomY, utilW, bottomH))
    {
      lastClickedButton = -1;
      nextTrial();
      return;
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
