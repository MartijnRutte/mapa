//IF JOB
//*
// IF RC=0 THEN
// ELSE
// ENDIF
// IF ABEND | RC > 12 THEN something bad happened
// EXEC PGM=S806
// ELSE all seems okay for now
// EXEC PGM=IEFBR14
// ENDIF end IF block
//IF0001  IF (((((RC=0))))) THEN
//EL0001  ELSE
//IF0001E ENDIF
//IF0002  IF (((((RC = 0))))) THEN
//EL0002  ELSE
//IF0002E ENDIF
//IF0003  IF (((((RC EQ 0))))) THEN
//EL0003  ELSE
//IF0003E ENDIF
//IF0004  IF (((((STEP01.RC=0))))) THEN
//EL0004  ELSE
//IF0004E ENDIF
//IF0005  IF (((((STEP01.RC = 0))))) THEN
//EL0005  ELSE
//IF0005E ENDIF
//IF0006  IF (((((STEP01.RC EQ 0))))) THEN
//EL0006  ELSE
//IF0006E ENDIF
//IF0007  IF (((((RC = 0))))) THEN
//EL0007  ELSE
//IF0007E ENDIF
//IF0008  IF (STEP01.ABEND |
//           ((STEP02.RC = 7 &
//             STEP03.RC > 9) |
//            STEP04.ABENDCC = U4038)) THEN
//EL0008  ELSE
//IF0008E ENDIF

