#include <MsTimer2.h>

#define JOY_X 0
#define JOY_Y 1

#define SI 2
#define SCK 3
#define RCK 4

#define LAYER_1 5
#define LAYER_2 6
#define LAYER_3 7
#define LAYER_4 8

#define SWITCH 9

#define DEBUG 13

int state[4][4][4] = {};
int view[4][4][4] = {};
int layer[4] = {LAYER_4, LAYER_3, LAYER_2, LAYER_1};
int turn = 1;
int cursor_x = 0, cursor_y = 0;
bool cursor_switch = true;
bool prev_pushed = false;
bool prev_moved = false;
int filled[4][4] = {};
int AI;

void timerFire() {
  if (cursor_switch) {
    view[cursor_x][cursor_y][3] = turn;
  } else {
    view[cursor_x][cursor_y][3] = state[cursor_x][cursor_y][3];
  }
  cursor_switch = !cursor_switch;
}

void setup() {
  pinMode(SI, OUTPUT);
  pinMode(SCK, OUTPUT);
  pinMode(RCK, OUTPUT);
  for (int i = 0; i < 4; i++) {
    pinMode(layer[i], OUTPUT);
    digitalWrite(layer[i], LOW);
  }
  pinMode(SWITCH, INPUT);
  pinMode(DEBUG, OUTPUT);
  MsTimer2::set(250, timerFire);
  MsTimer2::start();
  Serial.begin(9600);
  AI = 1;
  if (AI != 0) {
    Serial.write(AI + 201);
  }
}

void drop() {
  state[cursor_x][cursor_y][filled[cursor_x][cursor_y]] = turn;
  view[cursor_x][cursor_y][filled[cursor_x][cursor_y]] = turn;
  filled[cursor_x][cursor_y]++;
  if (filled[cursor_x][cursor_y] == 4) {
    do {
      int xy = cursor_x * 4 + cursor_y;
      xy = (xy + 1) % 16;
      cursor_x = xy / 4;
      cursor_y = xy % 4;
    } while (filled[cursor_x][cursor_y] == 4);
  }
  turn = -turn;
}

void read_JOY() {
  int x = analogRead(JOY_X);
  int y = analogRead(JOY_Y);
  int right = 512 - x, left = x - 512, top = 512 - y, bottom = y - 512;
  int dir = max(max(left, right), max(top, bottom));
  bool cur_moved = dir > 500;
  if (!prev_moved && cur_moved) {
    view[cursor_x][cursor_y][3] = 0;
    int dx = 0, dy = 0;
    if (dir == left) {
      dx = 3;
    } else if (dir == right) {
      dx = 1;
    } else if (dir == top) {
      dy = 3;
    } else if (dir == bottom) {
      dy = 1;
    }
    int tmp_x = cursor_x, tmp_y = cursor_y;
    do {
      cursor_x = (cursor_x + dx) % 4;
      cursor_y = (cursor_y + dy) % 4;
    } while (filled[cursor_x][cursor_y] == 4);
    view[tmp_x][tmp_y][3] = 0;
  }
  prev_moved = cur_moved;
}

void disp() {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 4; k++) {
        digitalWrite(SCK, LOW);
        digitalWrite(SI, view[j][j < 2 ? k : 3 - k][i] == 1 ? HIGH : LOW);
        digitalWrite(SCK, HIGH);
        digitalWrite(SCK, LOW);
        digitalWrite(SI, view[j][j < 2 ? k : 3 - k][i] == -1 ? HIGH : LOW);
        digitalWrite(SCK, HIGH);
      }
    }
    digitalWrite(layer[i], HIGH);
    digitalWrite(RCK, HIGH);
    delay(1);
    digitalWrite(layer[i], LOW);
    digitalWrite(RCK, LOW);
  }
}

void loop() {
  bool cur_pushed = digitalRead(SWITCH) == LOW;
  if (turn == AI) {
    if (Serial.available() > 0) {
      int hand = Serial.read();
      view[cursor_x][cursor_y][3] = 0;
      if (hand >= 100) {
        hand -= 100;
        cursor_x = hand / 4, cursor_y = hand % 4;
        drop();
      }
    }
  } else {
    if (!prev_pushed && cur_pushed) {
      if (AI != 0) {
        Serial.write(cursor_x * 4 + cursor_y + 100);
      }
      drop();
    }
    prev_pushed = cur_pushed;
    read_JOY();
  }
  disp();
}
