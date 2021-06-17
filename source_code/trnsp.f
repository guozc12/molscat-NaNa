      SUBROUTINE TRNSP(A,N)
C  This subroutine is part of the MOLSCAT, BOUND and FIELD suite of programs
C
C  SUBROUTINE FOR IN-PLACE TRANSPOSITION OF N X N MATRIX A
C  BASED ON MILLARD ALEXANDER'S TRANSP
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(1)
      ICOLPT = 2
      IROWPT = N + 1
      DO 100 ICOL = 1, N - 1
C  ICOLPT POINTS TO FIRST SUB-DIAGONAL ELEMENT IN COLUMN ICOL
C  IROWPT POINTS TO FIRST SUPER-DIAGONAL ELEMENT IN ROW ICOL
C  NROW IS NUMBER OF SUBDIAGONAL ELEMENTS IN THIS COLUMN
        NROW = N - ICOL
        CALL DSWAP(NROW, A(ICOLPT), 1, A(IROWPT), N)
        ICOLPT = ICOLPT + N + 1
        IROWPT = IROWPT + N + 1
  100 CONTINUE
      RETURN
      END
