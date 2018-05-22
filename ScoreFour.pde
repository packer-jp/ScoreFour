import processing.serial.*;

class Line {
  int x, y, z;
  Line(int x, int y, int z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
}

Serial myPort;
ArrayList < Line > [][][] lines = new ArrayList[4][4][4];

void init() {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 4; k++) {
        lines[i][j][k] = new ArrayList < Line > ();
        lines[i][j][k].add(new Line(1, 0, 0));
        lines[i][j][k].add(new Line(0, 1, 0));
        lines[i][j][k].add(new Line(0, 0, 1));
      }
    }
  }
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      lines[i][j][j].add(new Line(0, 1, 1));
      lines[j][i][j].add(new Line(1, 0, 1));
      lines[j][j][i].add(new Line(1, 1, 0));
      lines[i][j][3 - j].add(new Line(0, 1, -1));
      lines[3 - j][i][j].add(new Line(-1, 0, 1));
      lines[j][3 - j][i].add(new Line(1, -1, 0));
    }
    lines[i][i][i].add(new Line(1, 1, 1));
    lines[3 - i][i][i].add(new Line(-1, 1, 1));
    lines[i][3 - i][i].add(new Line(1, -1, 1));
    lines[i][i][3 - i].add(new Line(1, 1, -1));
  }
}

void sqcpy(int[][] par, int[][] child) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      child[i][j] = par[i][j];
    }
  }
}

void cbcpy(int[][][] par, int[][][] child) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 4; k++) {
        child[i][j][k] = par[i][j][k];
      }
    }
  }
}

void drop(int[][][] state, int[][] filled, int x, int y, int turn, ArrayList < Integer > active) {
  state[x][y][filled[x][y]] = turn;
  filled[x][y]++;
  if (filled[x][y] == 4) {
    active.remove(new Integer(x * 4 + y));
  }
}

boolean is_finished(int[][][] state, int x, int y, int z, int turn) {
  for (Line line: lines[x][y][z]) {
    for (int i = 0;; i++) {
      int refer_x = line.x == 0 ? x : line.x == 1 ? i : 3 - i;
      int refer_y = line.y == 0 ? y : line.y == 1 ? i : 3 - i;
      int refer_z = line.z == 0 ? z : line.z == 1 ? i : 3 - i;
      if (state[refer_x][refer_y][refer_z] != turn) {
        break;
      }
      if (i == 3) {
        return true;
      }
    }
  }
  return false;
}

int evaluate(int[][][] state, int[][] filled, int x, int y, int turn, ArrayList < Integer > active) {
  int turn_cpy = turn;
  while (true) {
    drop(state, filled, x, y, turn_cpy, active);
    if (is_finished(state, x, y, filled[x][y] - 1, turn_cpy)) {
      return turn * turn_cpy;
    }
    if (active.isEmpty()) {
      return 0;
    }
    int next = active.get((int)(Math.random() * active.size()));
    x = next / 4;
    y = next % 4;
    turn_cpy = -turn_cpy;
  }
}

int determine_hand(int[][][] state, int[][] filled, int turn, ArrayList < Integer > active) {
  int max_value = Integer.MIN_VALUE;
  int res = 0;
  for (int i = 0; i < 16; i++) {
    int x = i / 4, y = i % 4;
    if (filled[x][y] == 4) {
      continue;
    }
    int cur_value = 0;
    for (int j = 0; j < 30000; j++) {
      int[][][] state_cpy = new int[4][4][4];
      int[][] filled_cpy = new int[4][4];
      cbcpy(state, state_cpy);
      sqcpy(filled, filled_cpy);
      cur_value += evaluate(state_cpy, filled_cpy, x, y, turn, (ArrayList) active.clone());
    }
    if (cur_value > max_value) {
      max_value = cur_value;
      res = i;
    }
  }
  return res;
}


void setup() {
  surface.setLocation(-300, -300);
  surface.setVisible(false);
  myPort = new Serial(this, "COM3", 9600);
  init();
  int[][][] state = new int[4][4][4];
  int[][] filled = new int[4][4];
  int AI;
  ArrayList < Integer > active = new ArrayList();
  for (int i = 0; i < 16; i++) {
    active.add(i);
  }
  while(true){
    if(myPort.available() > 0){
      int input=myPort.read();
      if(input >= 200){
        AI = input - 201;
        break;
      }
    }
    delay(10);
  }
  int turn = 1;
  println(AI);
  for (int i = 0; i < 64; i++) {
    int hand;
    if (AI != turn) {
      while(true){
        if(myPort.available() > 0){
          int input=myPort.read();
          if(input >= 100 && input < 200){
            hand = input - 100;
            break;
          }
        }
        delay(10);
      }
      print("You:");
    } else {
      hand = determine_hand(state, filled, turn, active);
      myPort.write(hand + 100);
      print("AI:");
    }
    println(hand);
    int x = hand / 4, y = hand % 4;
    drop(state, filled, x, y, turn, active);
    if (is_finished(state, x, y, filled[x][y] - 1, turn)) {
      println(turn != AI ? "You win!!" : "You lose...");
      return;
    }
    turn = -turn;
  }
  println("Draw");
}

void draw(){
  exit();
}