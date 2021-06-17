      SUBROUTINE MGPROP(N,MXLAM,NHAM,
     1                  Y,U,VL,IV,EINT,CENT,P,DG,
     2                  RSTART,RSTOP,NSTEP,DR,NODES,
     3                  ERED,EP2RU,CM2RU,RSCALE,IPRINT)
C  This subroutine is part of the MOLSCAT, BOUND and FIELD suite of programs
C
C  31 AUG 2012 G. MCBANE.
C
C  CORE PROPAGATION ROUTINE FOR SYMPLECTIC LOG-DERIVATIVE PROPAGATOR OF
C  MANOLOPOULOS AND GRAY, JCP 102, 9214 (1995). THIS IS A COMPUTATIONAL
C  CORE ROUTINE, AND NEEDS TO BE CONNECTED TO THE SURROUNDING PROGRAM BY
C  AN INTERFACE ROUTINE THAT INITIALIZES THE LOG-DERIVATIVE (Y) AND COUPLING (U)
C  MATRICES AND DEFINES THE SCALAR ESHIFT FOR THIS PARTICULAR PROPAGATION.
C  IF IREAD IS TRUE, THE FILE POINTER ON ISCRU NEEDS TO BE SITTING AT THE SAME
C  PLACE IT WAS ON THE CALL WHEN IWRITE WAS TRUE.

C  TESTED IN MOLSCAT ON Ne-CO COLLISIONS AT J=0, 22 AUG 2012;
C  SEE NOTEBOOK PAGE CI118
C  TESTED IN BOUND ON Ne-CO BOUND STATES AT J=0; SEE CI121
C  NODE COUNT INITIALLY IMPLEMENTED ON TRIAL BASIS; JUSTIFICATION
C  FOR ITS ALGORITHM WAS PROVIDED BY D. MANOLOPOULOS IN A PRIVATE NOTE
C  TO GCM AND JMH IN SEPT 2012

C  OPTIMUM STEP SIZE SHOULD BE LARGER THAN THAT FOR JOHNSON OR
C  MANOLOPOULOS LD PROPAGATORS, OTHERWISE THIS IS NOT USEFUL!  REQUIRES
C  MSYMP-1 COUPLING MATRIX EVALUATIONS AND MATRIX INVERSIONS PER STEP
C  IF A(MSYMP)=0, AND MSYMP INVERSIONS AND POTENTIAL EVALUATIONS IF
C  A(MSYMP).NE.0.  CS4 PROPAGATOR OF THE PAPER, WITH
C  MSYMP=5 AND A(5)=0, USES 4 INVERSIONS AND 4 COUPLING MATRIX EVALUATIONS PER
C  SECTOR.  MA5 PROPAGATOR OF THE PAPER, MSYMP=6, USES 6 INVERSIONS AND 6
C  COUPLING MATRIX EVALUATIONS PER SECTOR.  BY COMPARISON, THE
C  DAPROP (MANOLOPOULOS) AND LDPROP (JOHNSON)
C  LOG-DERIVATIVE PROPAGATORS USE 3 INVERSIONS AND EVALUATIONS AT THE FIRST
C  ENERGY, AND DAPROP USES ONLY 2 AT SUBSEQUENT ENERGIES.

C  ONLY THE COUPLING MATRIX W (CALLED U HERE) CAN
C  USEFULLY BE SAVED FROM ONE ENERGY TO THE NEXT; THE NUMBER OF
C  INVERSIONS DOES NOT CHANGE AT SUBSEQUENT ENERGIES.

C  MOST INPUT VARIABLES HAVE THE USUAL MOLSCAT DEFINITIONS, AS WITH
C  OTHER PROPAGATORS (LDPROP, DAPROP, ETC.).  INPUT MGSEL CHOOSES
C  SYMPLECTIC PROPAGATOR; MGSEL=1 GIVES CS4 4TH-ORDER PROPAGATOR, WHILE
C  MGSEL=2 GIVES MA5 5TH-ORDER PROPAGATOR.  THE ONLY OUTPUTS ARE Y
C  (LOG-DERIVATIVE MATRIX AT RSTOP) AND NODES.


      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C  COMMON BLOCK FOR CONTROL OF USE OF PROPAGATION SCRATCH FILE
      LOGICAL IREAD,IWRITE
      COMMON /PRPSCR/ ESHIFT,ISCRU,IREAD,IWRITE

      DIMENSION U(N,N),Y(N,N),P(MXLAM),VL(2),IV(2),EINT(N),CENT(N),DG(N)

