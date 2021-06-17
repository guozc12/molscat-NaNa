      SUBROUTINE ECNVX(EUNITS,IVAL)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  THIS ROUTINE CONVERTS A 4 CHARACTER INPUT -- EUNITS --
C  INTO THE CORRESPONDING INTEGER VALUE -- IVAL.
C  IMPLEMENTED UNITS ARE
C    1) CM-1   2) DEG. K  3) MHZ  4) GHZ  5) EV  6) ERG  7) A.U.
C    8) KJ/MOL 9) KCAL/MOL
C
C  ON ENTRY: EUNITS SHOULD BE 4 CHARACTER STRING CORRESPONDING TO ONE OF
C            THE IMPLEMENTED UNITS. UNCHANGED
C  ON EXIT:  IVAL IS THE INTEGER VALUE CORRESPONDING TO THE UNIT.
C
      LOGICAL STSRCH
      CHARACTER(1) L4(4),C,M,K,H,Z,E,V,R,G,A,U,L,J
      CHARACTER(4) LTYP(9),EUNITS
      DATA MX/9/
      DATA LTYP/'CM-1',' K  ',' MHZ','GHZ ',' EV ','ERG', 'A.U.',
     1          'KJ/M','KCAL'/
      DATA C/'C'/,M/'M'/,K/'K'/,H/'H'/,Z/'Z'/,E/'E'/,V/'V'/,
     2     R/'R'/, G/'G'/, A/'A'/, U/'U'/, L/'L'/, J/'J'/
C  PUT CHARACTERS OF EUNITS INTO ARRAY L4
      L4(1)=EUNITS(1:1)
      L4(2)=EUNITS(2:2)
      L4(3)=EUNITS(3:3)
      L4(4)=EUNITS(4:4)
C
 2000 DO 2001 II=1,4
C  SEARCH FOR ONE OF ALLOWED 1ST LETTERS. . .
      IF (L4(II).EQ.C) GOTO 3001
      IF (L4(II).EQ.K) GOTO 3002
      IF (L4(II).EQ.M) GOTO 3003
      IF (L4(II).EQ.G) GOTO 3004
      IF (L4(II).EQ.E) GOTO 3005
 2001 IF (L4(II).EQ.A) GOTO 3006
      GOTO 2991

C  FOR EACH ALLOWED FIRST LETTER, SEARCH FOR NEXT IN KEYWORDS. . .
 3001 IF (.NOT.STSRCH(M,L4(II+1),4-II,IIF)) GOTO 2991
      IT=1
      GOTO 5000
C
 3002 IF (.NOT.STSRCH(C,L4(II+1),4-II,IIF)) GOTO 3012
      IFN=II+IIF
      IF (.NOT.STSRCH(A,L4(IFN+1),4-IFN,IIF)) GOTO 2991
      IFN=IFN+IIF
      IF (.NOT.STSRCH(L,L4(IFN+1),4-IFN,IIF)) GOTO 2991
      IT=9
      GOTO 5000
 3012 IF (.NOT.STSRCH(J,L4(II+1),4-II,IIF)) GOTO 3022
      IT=8
      GOTO 5000
 3022 IT=2
      GOTO 5000
 3003 IF (.NOT.STSRCH(H,L4(II+1),4-II,IIF)) GOTO 2991
      IF (.NOT.STSRCH(Z,L4(II+IIF+1),4-II-IIF,IIF)) GOTO 2991
      IT=3
      GOTO 5000
 3004 IF (.NOT.STSRCH(H,L4(II+1),4-II,IIF)) GOTO 2991
      IF (.NOT.STSRCH(Z,L4(II+IIF+1),4-II-IIF,IIF)) GOTO 2991
      IT=4
      GOTO 5000
 3005 IF (.NOT.STSRCH(V,L4(II+1),4-II,IIF)) GOTO 3015
      IT=5
      GOTO 5000
 3015 IF (.NOT.STSRCH(R,L4(II+1),4-II,IIF)) GOTO 2991
      IF (.NOT.STSRCH(G,L4(II+IIF+1),4-II-IIF,IIF)) GOTO 2991
      IT=6
      GOTO 5000
 3006 IF (.NOT.STSRCH(U,L4(II+1),4-II,IIF)) GOTO 2991
      IT=7
      GOTO 5000

 2991 CONTINUE
C
      WRITE(6,699) EUNITS,(LTYP(I),I=1,MX)
  699 FORMAT(/' *** WARNING. EUNITS INPUT = ',A4,' CANNOT BE',
     1        ' PROCESSED. ALLOWED TYPES ARE'//14X,9(2X,A4))
      STOP

 5000 IVAL=IT
C     WRITE(6,602) LTYP(IT),EUNITS
C 602 FORMAT(/'  INPUT ENERGY VALUES CONVERTED FROM ',A4,' TO INTERNAL',
C    1        ' WORKING UNITS OF CM-1 DUE TO ALPHANUMERIC INPUT =',A4)
      RETURN
      END
