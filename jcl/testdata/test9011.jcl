//TSOBATCH JOB
//*
//STEP0001 EXEC PGM=IKJEFT01
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD  *
 DSN SYSTEM(DB2P)
 RUN PROGRAM(TALYN) PLAN(MOYA)
 END
//*
//STEP0002 EXEC PGM=IKJEFT1A
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD  DISP=SHR,DSN=PROD.CNTLLIB(DB2P)
//         DD  *
 RUN PROGRAM(TALYN) PLAN(MOYA)
 END
//*
//STEP0003 EXEC PGM=IKJEFT1B
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD  DISP=SHR,DSN=PROD.CNTLLIB(DB2P)
//         DD  *
 RUN PROGRAM(TALYN) PLAN(MOYA)
//         DD  DISP=SHR,DSN=PROD.CNTLLIB(END)
//*
//STEP0004 EXEC PGM=IKJEFT1B
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD  DISP=SHR,DSN=PROD.CNTLLIB(DB2P)
//         DD  *
 RUN PROGRAM(TALYN) PLAN(MOYA)
 RUN PROGRAM(AERYN) PLAN(CRICHTON)
//         DD  DISP=SHR,DSN=PROD.CNTLLIB(END)
//*
//STEP0005 EXEC PGM=IKJEFT01
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD  *
ALLOCATE FILE(DD001) DA('CHIANA') SHR
CALL *DARGO
//*

