AGSScriptModule    eri0o Select things using arrows in point and click games. ArrowSelect 0.5.0 �?  // Arrow Select Module Script
//
// MIT License
//
// Copyright (c) 2019 �rico Vieira Porto
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


bool _useKeyboardArrows;
int hotspot_minx[MAX_HOTSPOTS_PER_ROOM];
int hotspot_maxx[MAX_HOTSPOTS_PER_ROOM];
int hotspot_miny[MAX_HOTSPOTS_PER_ROOM];
int hotspot_maxy[MAX_HOTSPOTS_PER_ROOM];
int hotspot_x[MAX_HOTSPOTS_PER_ROOM];
int hotspot_y[MAX_HOTSPOTS_PER_ROOM];

bool _filterOutHotspots;
bool _filterOutObjects;
bool _filterOutCharacters;
bool _filterOutGUI;

// needed for ListBoxes real row count
int VisibleItemCount(this ListBox*){
  int d =  this.ItemCount - this.TopItem-1;
  if(d < this.RowCount){
    return d;
  } 
  return this.RowCount;
}

float degToRad(int deg){
  return IntToFloat(deg)*Maths.Pi/180.0;
}

int insertInteractive(Interactive* ilist[], int icount, InteractiveType itype,  int ID, int x,  int y,  int owningGUI_ID){
  ilist[icount] = new Interactive;
  ilist[icount].type = itype;
  ilist[icount].ID = ID;
  ilist[icount].owningGUI_ID = owningGUI_ID;
  ilist[icount].x = x;
  ilist[icount].y = y;
  icount++;
  return icount;
}

//this function calculates each hotspot position on the screen
function generate_hotspot_xy(){
  int i;
  Hotspot *h;

  i=0;
  while(i<MAX_HOTSPOTS_PER_ROOM){
    hotspot_minx[i]=999;
    hotspot_miny[i]=999;
    hotspot_maxx[i]=0;
    hotspot_maxy[i]=0;
    hotspot_x[i]=-1;
    hotspot_y[i]=-1;
    i++;
  }

  int x=0;
  int y=0;
  int step=3;
  int h_id;

  //we will walk the screen in steps
  //get the hotspot at the x,y point
  //and note down the smaller and bigger
  //x,y position for each hotspot
  while(y<Screen.Viewport.Height - 1){
    x=0;
    while(x<Screen.Viewport.Width - 1){

      h = Hotspot.GetAtScreenXY(x, y);
      h_id = h.ID;
      if(h_id>0){
        if(x < hotspot_minx[h_id] ){
          hotspot_minx[h_id] = x;
        }

        if(y < hotspot_miny[h_id]){
          hotspot_miny[h_id] = y;
        }

        if(x > hotspot_maxx[h_id]){
          hotspot_maxx[h_id] = x;
        }

        if(y > hotspot_maxy[h_id]){
          hotspot_maxy[h_id] = y;
        }
      }


      x=x+step;
    }
    y=y+step;
  }


  //using the previously obtained max and min x and y values
  //we calculate the center of the hotspot
  i=0;
  while(i<MAX_HOTSPOTS_PER_ROOM){
    hotspot_x[i]=hotspot_minx[i]+(hotspot_maxx[i]-hotspot_minx[i])/2;
    hotspot_y[i]=hotspot_miny[i]+(hotspot_maxy[i]-hotspot_miny[i])/2;
    i++;
  }
}

static void ArrowSelect::filterInteractiveType(InteractiveType interactiveType, InteractiveFilter filter){
  if(interactiveType == eInteractiveTypeObject){
    if(filter == eI_FilterOut){
      _filterOutObjects = true;
    } else {
      _filterOutObjects = false;      
    }  
  } else if(interactiveType == eInteractiveTypeHotspot){
    if(filter == eI_FilterOut){
      _filterOutHotspots = true;
    } else {
      _filterOutHotspots = false;      
    }  
  } else if(interactiveType == eInteractiveTypeCharacter){
    if(filter == eI_FilterOut){
      _filterOutCharacters = true;
    } else {
      _filterOutCharacters = false;      
    }  
  } else if(interactiveType == eInteractiveTypeGUI){
    if(filter == eI_FilterOut){
      _filterOutGUI = true;
    } else {
      _filterOutGUI = false;      
    }  
  } else if(interactiveType == eInteractiveTypeGUIControl){
    if(filter == eI_FilterOut){
      _filterOutGUI = true;
    } else {
      _filterOutGUI = false;      
    }  
  }
}

