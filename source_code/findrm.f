      SUBROUTINE FINDRM(W,N,RSTART,RTURN,P,VL,
     1                  IV,ERED,EINT,CENT,
     2                  DIAG,DIAG2,XK,PHASE,MXLAM,NHAM,
     3                  EP2RU,CM2RU,RSCALE,IRMSET,ITYPE,IPRINT)
C  Copyright (C) 2020 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      COMMON /CNTROL/ CDRIVE
      CHARACTER(1) CDRIVE
C
C  SUBROUTINE TO FIND A SUITABLE STARTING POINT FOR PROPAGATION
C
C  FIND CLASSICAL TURNING POINT OF DIAGONAL POTENTIAL
C  IN LOWEST-LYING CHANNEL.
C  START FROM A GUESS BASED ON THE CENTRIFUGAL POTENTIAL
C
C  CR Le Sueur MARCH 2017: ALTERED TO FIND CLASSICAL TURNING POINT OF LOWEST
C              ADIABAT INSTEAD OF DIAGONAL POTENTIAL
C
      DIMENSION W(N,N),P(MXLAM),VL(1),IV(1),EINT(N),CENT(N),DIAG(N),
     1          DIAG2(N),XK(N),PHASE(N)

      RMIN=RSTART
      RTURN=1.D30
      NOPEN=0
      DO 80 I=1,N
        DIF=ERED-EINT(I)
        IF (DIF.LT.0.D0) GOTO 80
        NOPEN=NOPEN+1
        RCENT=SQRT(CENT(I)/DIF)
        RCENT=MAX(RCENT,RMIN)
        RTURN=MIN(RTURN,RCENT)
   80 CONTINUE
C
C  FOR SURFACE SCATTERING, OVERRIDE THE CENTRIFUGAL GUESS
C  FOR BOUND STATES ALSO
      IF (ITYPE.EQ.8 .OR. CDRIVE.NE.'M') RTURN=RMIN
C
      IF (NOPEN.LE.0 .AND. CDRIVE.EQ.'M') THEN
        GOTO 300
      ENDIF
C
      ITRY=0
   90 RSTART=RTURN
      IF (ITRY.GT.25) GOTO 140

      CALL WAVMAT(W,N,RSTART,P,VL,IV,ERED,EINT,CENT,EP2RU,CM2RU,
     1            RSCALE,DIAG,MXLAM,NHAM,IPRINT)
      CALL DIAGVL(W,N,N,DIAG)
C
C  FIND LOWEST CHANNEL
C
      IK=1
      V1=DIAG(1)
      DO 100 I=1,N
        IF (DIAG(I).GE.V1) GOTO 100
        IK=I
        V1=DIAG(I)
  100 CONTINUE
C
      RTURN=0.999D0*RSTART
      DO 120 II=1,100
        CALL WAVMAT(W,N,RTURN,P,VL,IV,ERED,EINT,CENT,EP2RU,CM2RU,
     1              RSCALE,DIAG2,MXLAM,NHAM,IPRINT)
        CALL DIAGVL(W,N,N,DIAG2)
C
C  CHECK THAT CHANNEL IK IS STILL LOWEST, AND CALCULATE ALL
C  THE DERIVATIVES FOR USE LATER
C
        V2=DIAG2(IK)
        DO 110 I=1,N
          XK(I)=(DIAG2(I)-DIAG(I))/(RTURN-RSTART)
          DIAG(I)=DIAG2(I)
          IF (DIAG(I).LT.V2) THEN
            ITRY=ITRY+1
            GOTO 90
          ENDIF
  110   CONTINUE
        DV1=XK(IK)
C
        IF (IPRINT.GE.13) WRITE(6,602) RTURN,V2
  602   FORMAT('  FINDRM: AT R =',F8.4,' SMALLEST REDUCED V-E IS',F11.2)
