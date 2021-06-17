      SUBROUTINE GNHAM(IPRINT,ITYPE,NLABV,MXLAM,NHAM,LAM)
C  Copyright (C) 2020 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE potential
      IMPLICIT NONE
      INTEGER, INTENT(IN)    :: IPRINT,ITYPE,NLABV,LAM(1)
      INTEGER, INTENT(INOUT) :: MXLAM
      INTEGER, INTENT(OUT)   :: NHAM
C
C  CR Le Sueur/G McBane 09-10-18: REPLACED VERY SIMPLE CHECKING OF LAMBDA
C                                 ARRAY WITH MORE SOPHISTICATED ONE WRITTEN
C                                 BY G McBane
C
C  THIS ROUTINE RETURNS THE VALUES ON NHAM AND NVLBLK,
C  TAKING ACCOUNT OF THE SETTING OF IVLFL,
C  WHICH CONTROLS 'NON-TRIVIAL' USE OF THE IV ARRAY.
C
C  IT ALSO CHECKS THE ARRAY LAMBDA OF POTENTIAL SYMMETRY INDICES
C  FOR DUPLICATED SETS (WHICH DO NOT WORK AFTER MOLSCAT V9)
C
C  ON ENTRY: IPRINT CONTROLS PRINT LEVEL
C            ITYPE IS INTERACTION TYPE
C            NLABV IS NUMBER OF LABELS FOR EACH SYMMETRY IN POTENTIAL
C            MXLAM IS NUMBER OF TERMS IN POTENTIAL EXPANSION
C            NHAM IS UNSET
C            LAM IS INTEGER ARRAY OF SYMMETRY LABELS,
C            CONCEPTUALLY OF DIMENSION (MXLAM,NLABV).
C  ON EXIT:  NHAM IS THE NUMBER OF BLOCKS OF THE VL ARRAY USED TO
C            CONSTRUCT INTERACTION MATRICES, INCLUDING ANY FOR NCONST
C            AND NRSQ
C            NVLBLK (IN MODULE potential) IS TOTAL NUMBER OF BLOCKS OF
C            VL ARRAY, INCLUDING ANY FOR EXTRA OPERATORS USED BY MULTOP.
C
      LOGICAL OKAY,LTEST,LUNSPC
      INTEGER ITYP,IADD,IDPCHK,IEXTRA,NPCOEF,MAXL,NQ,NDUP,I,NPQL
      COMMON /VLFLAG/ IVLFL
      INTEGER IVLFL
C  COMMON BLOCK FOR COMMUNICATING WITH SURBAS OR BAS9IN
      COMMON /NPOT  / NVLP
      INTEGER NVLP
C  CHARACTER VARIABLE FOR PLURALS
      CHARACTER(1) PLUR(2)
      DATA PLUR /' ','S'/
C
C  CALLED FROM DRIVER AFTER BASIN (OR IOSBIN) AND POTENL INITIALIZATION
C
      ITYP=MOD(ITYPE,10)
      IADD=ITYPE-ITYP

      IF (ITYP.EQ.0) THEN
        WRITE(6,*) ' *** IVCHK.  ILLEGAL ITYPE',ITYPE
        STOP
      ENDIF

C  COUNT NUMBER OF BLOCKS OF VL ARRAY NEEDED FOR EXTRA OPERATORS
      NEXBLK=0
      IF (ITYP.EQ.9 .AND. NEXTRA.GT.0) THEN
        LUNSPC=.TRUE.
        DO IEXTRA=1,NEXTRA
          IF (NEXTMS(IEXTRA).EQ.0) THEN
            IF (.NOT.LUNSPC) THEN
              WRITE(6,*) ' EXTRA OPERATOR',IEXTRA,'APPEARS TO',
     1                   ' USE NO BLOCKS OF COUPLING MATRIX'
              WRITE(6,*) ' FIX AND RECOMPILE'
              STOP
            ENDIF
          ELSE
            LUNSPC=.FALSE.
            NEXBLK=NEXBLK+NEXTMS(IEXTRA)
          ENDIF
        ENDDO

        IF (LUNSPC) THEN
          DO IEXTRA=1,NEXTRA
            NEXTMS(IEXTRA)=1
          ENDDO
          NEXBLK=NEXTRA
        ENDIF
      ENDIF

      IF (IVLFL.LE.0) THEN
        NPCOEF=MXLAM

      ELSE

        IF (ITYP.EQ.2 .OR. ITYP.EQ.7) THEN
          NPQL=3
          IF (ITYP.EQ.7) NPQL=5
          MAXL=0
          DO I=1,MXLAM
            MAXL=MAX(MAXL,LAM(NPQL*(I-1)+1))
          ENDDO
          NPCOEF=MAXL+1
        ELSEIF (IADD.EQ.100) THEN
          NPCOEF=1
        ELSEIF (ITYP.EQ.8) THEN
          NPCOEF=NVLP
          WRITE(6,9380) NPCOEF
 9380     FORMAT('  SURFACE FOURIER COMPONENTS'/'  NPCOEF =',I2,
     1           ' FROM SURBAS')
        ELSEIF (ITYP.EQ.9) THEN
          NPCOEF=NVLP
          WRITE(6,9390) NPCOEF
 9390     FORMAT('  ONLY',I4,' POTENTIAL COEFFICIENTS CONTRIBUTE TO',
     1           ' EACH ELEMENT OF INTERACTION MATRIX')
        ELSE
          NPCOEF=MXLAM
        ENDIF
        IF (MXLAM.LE.1) THEN
          NPCOEF=1
          MXLAM=ABS(MXLAM)
          RETURN
        ENDIF

        NQ=NLABV

        NDUP = IDPCHK(NQ,MXLAM,LAM)
        IF (NDUP.NE.0) THEN
          WRITE(6,*) ' *** ERROR *** - FOUND ',NDUP,
     1               ' DUPLICATE SYMMETRIES IN LAMBDA'
          WRITE(6,*) '               IVCHK TERMINATING'
          STOP
        ENDIF
        IF (IPRINT.GE.3)
     1    WRITE(6,*) ' NO DUPLICATED SETS OF INDICES IN LAMBDA ARRAY'

      ENDIF

      NHAM=NPCOEF+NCONST+NRSQ

      NVLBLK=NHAM+NEXBLK

      IF (IPRINT.GE.1) THEN
        WRITE(6,9980) NPCOEF
 9980   FORMAT('  INTERACTION MATRIX USES ',I3,' BLOCKS OF VL ARRAY',
     1         ' FOR R-DEPENDENT TERMS IN POTENTIAL')
        IF (NCONST.GT.0) WRITE(6,9981) NCONST,
     1                                 'CONSTANT    TERMS IN POTENTIAL'
        IF (NRSQ.GT.0)   WRITE(6,9981) NRSQ,'CENTRIFUGAL OPERATOR'
        IF (NEXTRA.GT.0) WRITE(6,9982) NEXBLK,NEXTRA,PLUR(MIN(NEXTRA,2))
        IF (NVLBLK.NE.NPCOEF) WRITE(6,9983) NVLBLK
 9981   FORMAT(26X,I3,20X,'FOR ',A)
 9982   FORMAT(26X,I3,20X,'FOR ',I3,' EXTRA OPERATOR',A)
 9983   FORMAT(/'  IN TOTAL:',I3,' BLOCKS OF VL ARRAY ARE USED'/)
      ENDIF

      RETURN
      END