C  PROPAGATOR CONSTANTS.  MAXMS WILL NEED TO INCREASE IF HIGHER-ORDER
C  PROPAGATORS ARE INSTALLED.  6 IS ADEQUATE FOR BOTH CS4 AND MA5.
      INTEGER MAXMS
      PARAMETER (MAXMS = 6)
      INTEGER MSYMP
      DOUBLE PRECISION A(MAXMS), B(MAXMS)
      SAVE ! VALUE OF MGSEL CHOSEN IN CALL TO ENTRY POINT MGISEL

C  OBTAIN MSYMP AND PROPAGATOR CONSTANTS A AND B
      CALL SYMSEL(MGSEL, A, B, MSYMP, MAXMS)
C  INITIALIZE SCALARS
      H=DR
      NODES = 0

C  PROPAGATE
      DO ISTEP = 1,NSTEP        ! LOOP OVER SECTORS
         R = RSTART+(ISTEP-1)*H
         DO K = 1, MSYMP        ! LOOP OVER SUBSTEPS WITHIN SECTOR

C  OBTAIN W MATRIX.  IF A(MSYMP)=0, THEN FINAL W FROM LAST SECTOR EQUALS W FOR FIRST SUBSTEP OF THIS
C  SECTOR, AND W CAN BE REUSED.
            IF (K.NE.1 .OR. ISTEP.EQ.1 .OR. A(MSYMP).NE.0.0D0) THEN
               IF (IREAD) THEN
                  READ(ISCRU) U
                  DO I = 1,N
                     U(I,I)=U(I,I)-ESHIFT
                  ENDDO
               ELSE
                  CALL WAVMAT(U,N,R,P,VL,IV,ERED,EINT,CENT,EP2RU,CM2RU,
     1                        RSCALE,DG,MXLAM,NHAM,IPRINT)
               ENDIF
               IF (IWRITE) WRITE(ISCRU) U
            ENDIF
C  U NOW CONTAINS W MATRIX

C  1ST STEP OF EQN 43 FROM MG PAPER: X_K = Y_K-1 + B_K*W*H, LOWER TRIANGLE ONLY
            DO J = 1, N
               CALL DAXPY(N+1-J, B(K)*H, U(J,J), 1, Y(J,J), 1)
            ENDDO
C  Y MATRIX NOW CONTAINS X_K
C
C  2ND STEP OF EQN 43, USING ALTERNATIVE FORM OF EQN 44
            IF (A(K).NE.0.0D0) THEN
               DO J = 1, N
                  CALL DSCAL(N+1-J,A(K)*H,Y(J,J),1)
                  Y(J,J)=Y(J,J)+1.0D0
               ENDDO
C  Y NOW CONTAINS (I+A_K X_K DR)
               CALL SYMINV(Y,N,N,NCU)
C  NODE COUNT: ADD TO TOTAL IF STEPPING "FORWARD", SUBTRACT IF BACKWARD
               IF (A(K).GE.0.0D0) THEN
                  NODES = NODES+NCU
               ELSE
                  NODES = NODES-NCU
               ENDIF
C  Y NOW CONTAINS (I+A_K X_K DR)^{-1}
               DO J = 1, N
                  CALL DSCAL(N+1-J,-1.0D0,Y(J,J),1)
                  Y(J,J)=Y(J,J)+1.0D0
               ENDDO
               D1 = 1.0D0/(A(K)*H)
               DO J = 1, N
                  CALL DSCAL(N+1-J,D1,Y(J,J),1)
               ENDDO
C  ELSE A(K)=0, SO NOTHING TO DO: Y = X
            ENDIF
C  Y NOW CONTAINS Y_K

C  3RD STEP OF EQN 43: UPDATE R
            R = R + A(K)*H
         ENDDO                 ! K LOOP

      ENDDO                    ! ISTEP LOOP

C  FILL IN UPPER TRIANGLE OF Y MATRIX
      CALL DSYFIL('U', N, Y, N)
      RETURN
C========================================================== MGISEL
      ENTRY MGISEL(IMGSEL)