C
C  THERE MIGHT BE A WELL BEHIND THE BARRIER MAXIMUM.
C  PROVIDED IT IS ABOVE THE SCATTERING ENERGY, JUMP OVER IT
C  AND TRY AGAIN. ONLY DO THIS ONCE, THOUGH.
C
        IF (DV1.GE.0.D0) THEN
          IF (V2.GT.0.D0) THEN
            ITRY=ITRY+10
            IF (ITRY.LT.20) THEN
              RTURN=2.D0*RTURN
              GOTO 90

            ELSE
              GOTO 140

            ENDIF
          ELSE
            ITRY=ITRY+5
            RTURN=0.9D0*RTURN
            GOTO 90

          ENDIF
        ENDIF

        RSTART=RTURN
        V1=V2
        DR=-V1/DV1
        IF (DR.LT.-0.3D0*RTURN .AND. ITYPE.NE.8) DR=-0.3D0*RTURN
        RTURN=RTURN+DR
        IF (ITRY.GT.25 .OR. DR.GT.1.D3) GOTO 140
        IF (RTURN.LE.0.D0 .AND. ITYPE.NE.8) GOTO 140

        IF (ABS(DR/RTURN).LE.1.D-3) GOTO 160

  120 CONTINUE
C
C  ARRIVE HERE IF DR BECOMES HUGE, RTURN BECOMES NEGATIVE,
C  OR THERE IS NO CONVERGENCE IN 100 NEWTON-RAPHSON ITERATIONS.
C  IF THIS HAPPENS, JUST USE THE INPUT VALUE OF RMIN
C
  140 IF (IPRINT.GE.3) WRITE(6,*) ' *** FINDRM. UNABLE TO FIND ',
     1                            'CLASSICAL TURNING POINT'
C
C  ARRIVE HERE IF WE HAVE CONVERGED ON A CLASSICAL TURNING POINT
C  DIAG ARRAY CONTAINS DIAGONAL ELEMENTS
C
  160 IF (IPRINT.GE.9) WRITE(6,603) RTURN
  603 FORMAT('  INNER CLASSICAL TURNING POINT AT R =',F8.4)
C
C  SPECIAL CASE: CALLED TO FIND RTURN ONLY
C
      IF (IRMSET.LE.0) THEN
        RSTART=RMIN
        RETURN
      ENDIF
C
C  FIND NEW RSTART BY INTEGRATING PHASE INTEGRALS INWARDS.
C  WE WANT RSTART SUCH THAT
C  INT(RSTART,RTURN) SQRT(E-V) DR = 2.303 * IRMSET
C  TRY TO DO IT IN NSTEP ROUGHLY EQUAL STEPS
C
      NSTEP=3+IRMSET/3
C
      TARGET=2.303D0*DBLE(IRMSET)
      DR=1.5D0*TARGET/SQRT(ABS(XK(IK)))/DBLE(NSTEP)
C
      IF (IPRINT.GE.13) WRITE(6,604) NSTEP,TARGET
  604 FORMAT('  USE',I3,' STEPS TO SEEK DISTANCE SUCH THAT ESTIMATED',
     1       ' PHASE INTEGRAL IS AT LEAST',F6.2,' IN EVERY CHANNEL')
      DO 210 I=1,N
        PHASE(I)=0.D0
        XK(I)=SQRT(ABS(DIAG(I)))
  210 CONTINUE
C
  220 CONTINUE
C
      DO 240 ISTEP=1,NSTEP
        RNEXT=RSTART-DR
        IF (RNEXT.LT.0.D0 .AND. ITYPE.NE.8) THEN
          RSTART=0.D0
          IF (IPRINT.GE.1) THEN
            WRITE(6,*) ' *** FINDRM. REACHED ORIGIN WHILE '//
     2                 ' ACCUMULATING PHASE INTEGRAL.'
            WRITE(6,*) '     PROPAGATION WILL START AT ORIGIN.'
          ENDIF
          RETURN
        ENDIF
