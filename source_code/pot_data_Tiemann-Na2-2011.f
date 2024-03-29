      module pot_data_Tiemann
C  Copyright (C) 2020 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  MODULE CONTAINING PARAMETERS OF A PAIR OF TIEMANN-STYLE
C  POTENTIAL CURVES OF AN ALKALI DIMER
C  UNITS USED ARE CM-1 AND POWERS OF ANGSTROM
C
C  POTENTIAL 1 IS SINGLET X, POTENTIAL 2 IS TRIPLET A
C
      USE physical_constants
      SAVE
C
C  KCS PARAMETERS FROM FERBER ET AL., PRA 88, 012516 (2013)
C
      CHARACTER(72) :: POTNAM =
     X ' Na2 potential from S. Knoop et al., PhysRevA.83.042704 (2011)'
C
C  PRINT CONTROL (FOR POTENTIAL ROUTINE ONLY)
C  0 = SILENT, 1 = TITLE, 2 = INTERNALLY CALCULATED PARAMETERS
C
      INTEGER IPRINT/2/
C
C  NUMBER OF TERMS IN POWER SERIES FOR CENTRAL REGION
C  (NOTE: HIGHEST POWER + 1 BECAUSE ARRAYS START AT 0)
C
      INTEGER :: NA(2) = (/27,9/)
C
C  EXPANSION COEFFICIENTS:
C
      DOUBLE PRECISION :: A(0:26,2) = RESHAPE((/
     X  -6022.04193D0,
     X  -0.200727603516760356D+01,
     X   0.302710123527149044D+05,
     X   0.952678499004718833D+04,
     X  -0.263132712461278206D+05,
     X  -0.414199125447689439D+05,
     X   0.100454724828577862D+06,
     X   0.950433282843468915D+05,
     X  -0.502202855817934591D+07,
     X  -0.112315449566019326D+07,
     X   0.105565865633448541D+09,
     X  -0.626929930064849034D+08,
     X  -0.134149332172454119D+10,
     X   0.182316049840707183D+10,
     X   0.101425117010240822D+11,
     X  -0.220493424364290123D+11,
     X  -0.406817871927934494D+11,
     X   0.144231985783280396D+12,
     X   0.379491474653734665D+11,
     X  -0.514523137448139771D+12,
     X   0.342211848747264038D+12,
     X   0.839583017514805054D+12,
     X  -0.131052566070353687D+13,
     X  -0.385189954553600769D+11,
     X   0.135760501276292969D+13,
     X  -0.108790546442390417D+13,
     X   0.282033835345282288D+12,
     X
     X  -172.90517D0,
     X   0.355691862122135882D+01,
     X   0.910756126766199941D+03,
     X  -0.460619207631179620D+03,
     X   0.910227086296958532D+03,
     X  -0.296064051187991117D+04,
     X  -0.496106499110302684D+04,
     X   0.147539144920038962D+05,
     X  -0.819923776793683828D+04,
     X   0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0,
     X   0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0 /), SHAPE(A))
C
C     LOGICAL VARIABLES TO CONTROL CONTINUITY MATCHING:
C
      LOGICAL :: MATCHL = .TRUE., MATCHV = .TRUE., MATCHD = .FALSE.
C
C     IF (MATCHL), ADJUST A(0) TO MAKE POTENTIAL  CONTINUOUS AT RLR
C     IF (MATCHL), ADJUST ASR  TO MAKE POTENTIAL  CONTINUOUS AT RSR
C     IF (MATCHD), ADJUST BSR  TO MAKE DERIVATIVE CONTINUOUS AT RSR
C     IF .FALSE., USE THE CORRESPONDING INPUT VALUE UNCHANGED AND
C     PRINT THE RESULTING MISMATCH FOR INFORMATION.
C
C     RM AND B ARE USED IN DEFINITION THE OF XI.
C     RSR AND RLR ARE SHORT-RANGE AND LONG-RANGE MATCHING POINTS.
C     PARAMETERS OF SHORT-RANGE POTENTIAL ASR + BSR*R**NSR.
C
       DOUBLE PRECISION ::
     X  RM(2)  = (/3.0788576D0, 5.149085D0/),
     X  B(2)   = (/ -0.140D0, -0.40D0/),
     X  RSR(2) = (/2.181D0, 4.2780D0/),
     X  RLR(2) = (/11.00D0, 11.00D0/),
     X  NSR(2)  = (/6.0D0, 6.0D0/),
     X  ASR(2) = (/-0.785318644D4, -0.2435819D3/),
     X  BSR(2) = (/0.842586535D6, 0.1488425D7/)
C
C  DISPERSION COEFFICIENTS
C
       DOUBLE PRECISION ::
     X  C6 = 0.75186131D7,
     X  C8 = 0.1686430D9,
     X  C10 = 0.3081961D10
C
C  EXTRA -C26/R**26 TERM PRESENT IN LONG-RANGE POTENTIAL FOR RB2
C
       INTEGER ::
     X  NEX = 0
       DOUBLE PRECISION ::
     X  CEX = 0.D0
C
C  PARAMETERS OF EXCHANGE POTENTIAL
C  NOTE THAT BETA AND GAMMA ARE CONVENTIONALLY LINKED.
C  THREE OPTIONS ARE IMPLEMENTED HERE:
C        GAMBET = 0: USE INPUT VALUES UNCHANGED
C        GAMBET = 1: CALCULATE GAMMA FROM BETA
C        GAMBET = 2: CALCULATE BETA FROM GAMMA
C  IF CHANGED, THE INPUT VALUE IS PRINTED FOR COMPARISON
C
       INTEGER :: GAMBET = 0
       DOUBLE PRECISION ::
     X  EXSIGN(2) = (/-1.D0, +1.D0/),
     X  AEX = 0.40485835D5,
     X  GAMMA = 4.59105D0,
     X  BETA = 2.36594D0
C
C  DISTANCE UNITS TO BE USED BY MOLSCAT/BOUND:
C  1.D0 FOR ANGSTROM, 0.529... FOR BOHR, ETC.
C
      DOUBLE PRECISION :: RUNITM = bohr_to_Angstrom
      CHARACTER(8)     :: LENUNT = 'BOHR'
C
C  COMMON BLOCK TO BE USED FOR ANY PARAMETERS TO BE CHANGED BY
C  OTHER ROUTINES, FOR EXAMPLE WHEN LEAST-SQUARES FITTING
C
      COMMON/POTEXT/NSR
C
      end module pot_data_Tiemann