int _unpackGUIControl(Interactive* ilist[], int icount, GUIControl* aguictrl, int guicntrl_x,  int guicntrl_y){
  if(aguictrl.AsListBox !=null){
    int visibleItems = aguictrl.AsListBox.VisibleItemCount();
    int itemHeight = aguictrl.Height / aguictrl.AsListBox.RowCount;
    int topItemY = aguictrl.OwningGUI.Y+aguictrl.Y+itemHeight/2;
    int i=0;
    while(i<visibleItems){
      icount = insertInteractive(ilist, icount, 
                eInteractiveTypeGUIControl, aguictrl.ID, guicntrl_x, topItemY+i*itemHeight, 
                aguictrl.OwningGUI.ID);

      i++;
    }
    
    
  }else if(aguictrl.AsSlider !=null){
    int parts = 4;
    bool horizontal = aguictrl.Height < aguictrl.Width;
    int ctrlWidth = aguictrl.Width-1;
    int ctrlHeight = aguictrl.Height-1;
    int partWidth = 0;
    int partHeight = 0;
    int offset_x = 0;
    int offset_y = 0;
    if(horizontal){
      partWidth = ctrlWidth/parts;
      offset_x = 1-ctrlWidth/2;
    } else {
      partHeight = ctrlHeight/parts;
      offset_y = 1-ctrlHeight/2;
    }
    
    int i=0;
    while(i<=parts){
      icount = insertInteractive(ilist, icount, 
                eInteractiveTypeGUIControl, aguictrl.ID, offset_x+guicntrl_x+i*partWidth, offset_y+guicntrl_y+i*partHeight, 
                aguictrl.OwningGUI.ID);
          
      i++;
    }
    
  }else if(aguictrl.AsInvWindow !=null){
    int itemHeight = aguictrl.AsInvWindow.ItemHeight;
    int itemWidth = aguictrl.AsInvWindow.ItemWidth;
    
    int origin_x = aguictrl.OwningGUI.X + aguictrl.X + 2*itemWidth/3;
    int origin_y = aguictrl.OwningGUI.Y + aguictrl.Y + 2*itemHeight/3;
    
    int itemsPerRow = aguictrl.AsInvWindow.ItemsPerRow;
    int itemCount = aguictrl.AsInvWindow.ItemCount;
    
    int i=0;
    while(i<itemCount){
      icount = insertInteractive(ilist, icount, 
                eInteractiveTypeGUIControl, aguictrl.ID, origin_x+(i%itemsPerRow)*itemWidth, origin_y+(i/itemsPerRow)*itemHeight, 
                aguictrl.OwningGUI.ID);

      i++;
    }
    
  }else{
    icount = insertInteractive(ilist, icount, 
              eInteractiveTypeGUIControl, aguictrl.ID, guicntrl_x, guicntrl_y, 
              aguictrl.OwningGUI.ID);
              
    icount++;
  }
  return icount;
}