C
        CALL WAVMAT(W,N,RNEXT,P,VL,IV,ERED,EINT,CENT,EP2RU,CM2RU,
     1              RSCALE,DIAG,MXLAM,NHAM,IPRINT)
        CALL DIAGVL(W,N,N,DIAG)
        DRNEXT=0.D0
        PHMIN=1.D30
        DO 230 I=1,N
          IF (DIAG(I).LE.0.D0) THEN
            IF (IPRINT.GE.3) THEN
              WRITE(6,*) ' *** FINDRM. INNER CLASSICALLY ALLOWED '//
     2                   'REGION ENCOUNTERED'
              WRITE(6,*) '     WHILE INTEGRATING INWARDS FROM '//
     1                   'TURNING POINT.'
            ENDIF
            GOTO 260

          ENDIF
          V1=SQRT(DIAG(I))
          V2=0.5D0*(V1+XK(I))
          PHASE(I)=PHASE(I)+DR*V2
          PHMIN=MIN(PHMIN,PHASE(I))
          DRNEXT=MAX(DRNEXT,(TARGET-PHASE(I))/V1)
          XK(I)=V1
  230   CONTINUE
C
        RSTART=RNEXT
        IF (ISTEP.LT.NSTEP) DR=DRNEXT/DBLE(NSTEP-ISTEP)
C
        IF (IPRINT.GE.13) WRITE(6,605) ISTEP,RNEXT,DIAG(IK),PHMIN
  605   FORMAT('  FINDRM: STEP',I3,' TO R =',F8.4,', SMALLEST REDUCED ',
     1         ' V-E =',F11.2,', SMALLEST PHASE INTEGRAL =',F6.2)
C
        IF (DRNEXT.LE.0.D0) GOTO 250
C
C  IF THE STEP SIZE SEEMS EXCESSIVE, TRY ACCUMULATING THE
C  PHASE INTEGRAL MORE CAUTIOUSLY
C
        IF (ISTEP.LT.NSTEP .AND. ITYPE.NE.8 .AND.
     1      DR.GT.0.5D0*RSTART .AND. DR.GT.0.5D0*RMIN) THEN
          DR=0.02D0*RSTART
          GOTO 220

        ENDIF
C
  240 CONTINUE
C
  250 IF (IPRINT.GE.9) WRITE(6,606) RSTART
  606 FORMAT('  RADIAL PROPAGATION WILL START AT R =',F8.4)
      RETURN
C
C  ARRIVE HERE IF THE INWARDS SEARCH ENTERED A CLASSICALLY ALLOWED
C  REGION. TRY TO FIND A BETTER STARTING POINT AND LOOK FOR THE
C  INNER TURNING POINT
C
  260 DR=0.1D0*RNEXT
      RTURN=RNEXT-DR
      DO 290 II=1,9
        CALL WAVMAT(W,N,RTURN,P,VL,IV,ERED,EINT,CENT,EP2RU,CM2RU,
     1              RSCALE,DIAG,MXLAM,NHAM,IPRINT)
        CALL DIAGVL(W,N,N,DIAG)
        DO 270 I=1,N
          IF (DIAG(I).LE.0.D0) GOTO 280

  270   CONTINUE
        ITRY=ITRY+10
        GOTO 90

  280   RTURN=RTURN-DR
  290 CONTINUE
      IF (IPRINT.GE.1) WRITE(6,*) ' *** FINDRM. UNABLE TO FIND INNER ',
     1                            'CLASSICAL TURNING POINT. ',
     2                            'PROPAGATION WILL START AT ORIGIN'
      RSTART=0.D0
      RETURN
C
  300 RSTART=RMIN
      RTURN=2.D0*RMIN
      IF (IPRINT.GE.3) WRITE(6,608) ERED
  608 FORMAT(2X,'*** FINDRM. NO OPEN CHANNELS AT ENERGY = ',1PG17.10,1X,
     1       'CM-1'/14X,'RSTART SET TO RMIN AND RTURN  SET TO 2*RMIN')
      RETURN
C
      END