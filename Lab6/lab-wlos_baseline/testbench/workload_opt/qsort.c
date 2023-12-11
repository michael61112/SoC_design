#include "qsort.h"

int __attribute__ ( ( section ( ".mprjram" ) ) ) partition(int low,int hi){
	int pivot = Am[hi];
	int i = low-1,j;
	int temp;
	for(j = low;j<hi;j++){
		if(Am[j] < pivot){
			i = i+1;
			temp = Am[i];
			Am[i] = Am[j];
			Am[j] = temp;
		}
	}
	if(Am[hi] < Am[i+1]){
		temp = Am[i+1];
		Am[i+1] = Am[hi];
		Am[hi] = temp;
	}
	return i+1;
}

void __attribute__ ( ( section ( ".mprjram" ) ) ) sort(int low, int hi){
	if(low < hi){
		int p = partition(low, hi);
		sort(low,p-1);
		sort(p+1,hi);
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) qsort(){
	sort(0,SIZE-1);
	return Am;
}