static Interactive*[] ArrowSelect::getInteractives(){
  Interactive* ilist[];
  ilist = new Interactive[MAX_LABELS];
  int icount=0;

  int obj_count = Room.ObjectCount;
  int cha_count = Game.CharacterCount;
  int gui_count = Game.GUICount;
  Character *c;
  int i;
  int textx,  texty;
  String text;
  
  if(!_filterOutHotspots){
    generate_hotspot_xy();
  }
  
  i=0;
  while(!_filterOutHotspots && i<MAX_HOTSPOTS_PER_ROOM){
    text = hotspot[i].Name;
    if(hotspot[i].Enabled &&
      text.Length > 1 && text.IndexOf("Hotspot") == -1){
        
      // checks there's no GUI ocluding the hotspot
      if(GUI.GetAtScreenXY(hotspot_x[i], hotspot_y[i])==null){
        icount = insertInteractive(ilist, icount, 
                  eInteractiveTypeHotspot, hotspot[i].ID, hotspot_x[i], hotspot_y[i], 
                  -1);
      
      }
    }
    i++;
  }

  i=0;
  while(!_filterOutObjects && i<obj_count){
    if(object[i].Visible && object[i].Clickable){
      Point* objPoint = Screen.RoomToScreenPoint(
        object[i].X+Game.SpriteWidth[object[i].Graphic]/2,
        object[i].Y-Game.SpriteHeight[object[i].Graphic]/2);

      int objx = objPoint.x;
      int objy = objPoint.y;

      //check if object inside screen
      if((objx>0 && objx<Screen.Width) &&
         (objy>0 && objy<Screen.Height) &&
         GUI.GetAtScreenXY(objx, objy)==null){  // checks there's no GUI ocluding the object
         
        icount = insertInteractive(ilist, icount, 
                  eInteractiveTypeObject, object[i].ID, objx, objy, 
                  -1);
          
      }
    }
    i++;
  }

  i=0;
  while (!_filterOutCharacters && i<cha_count) {
    c = character[i];
    if (c.Room == player.Room && c.Clickable) {
      ViewFrame *cviewframe = Game.GetViewFrame(c.View, c.Loop, c.Frame);
      Point* chaPoint = Screen.RoomToScreenPoint(
        c.x,
        c.y - Game.SpriteHeight[cviewframe.Graphic]*c.Scaling/2*100);

      int cha_x = chaPoint.x;
      int cha_y = chaPoint.y;

      text = c.Name;
      //check if character inside screen
      if(text.Length>1 && cha_x>0 && cha_x<Screen.Width &&
         cha_y>0 && cha_y<Screen.Height &&
         (GUI.GetAtScreenXY(cha_x, cha_y)==null)){ // checks there's no GUI ocluding the character
          
        icount = insertInteractive(ilist, icount, 
                  eInteractiveTypeCharacter, c.ID, cha_x, cha_y, 
                  -1);

      }
    }
    i++;
  }

  i=0;
  while (!_filterOutGUI && i<gui_count) {
    if(gui[i].Visible && gui[i].Clickable && gui[i].Transparency < 100){
      GUI* agui = gui[i];
      int k=0;
      while (k < agui.ControlCount) {
        GUIControl*aguictrl = agui.Controls[k];

        if(aguictrl.Clickable && aguictrl.Enabled && aguictrl.Visible){
          
          int guicntrl_x = agui.X+ aguictrl.X + aguictrl.Width/2;
          int guicntrl_y;
          if(aguictrl.OwningGUI.PopupStyle == eGUIPopupMouseYPos){
            guicntrl_y = aguictrl.OwningGUI.PopupYPos-1;
          } else {
            guicntrl_y = agui.Y+ aguictrl.Y + aguictrl.Height/2;
          }
                    
          // checks there's no GUI ocluding the GUI in question
          // there's an exception for GUIs with PopupStyle per Y pos
          // because we can't easily figure out ordering with them
          if(aguictrl.OwningGUI.PopupStyle == eGUIPopupMouseYPos ||
             GUI.GetAtScreenXY(guicntrl_x, guicntrl_y)==aguictrl.OwningGUI){
              
            icount = _unpackGUIControl(ilist, icount, aguictrl, guicntrl_x, guicntrl_y);
          }
        }

        k++;
      }

    }

    i++;
  }


  while (icount < MAX_LABELS) {
    ilist[icount] = new Interactive;
    ilist[icount].ID = -1;
    ilist[icount].owningGUI_ID = -1;
    icount++;
  }

  return ilist;
}

static Triangle* ArrowSelect::triangleFromOriginAngleAndDirection(Point* origin, int direction, int spreadAngle){
  float distance_limits = IntToFloat(Screen.Width);
  float radDirection = degToRad(direction);
  float radSpreadAngle = degToRad(spreadAngle);

  Triangle* tri = new Triangle;

  //the triangle can't include the origin point!
  tri.a_x = origin.x+FloatToInt(6.0*Maths.Cos(radDirection));
  tri.a_y = origin.y+-FloatToInt(6.0*Maths.Sin(radDirection));

  tri.b_x = tri.a_x + FloatToInt(distance_limits*Maths.Cos(radDirection-radSpreadAngle/2.0));
  tri.b_y = tri.a_y - FloatToInt(distance_limits*Maths.Sin(radDirection-radSpreadAngle/2.0));
  tri.c_x = tri.a_x + FloatToInt(distance_limits*Maths.Cos(radDirection+radSpreadAngle/2.0));
  tri.c_y = tri.a_y - FloatToInt(distance_limits*Maths.Sin(radDirection+radSpreadAngle/2.0));


  return tri;
}

