      SUBROUTINE WVCALC(WVEC,WMAX,ERED,EINT,NOPEN,N)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  CR Le Sueur 2015
C  COMMON CODE EXTRACTED FROM SEVERAL PLACES (MOSTLY PROPAGATION
C  ROUTINES)
      IMPLICIT NONE

      INTEGER, INTENT(IN)::N
      INTEGER, INTENT(OUT)::NOPEN
      INTEGER I

      DOUBLE PRECISION, INTENT(IN)::ERED,EINT(N)
      DOUBLE PRECISION, INTENT(OUT)::WVEC(N),WMAX
      DOUBLE PRECISION DIF

      WMAX=0.0D0
      NOPEN=0

      DO I=1,N
        DIF=ERED-EINT(I)
        WVEC(I)=SIGN(SQRT(ABS(DIF)),DIF)
        IF (DIF.LE.0.0D0) CYCLE
        WMAX=MAX(WMAX,SQRT(DIF))
        NOPEN=NOPEN+1
      ENDDO

      RETURN
      END
