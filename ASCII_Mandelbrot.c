/**
 * @file ASCII_Mandelbrot.c
 * Murtaza Gulamali (02/03/2012)
 *
 * Self explanatory really... an ASCII Mandelbrot beetle generator:
 * http://en.wikipedia.org/wiki/Mandelbrot_set
 * 
 * This software is released under the terms and conditions of The MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */

#include <stdio.h>

#define HEIGHT   22
#define WIDTH    78
#define BLACK    "#"
#define WHITE    "."
#define MAXITERS 100

int main(int argc, const char* argv[]) {
  int a, b, i;
  double x, y, p, q;
  for (a=0; a<HEIGHT; a++) {
    for (b=0; b<WIDTH; b++) {
      x = 0.0; y = 0.0; i = 0;
      while ((x*x+y*y)<4.0 && (i<MAXITERS)) {
        p = x*x-y*y+b/(WIDTH/2.0)-1.5;
        q = 2.0*x*y+a/(HEIGHT/2.0)-1.0;
        x = p; y = q; i++;
      }			
      (i>99) ? printf(BLACK) : printf(WHITE);
    }
    printf("\n");
  }
}
