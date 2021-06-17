      SUBROUTINE DERMAT(IDER,W,N,R,P,VL,IV,CENT,
     1                  EP2RU,RSCALE,MXLAM,NHAM,IPRINT)
C  Copyright (C) 2020 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE potential
C
C  EVALUATES THE IDER'TH DERIVATIVE OF THE POTENTIAL AT RADIUS R
C  W = VCOUPL + VCENT
C  ORDER OF THE REAL SYMMETRIC MATRIX W IS N
C  THE FULL MATRIX IS COMPUTED
C  VL IS THE PREVIOUSLY COMPUTED MATRIX OF THE COUPLING POTENTIAL
C  IV IS AN INDEX ARRAY MAPPING P ONTO VL, SUCH THAT VL(I) IS
C        A COEFFICIENT TO MULTIPLY P(IV(I))
C  CENT(I) IS L*(L+1) FOR THE I-TH CHANNEL
C    (BUT VL ARRAY IS USED INSTEAD OF CENT IF NRSQ = 1)
C  EP2RU IS THE CONVERSION FACTOR FROM ENERGY IN EPSIL UNITS TO REDUCED ENERGY
C  IN (1/RUNIT**2) UNITS.
C  EP2RU = MUNIT*URED*RUNIT**2*EP2CM/BFCT, CONCEPTUALLY 2*MU/HBAR^2 IN
C  APPROPRIATE UNITS
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE RSAVE
C
      DIMENSION W(N,N),VL(1),IV(1),CENT(N),P(MXLAM),IDUM1(1)
C
C  COMMON BLOCK FOR DERIVATIVES
      LOGICAL NUMDER
      COMMON /DERIVS/ NUMDER
C
C  STEP SIZE FOR NUMERICAL DERIVATIVES: SHOULD REALLY BE ADJUSTABLE
      DATA DEL / 1.D-3 /
C
      IF (IDER.EQ.1) RSQ=-2.D0/R**3
      IF (IDER.EQ.2) RSQ=+6.D0/R**4

      RSQ=MIN(RSQ,1.D16)
C
C  COMPUTE THE RADIAL PARTS OF THE POTENTIAL
C  IDUM1 AND IDUM2 ARE DUMMY ARGUMENTS HERE.
C
      IF (NUMDER) THEN
C
C  NUMERICAL DERIVATIVE OPTION.
C  NOTE THAT IF IDER = 2 THIS ASSUMES THAT
C  THE POTENTIAL ITSELF IS ALREADY IS ALREADY IN THE FIRST
C  MXLAM ELEMENTS OF P. THIS IS NOT TRUE IF DERMAT HAS BEEN
C  CALLED MORE RECENTLY THAN WAVMAT, SO THE IDER = 2 CALL
C  MUST PRECEDE THE IDER = 1 CALL.
C
C  FIRST SEE WHETHER DERMAT HAS BEEN CALLED BEFORE FOR THIS
C  VALUE OF R, AND IF SO SKIP POTENTIAL EVALUATIONS
C
        IPDIM=MXLAM+NCONST+NRSQ
C
        IF (R.NE.RSAVE) THEN
          RSAVE=R
          RR=R-DEL
          CALL POTENL(0,MXLAM,IDUM1,RR*RSCALE,P(IPDIM+1),IDUM2,IPRINT)
          RR=R+DEL
          CALL POTENL(0,MXLAM,IDUM1,RR*RSCALE,P(2*IPDIM+1),IDUM2,IPRINT)
        ENDIF
C
        DO 10 I=1,MXLAM
          P1=P(IPDIM+I)
          P2=P(2*IPDIM+I)
          IF (IDER.EQ.1) P(I) = (P2-P1)/(2.D0*DEL)
   10     IF (IDER.EQ.2) P(I) = (P2+P1-2.D0*P(I))/(DEL*DEL)
C
      ELSE
        CALL POTENL(IDER,MXLAM,IDUM1,R*RSCALE,P,IDUM2,IPRINT)
      ENDIF
C
C  CONVERT POTENTIAL P FROM EPSIL ENERGY UNITS TO REDUCED UNITS
C
      DO I=1,MXLAM
        P(I)=EP2RU*P(I)
      ENDDO
C
C  EXTEND ARRAY WITH ANY CONSTANT TERMS IN HAMILTONIAN (ZERO DERIV)
C
      DO I=1,NCONST
        P(MXLAM+I)=0.D0
      ENDDO
C
C  PROCESS ANY POTENTIAL SCALING FACTOR IN SCALAM
C
      CALL SCAPOT(P,MXLAM)
C
C  NEXT LINE NEEDED ONLY FOR BOUND, WHICH DOES NOT AT PRESENT (12/19)
C  USE PROPAGATORS THAT CALL DERMAT
C     CALL PERTRB(R*RSCALE,P,NHAM,0)
C
C  EXTEND ARRAY WITH ANY TERMS THAT MULTIPLY 1/R**2
C
      IF (NRSQ.GT.0) THEN
        DO I=1,NRSQ
          P(MXLAM+NCONST+I)=RSQ
        ENDDO
      ENDIF
C
      CALL WAVVEC(VL,P,IV,W,N,NHAM)
C
C  NOW COMPUTE THE DIAGONAL CONTRIBUTIONS W(I,I).
C
      IF (NRSQ.EQ.0) THEN
        DO 20 I=1,N
          W(I,I) = W(I,I) + RSQ*CENT(I)
   20   CONTINUE
      ENDIF

      RETURN
      END