C  THIS ENTRY POINT USED BY IFMSG TO SET WHICH SYMPLECTIC PROPAGATOR IS
C  TO BE USED

      IF (IMGSEL.EQ.4) THEN
        MGSEL=1
      ELSEIF (IMGSEL.EQ.5) THEN
        MGSEL=2
      ELSE
        WRITE(6,*) ' *** ERROR *** ONLY CS4 AND MA5 SYMPLECTIC '//
     1             'PROPAGATORS CODED AT THE MOMENT'
        STOP
      ENDIF
      RETURN

      END
C========================================================== SYMSEL
      SUBROUTINE SYMSEL(MGSEL, A, B, MSYMP, MAXMS)
C  This subroutine is part of the MOLSCAT, BOUND and FIELD suite of programs
C
C  G. C. MCBANE, 31 AUG 2012
C
C  DEFINE CONSTANTS FOR SYMPLECTIC PROPAGATORS
C  FROM MANOLOPOULOS AND GRAY, JCP 102, 9214 (1995).
C  INPUT MAXMS IS ALLOCATED SIZE OF A AND B VECTORS.
C  INPUT MGSEL CHOOSES PROPAGATOR:
C    MGSEL=1 GIVES CS4,
C    MGSEL=2 GIVES MA5.
C  OUTPUT MSYMP IS CALLED M IN THE PAPER.
C  OUTPUTS A AND B ARE ARRAYS FROM TABLE I OF PAPER.

      IMPLICIT NONE
      INTEGER MGSEL, MAXMS, MSYMP, I
      DOUBLE PRECISION A(MAXMS), B(MAXMS)

C  CONSTANTS FOR CS4 PROPAGATOR
      INTEGER MCS4
      PARAMETER (MCS4 = 5)
      DOUBLE PRECISION ACS4(MCS4), BCS4(MCS4)
      DATA ACS4 /0.20517766154229D0,
     1           0.40302128160421D0,
     2          -0.12092087633891D0,
     3           0.51272193319241D0,
     4           0.0D0/
      DATA BCS4 /0.061758858135626D0,
     1           0.33897802655364D0,
     2           0.61479130717558D0,
     3          -0.14054801465937D0,
     4           0.12501982279453D0 /

C  CONSTANTS FOR MA5 PROPAGATOR
      INTEGER MMA5
      PARAMETER (MMA5 = 6)
      DOUBLE PRECISION AMA5(MMA5), BMA5(MMA5)
      DATA AMA5 /0.33983962583911D0,
     1          -0.088601336903027D0,
     2           0.58585647682596D0,
     3          -0.60303935653649D0,
     4           0.32358079655470D0,
     5           0.44236379421975D0/

      DATA BMA5 /0.11939002928757D0,
     1           0.69892737038248D0,
     2          -0.17131235827160D0,
     3           0.40126950225135D0,
     4           0.010705081848236D0,
     5          -0.058979625498031D0/

C  SELECT CONSTANTS FOR DESIRED PROPAGATOR.
C  MGSEL OPTIONS ARE 1 FOR CS4 AND 2 FOR MA5.


      IF (MGSEL.EQ.1) THEN  !CS4
         IF (MAXMS.LT.MCS4) THEN
            WRITE(*,*) 'A AND B ARRAYS NOT LARGE ENOUGH IN SYMSEL'
            WRITE(*,*) 'MAXMS = ', MAXMS
            WRITE(*,*) 'MCS4 = ', MCS4
            STOP
         ENDIF
         MSYMP = MCS4
         DO I = 1, MSYMP
            A(I) = ACS4(I)
            B(I) = BCS4(I)
         ENDDO

      ELSEIF (MGSEL.EQ.2) THEN !MA5
         IF (MAXMS.LT.MMA5) THEN
            WRITE(*,*) 'A AND B ARRAYS NOT LARGE ENOUGH IN SYMSEL'
            WRITE(*,*) 'MAXMS = ', MAXMS
            WRITE(*,*) 'MMA5 = ', MMA5
            STOP
         ENDIF
         MSYMP = MMA5
         DO I = 1, MSYMP
            A(I) = AMA5(I)
            B(I) = BMA5(I)
         ENDDO

      ELSE
         WRITE(*,*) 'MGPROP: ILLEGAL VALUE OF MGSEL = ', MGSEL
         STOP

      ENDIF
      RETURN
      END
