#include "fir.h"
#include <stdio.h>
void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {

    for (int i = 0; i < N; i++) {
        inputbuffer[i] = 0;
	outputsignal[i] = 0;
    }

}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
    int i, j;
    for (i = 0; i < N; i++) {
        for (j = 0; j <= i; j++) {
          outputsignal[i] += taps[i-j] * inputsignal[j];
        }
    }
return outputsignal;
}
		
