#include <stdio.h>
#include <stdint.h>

void EaglesongHash( unsigned char * output, const unsigned char * input, int input_length );

void main( int argc, char ** argv ) {
    unsigned char input[10000];
    unsigned char output[32];
    int c;
    int i;

    i = 0;
    while( 1 ) {
        c = getchar();
        if( c == EOF ) {
            break;
        }
        input[i] = c;
        i = i + 1;
    }

    EaglesongHash(output, input, i);

    for( i = 0 ; i < 32 ; ++i ) {
        printf("%02x", output[i]);
    }

    printf("\n");
}
