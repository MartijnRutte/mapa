       PROCESS DEFINE(X=2)                                              00000001
       Identification Division.                                         00000002
       Program-ID. testantlr242.                                        00000003
       Data Division.                                                   00000004
       Working-Storage Section.                                         00000005
                                                                        00000006
       01  CONSTANTS.                                                   00000007
           05  MYNAME               PIC X(012) VALUE 'testantlr242'.    00000008
           >>EVALUATE TRUE                                              00000009
           >>WHEN X = 1                                                 00000010
           05  PGM-0001             PIC X(008) VALUE 'PGMA0001'.        00000011
           >>WHEN X = 2                                                 00000012
           05  PGM-0001             PIC X(008) VALUE 'PGMA0002'.        00000013
           >>WHEN X = 3                                                 00000014
           05  PGM-0001             PIC X(008) VALUE 'PGMA0003'.        00000015
           >>WHEN OTHER                                                 00000016
           05  PGM-0001             PIC X(008) VALUE 'PGMA0009'.        00000017
           >>END-EVALUATE                                               00000018
                                                                        00000019
      *                                                                 00000020
                                                                        00000021
       Procedure Division.                                              00000022
           DISPLAY MYNAME ' Begin'                                      00000023
           CALL PGM-0001                                                00000024
                                                                        00000025
           DISPLAY MYNAME ' End'                                        00000026
                                                                        00000027
           GOBACK                                                       00000028
           .                                                            00000029
                                                                        00000030
                                                                        00000031
