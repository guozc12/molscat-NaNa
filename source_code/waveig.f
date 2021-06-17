      SUBROUTINE WAVEIG(W, EIGNOW, SCR1, RNOW, NCH, P, MXLAM, VL,
     1                  IV, EP2RU, CM2RU, RSCALE, ERED, EINT, CENT,
     2                  NHAM, IPRINT)
C  This subroutine is part of the MOLSCAT, BOUND and FIELD suite of programs
*  THIS SUBROUTINE FIRST SETS UP THE WAVEVECTOR MATRIX AT RNOW
*  THEN OBTAINS ITS EIGENVALUES
*  WRITTEN BY:  MILLARD ALEXANDER
*  CURRENT REVISION DATE: 25-SEPT-87
* ----------------------------------------------------------------
*  VARIABLES IN CALL LIST:
*  W:           MATRIX OF MAXIMUM ROW DIMENSION NCH USED TO STORE
*               WAVEVECTOR MATRIX
*  EIGNOW:      ON RETURN:  ARRAY CONTAINING EIGENVALUES OF WAVEVECTOR M
*  SCR1:        SCRATCH VECTOR OF DIMENSION AT LEAST NCH
*  RNOW:        VALUE OF INTERPARTICLE SEPARATION AT WHICH WAVEVECTOR MA
*               IS TO BE EVALUATED
*  NCH:         NUMBER OF CHANNELS
*  SUBROUTINES CALLED:
*     WAVMAT:         DETERMINES WAVEVECTOR MATRIX
*     DIAGVL:         NAG ROUTINE TO OBTAIN EIGENVALUES OF REAL,
*                     SYMMETRIC MATRIX
*     DSCAL, DCOPY:   BLAS ROUTINES
* ----------------------------------------------------------------
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER IERR, NCH, NCHM1, NCHP1
      EXTERNAL DSCAL, DCOPY, WAVMAT, DIAGVL
*  SQUARE MATRIX (OF ROW DIMENSION NCH)
      DIMENSION W(1)
*  VECTORS DIMENSIONED AT LEAST NCH
      DIMENSION EIGNOW(1),SCR1(1),P(1),VL(1),IV(1),EINT(1)
      DIMENSION CENT(1)
* ------------------------------------------------------------------
      DATA XMIN1 / -1.D0/
      NCHP1 = NCH + 1
      NCHM1 = NCH - 1
      CALL WAVMAT(W, NCH, RNOW, P, VL, IV, ERED, EINT, CENT, EP2RU,
     1            CM2RU, RSCALE, SCR1, MXLAM, NHAM, IPRINT)
C
*  SINCE WAVMAT RETURNS NEGATIVE OF LOWER TRIANGLE OF W(R) MATRIX (EQ.(3
*  M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..."),
*  NEXT LINE CHANGES ITS SIGN
      CALL DSCAL(NCH*NCH, XMIN1, W, 1)
C
      CALL DIAGVL(W, NCH, NCH, EIGNOW)
C
      RETURN
      END