static int ArrowSelect::distanceInteractivePoint(
  Interactive* s, Point* a){

  return (s.x-a.x)*(s.x-a.x)+ (s.y-a.y)*(s.y-a.y);
}


static Interactive* ArrowSelect::closestValidInteractivePoint(
  Interactive* Interactives[], Point* a){

  int min_distance=100000;
  int min_distance_i=-1;
  int i=0;
  while(i<MAX_LABELS){
    Interactive* aInteractive = Interactives[i];
    if(aInteractive!=null && aInteractive.ID >= 0){
      int distanceToPoint = ArrowSelect.distanceInteractivePoint(aInteractive, a);
      if(distanceToPoint<min_distance){
        min_distance = distanceToPoint;
        min_distance_i = i;
      }
    }

    i++;
  }

  if(min_distance_i>=0){
    return Interactives[min_distance_i];
  } else {
    return null;
  }
}

static bool ArrowSelect::isInteractiveInsideTriangle(
  Interactive* p, Point* a, Point* b, Point* c){

  int s = a.y * c.x - a.x * c.y + (c.y - a.y) * p.x + (a.x - c.x) * p.y;
  int t = a.x * b.y - a.y * b.x + (a.y - b.y) * p.x + (b.x - a.x) * p.y;

  if ((s < 0) != (t < 0))
      return false;

  int Ar = -b.y * c.x + a.y * (c.x - b.x) + a.x * (b.y - c.y) + b.x * c.y;

  if(Ar < 0 ){
    return (s <= 0 && s + t >= Ar);
  }
  return (s >= 0 && s + t <= Ar);
}

static Interactive*[] ArrowSelect::whichInteractivesInTriangle(
  Interactive* Interactives[], Point* a, Point* b, Point* c){

  if(Interactives==null){
    return null;
  }

  int i=0;
  while(i<MAX_LABELS){
    if(Interactives[i]!=null && Interactives[i].ID >= 0){
      if(!ArrowSelect.isInteractiveInsideTriangle(
        Interactives[i], a, b, c)){

        Interactives[i].ID = -1;

      }
    }

    i++;
  }

  return Interactives;
}

static Point* ArrowSelect::getNearestInteractivePointAtDirection(CharacterDirection dir){
  Point* p = new Point;
  p.x = mouse.x;
  p.y = mouse.y;
  Triangle* tri;
  if(dir == eDirectionRight){
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 0);
  } else if(dir == eDirectionUpRight){
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 45);
  } else if(dir == eDirectionUp){
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 90);
  } else if(dir == eDirectionUpLeft){
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 135);
  } else if(dir == eDirectionLeft){
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 180);
  } else if(dir == eDirectionDownLeft){
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 225);
  } else if(dir == eDirectionDown){
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 270);
  } else {
    tri = ArrowSelect.triangleFromOriginAngleAndDirection(p, 315);
  }

  Point* tri_a = new Point;
  Point* tri_b = new Point;
  Point* tri_c = new Point;
  tri_a.x = tri.a_x;
  tri_a.y = tri.a_y;
  tri_b.x = tri.b_x;
  tri_b.y = tri.b_y;
  tri_c.x = tri.c_x;
  tri_c.y = tri.c_y;

  Interactive* iList[];
  iList = ArrowSelect.getInteractives();

  iList = ArrowSelect.whichInteractivesInTriangle(iList, tri_a, tri_b, tri_c);

  Interactive* aInteractive = ArrowSelect.closestValidInteractivePoint(iList, p);
  if(aInteractive!=null){
    p.x = aInteractive.x;
    p.y = aInteractive.y;
    return p;
  }
  return null;
}

static bool ArrowSelect::moveCursorDirection(CharacterDirection dir){
  Point* p = ArrowSelect.getNearestInteractivePointAtDirection(dir);

  //if the point is a list box item, we need to select it too
  
  if(p == null){
    return false;
  }
  
  GUIControl* aguictrl = GUIControl.GetAtScreenXY(p.x, p.y);
  if(aguictrl != null && aguictrl.AsListBox !=null){
    aguictrl.AsListBox.SelectedIndex = aguictrl.AsListBox.GetItemAtLocation(p.x, p.y);
  }

  mouse.SetPosition(p.x, p.y);
  return true;
}

