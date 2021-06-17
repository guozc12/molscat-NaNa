      SUBROUTINE SCWAVE(RBSEG,RESEG,DRSEG,NSTEPS,NSEG,
     1                  WVEC,PSIAR,PSIAI,PSIB,WORK,
     1                  W,SR,SI,EVEC,U,L,N,NSQ,NOPEN,NB,
     2                  ICHAN,IREC,IPRINT)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3

C  CODE WRITTEN BY GC McBane AND ADAPTED FOR USE IN MOLSCAT BY CR Le Sueur
C  NOV 2016
      USE potential
      IMPLICIT NONE
C  CONSTRUCT ASYMPTOTIC WAVEFUNCTION FROM DESIRED INITIAL CHANNEL AND S-MATRIX
C  INITIAL PSI IS RETURNED IN PSIAR (REAL PART) AND PSIAI (IMAG PART),
C  BOTH OF LENGTH N
C
      DOUBLE PRECISION RBSEG,RESEG,DRSEG,WVEC,PSIAR,PSIAI,PSIB,
     1                 WORK,W,SR,SI,EVEC,U
      DIMENSION RBSEG(NSEG),RESEG(NSEG),DRSEG(NSEG)
      DIMENSION WVEC(N),PSIAR(N),PSIAI(N),PSIB(N),WORK(N),W(N,N),
     1          SR(N,N),SI(N,N),EVEC(N,N),U(N,N)
      INTEGER, INTENT(IN):: NSTEPS(NSEG),NSEG,L,N,NSQ,NB,NOPEN,ICHAN,
     1                      IREC,IPRINT
      DIMENSION L(N),NB(N)

C  COMMON BLOCK FOR INPUT/OUTPUT CHANNEL NUMBERS
      LOGICAL PSIFMT
      INTEGER IPSISC,IWAVSC,IPSI,NWVCOL
      COMMON /IOCHAN/ IPSISC,IWAVSC,IPSI,NWVCOL,PSIFMT

      LOGICAL ASYMPK,LFIRST
      PARAMETER (ASYMPK=.FALSE.)

      DOUBLE PRECISION DR,R,REND,RSTART,RSTOP
      INTEGER IWREC,ITREC,IRREC,IIREC,NTSTPS,J,I,ISEG,NSTEP
      CHARACTER(2)  NCOL
      CHARACTER(60) F990

      REND=RESEG(NSEG)
      NTSTPS=SUM(NSTEPS(1:NSEG))

      WRITE(NCOL,'(I2)') 2*NWVCOL
      NCOL=ADJUSTR(NCOL)
      F990='(1P,E15.7,1X'//NCOL//'(E15.7E3:,1X),/(16X,'//
     1                     NCOL//'(E15.7E3:,1X)))'
      IF (ASYMPK) THEN  ! USE K-MATRIX VERSION
         CALL PSIK(N,NOPEN,NB,U,REND,WVEC,L,ICHAN,PSIAR) !K-MATRIX VERSION
         WRITE(*,*) ' CONSTRUCTING PSI(REND) USING K MATRIX'
         WRITE(*,*) ' ASYMPTOTIC WAVEFUNCTION AT REND = ', REND, ':'
         DO I = 1, N
            WRITE(*,*) PSIAR(I)    !K-MATRIX VERSION
         ENDDO
      ELSE  !S-MATRIX VERSION
         CALL PSIRH(N,NOPEN,NB,SR,SI,REND,WVEC,L,ICHAN,PSIAR,PSIAI)
         WRITE(*,*) ' CONSTRUCTING PSI(REND) USING S MATRIX'
         WRITE(*,*) ' ASYMPTOTIC WAVEFUNCTION AT REND = ', REND, ':'
         DO I = 1, N
            WRITE(*,*) PSIAR(I), PSIAI(I) !S-MATRIX VERSION
         ENDDO
      ENDIF

C  TRANSFORM ASYMPTOTIC WAVEFUNCTION TO PRIMITIVE BASIS
      IF (NCONST.NE.0 .OR. NRSQ.NE.0) THEN
        W=EVEC
        CALL DGEMV('N',N,N,1.0D0,W,N,PSIAR,1,0.0D0,PSIB,1)  ! REAL PART
        CALL DCOPY(N,PSIB,1,PSIAR,1)
        IF (.NOT.ASYMPK) THEN !MUST DO IMAGINARY PART TOO
          CALL DGEMV('N',N,N,1.0D0,W,N,PSIAI,1,0.0D0,PSIB,1) ! IMAG PART
          CALL DCOPY(N,PSIB,1,PSIAI,1)
        ENDIF
      ENDIF


C  GENERATE REAL AND IMAGINARY PARTS OF PSI(R) WITH SEPARATE CALLS TO EFPROP;
C  MUST MAKE TWO RUNS WRITE INTO DIFFERENT RECORDS OF UNIT 10.
      ITREC = IREC          ! NUMBER OF LAST RECORD ON UNIT IWAVSC (+1)

C  PROPAGATE REAL PART (PSIAR)
C  WORK RETURNS SUMPSI (NOT USEFUL HERE)
C  PSIB IS USED AS SCRATCH SPACE
      IRREC = NTSTPS+1      ! POSITION OF INITIAL RECORD TO BE WRITTEN TO UNIT IPSISC
      IF (.NOT.ASYMPK) IIREC = (NTSTPS+1)*2

      DO ISEG=NSEG,1,-1
        RSTART=RBSEG(ISEG)
        RSTOP=RESEG(ISEG)
        DR=DRSEG(ISEG)
        NSTEP=NSTEPS(ISEG)
        IWREC=ITREC
        LFIRST=ISEG.EQ.NSEG
        CALL EFPROP(N,RSTART,RSTOP,NSTEP,DR,PSIB,W,PSIAR,IWREC,
     1              WORK,IPRINT,IRREC,LFIRST)
        IF (.NOT.ASYMPK) THEN
C  PROPAGATE IMAG PART (PSIAI)
           IWREC = ITREC
           CALL EFPROP(N,RSTART,RSTOP,NSTEP,DR,PSIB,W,PSIAI,IWREC,
     1                 WORK,IPRINT,IIREC,LFIRST)
        ENDIF
        ITREC=ITREC-NSTEP
      ENDDO

C  COLLECT RESULTS FROM UNIT IPSISC AND WRITE SEQUENTIALLY ON UNIT IPSI
C  IN FORMAT COMPATIBLE WITH READING AS DOUBLE COMPLEX

      PSIAI=0.D0
      DO I = 1, NTSTPS+1
        READ(IPSISC,REC=I,ERR=998) R,PSIAR
        IF (.NOT.ASYMPK) READ(IPSISC,REC=NTSTPS+1+I,ERR=999) R,PSIAI
        IF (PSIFMT) THEN
          WRITE(IPSI,FMT=F990) R,(PSIAR(J),PSIAI(J),J=1,N)
        ELSE
          WRITE(IPSI) R,(PSIAR(J),PSIAI(J),J=1,N)
        ENDIF
      ENDDO

      RETURN
998   WRITE(6,*)'PSIAR',I
      STOP
999   WRITE(6,*)'PSIAI',NTSTPS+1+I
      STOP
      END