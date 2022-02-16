/*  ######################################################################## */
/*  05: Programm-Ablauf-Steuerung (Kontrollstrukturen)                       */
/*  ######################################################################## */

#include "c00.h"        /* WICHTIG für msVisualStudio Express */

#ifdef  USE__TUTOR_C2CPP
    int cpp_control(void);
#endif    

int main(void) 
{
    int     i=7,j=0;                 
    int     x=4,y=8,z=1;


    printf("============================================================\n");
    printf("[C05]:  CONTROL structs\n");
    printf("============================================================\n");

    printf("--- FILE:%s,DATE={%s-%s}\n",
            __FILE__,  
            __DATE__,   
            __TIME__);        
#ifdef  __cplusplus
    printf("--- isC++:=YES\n");
#else
    printf("--- isC++:=NO !\n");
#endif


    printf("USE:i=%d,x=%d,y=%d,z=%d\n",i,x,y,z); 


/*  
 *  ***************************************************************************
 *  1) (a==b) ? a : b         (AUSWAHL-OPERATOR)        
 *  ***************************************************************************
 */

    printf("*** [%s;%d]: (x==y) ? (x) : (y)\n",__FILE__,__LINE__); 
    (x < y) ? printf("(%d < %d)?=:YES",x,y) : printf("(%d < %d)?=:NO",x,y);
    printf("\n");

/*  
 *  ***************************************************************************
 *  2) if {...} [else if {...} else {...}]; {....}       
 *  ***************************************************************************
 *  === !KEY:   if
 *  === !KEY:   else
 */
    printf("*** [%s;%d]: if (x) {...}\n",__FILE__,__LINE__); 
    printf("--- if (x) {...}\n"); 
    if (x < y) { 
        printf("(%d < %d) =: ja\n",x,y); 
    }

    printf("--- if (x) {...} else {...};\n"); 
    printf("x={3>1}=:");
    if (3 > 1)  /* warning: bedinger Ausdruck konstant */
    { 
        printf("ja"); 
    }
    else {
        printf("nein"); 
    }        
    printf("\n"); 

    printf("--- if (x) {...} else if(y) {...} ;\n"); 
    if (x > y) { 
        printf("if(x:%d > y:%d) =:YES",x,y); 
    }
    else if (y > z) { 
        printf("else if (y:%d > z:%d)=:YES",y,z); 
    }
    else {
        printf("=:NO"); 
    }        
    printf("\n"); 

/*  
 *  ***************************************************************************
 *  3) switch {....}       
 *  ***************************************************************************
 *  === !KEY:   switch
 *  === !KEY:   case
 *  === !KEY:   default
 *  === !KEY:   break
 */

    printf("*** [%s;%d]: switch(x) {};\n",__FILE__,__LINE__); 
    switch(x) {
        case 0: printf("x==0\n"); break;
        case 1: printf("x==1\n"); break;
        case 2: printf("x==2\n"); break;
        case 3: printf("x==3\n"); break;
        case 4: printf("x==4\n"); break;
        default:
                printf("x==?\n"); break;
    };
            
/*  
 *  ***************************************************************************
 *  4) for(i=0; i<x; i++)    
 *  ***************************************************************************
 *  === !KEY:   for
 */

    printf("*** [%s;%d]: for (i=0;i<%d;i++) {...}\n",__FILE__,__LINE__,x); 
    for (i=0; i<x; i++) {
        printf("i:%d;",i);
    }
    printf("\n");
    
    printf("*** for (i=0;i<%d;i++) {..if(i==3){break};.}\n",y); 
    for (i=0; i<y; i++) {
        if (i==3) {
            break;
        }            
        printf("i:%d;",i);
    }
    printf("\n");


/*  
 *  ***************************************************************************
 *  5) while(x) {...}    
 *  ***************************************************************************
 *  === !KEY:   while
 */

    printf("*** [%s;%d]: while (i<%d) {i++;...}\n",__FILE__,__LINE__,x); 
    i = 0;
    while(i < x) {
        i++;
        printf("i:%d;",i);
    }            
    printf("\n");

/*  
 *  ***************************************************************************
 *  6) do while(x) {...}    
 *  ***************************************************************************
 *  === !KEY:   do
 */

    printf("*** [%s;%d]: do while(x) {..} \n",__FILE__,__LINE__); 
    i = 0;
    do {
        i++;
        printf("i:%d;",i);
    } while(i < x);
    printf("\n");


/*  
 *  ***************************************************************************
 *  7) goto {...}   
 *  ***************************************************************************
 *  === !KEY:   goto
 *  REM: beliebiger Sprung
 */
 
    printf("*** [%s;%d]: goto \n",__FILE__,__LINE__); 
    for(i=0; i<5; i++) {
        for(j=0; j<5;j++) {
            printf("(%d|%d);",i,j);
            if ((i == j) && (i == 3)) {
                printf("!GOTO!");
                goto l_Next;
            }
            printf("*");
        }            
        printf("#");
    }        
    printf("LINE=%d\n",__LINE__);
l_Next:
    printf("\n");
    printf("Hier weiter\n");

/*  
 *  ***************************************************************************
 *  8) break {...}    
 *  ***************************************************************************
 *  REM: beendet den Schleifendurchlauf
 */

    printf("*** [%s;%d]: break \n",__FILE__,__LINE__); 
    for(i=0; i<5; i++) {
        for(j=0; j<5;j++) {
            printf("(%d|%d);",i,j);
            if ((i == j) && (i == 3)) {
                printf("!BREAK!");
                break;      /* leave for(j) */
            }
            printf("*");    
        }            
        printf("#");
    }        
    printf("\n");

/*  
 *  ***************************************************************************
 *  9) continue {...}  
 *  ***************************************************************************
 *  === !KEY:   continue
 *  REM: setzt unmittelbar den Schleifendurchlauf fort
 */
    printf("*** [%s;%d]: continue \n",__FILE__,__LINE__); 
    for(i=0; i<5; i++) {
        for(j=0; j<5;j++) {
            printf("(%d|%d);",i,j);
            if ((i == j) && (i == 3)) {
                printf("!CONTINUE!");
                continue; /* goto for(j) */
            }
            printf("*");        /* continue::überspinge nur dieses Statment */
        }            
        printf("#");
    }        
    printf("\n");

    printf("Ende C\n");

/*  
 *  ***************************************************************************
 *  10) c++ additions  
 *  ***************************************************************************
 */

#ifdef  USE__TUTOR_C2CPP
    cpp_control();
#endif    
    printf("--- EndOfFile:[%s] at LineNr:[%d] \n",__FILE__,__LINE__);
    return(0);
}