static bool ArrowSelect::areKeyboardArrowsEnable(){
  return _useKeyboardArrows;
}

static bool ArrowSelect::enableKeyboardArrows(bool isKeyboardArrowsEnabled){
  _useKeyboardArrows = isKeyboardArrowsEnabled;
}

function on_key_press(eKeyCode keycode) {
  if(!_useKeyboardArrows){
    return;
  }

  if (keycode == eKeyDownArrow) {
    ArrowSelect.moveCursorDirection(eDirectionDown);
    return;
  } else if (keycode == eKeyUpArrow) {
    ArrowSelect.moveCursorDirection(eDirectionUp);
    return;
  } else if (keycode == eKeyLeftArrow) {
    ArrowSelect.moveCursorDirection(eDirectionLeft);
    return;
  } else if (keycode == eKeyRightArrow) {
    ArrowSelect.moveCursorDirection(eDirectionRight);
    return;
  }
}
 �  //Arrow Select Module Header// MIT License
//
// Copyright (c) 2019 �rico Vieira Porto
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// ## Implementation details
// This is just the detail on how things works on this module
//
// ### Problem
// By using keyboard arrow keys or joystick directional hat, select between
// clickable things on screen.
//
// ### Solution
// When the player press an arrow button do as follow:
//
// 1 .get the x,y position of each thing on screen,
//
// 2 .select only things on arrow button direction (example:at right of current
// cursor position, when player press right arrow button),
//
// 3 .calculate distance from cursor to things there, and get what has the
// smaller distance
//
// This is implemented by `bool moveCursorDirection(CharacterDirection dir)`
//
// Look into module README for more info


#define MAX_HOTSPOTS_PER_ROOM 49
#define MAX_LABELS 70

enum InteractiveFilter{
  eI_FilterOut=0, 
  eI_FilterIn=1
};

enum InteractiveType{
  eInteractiveTypeNothing = eLocationNothing,
  eInteractiveTypeObject = eLocationObject,
  eInteractiveTypeCharacter = eLocationCharacter,
  eInteractiveTypeHotspot = eLocationHotspot,
  eInteractiveTypeGUIControl,
  eInteractiveTypeGUI,
};

managed struct Triangle{
  int a_x;
  int a_y;
  int b_x;
  int b_y;
  int c_x;
  int c_y;
};

managed struct Interactive{
  int x;
  int y;
  int ID;
  int owningGUI_ID;
  InteractiveType type;
};

struct ArrowSelect
{  
  /// Moves cursor to the interactive available at a direction. Returns true if the cursor is successfully moved.
  import static bool moveCursorDirection(CharacterDirection dir);
  
  /// Get point to the interactive available at a direction. Returns true if the cursor is successfully moved.
  import static Point* getNearestInteractivePointAtDirection(CharacterDirection dir);
  
  /// Filters or not a interactive type for cursor moveCursorDirection and getNearestInteractivePointAtDirection.
  import static void filterInteractiveType(InteractiveType interactiveType, InteractiveFilter filter=0);
  
  /// Returns a Triangle instance with one point at the origin points and the two other points separated by spreadAngle, and at the direction angle
  import static Triangle* triangleFromOriginAngleAndDirection(Point* origin, int direction, int spreadAngle=90);

  /// Retuns the distance between an interactive and a point.
  import static int distanceInteractivePoint(Interactive* s, Point* a);
  
  /// Returns the closest interactive to a point.
  import static Interactive* closestValidInteractivePoint(Interactive* Interactives[], Point* a);

  /// Get a list of all interactives on screen.
  import static Interactive*[] getInteractives();

  /// Returns true if an interactive is inside a triangle defined by three points.
  import static bool isInteractiveInsideTriangle(Interactive* p, Point* a, Point* b, Point* c);

  /// Returns a list of which triangles are inside a triangle defined by three points.
  import static Interactive*[] whichInteractivesInTriangle(Interactive* Interactives[], Point* a, Point* b, Point* c);

  /// Returns true if regular keyboard arrows are enabled for cursor movements.
  import static bool areKeyboardArrowsEnable();

  /// Enables or disables (by passing `false`) regular keyboard arrows handled by this module.
  import static bool enableKeyboardArrows(bool isKeyboardArrowsEnabled = 1);
};
 0#�:        ej��