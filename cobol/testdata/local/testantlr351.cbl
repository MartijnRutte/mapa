000001 PROCESS DEFINE(A=B'1'),DEFINE(B=B'0')                            00000001
000002 ID Division.                                                     00000002
000003 Program-ID. testantlr351.                                        00000003
000004 Procedure Division.                                              00000004
000005     >>IF A                                                       00000005
000006     CALL 'PGM0001A'                                              00000006
000007     >>END-IF                                                     00000007
000008                                                                  00000008
000009     >>IF B                                                       00000009
000010     CALL 'PGM0001B'                                              00000010
000011     >>END-IF                                                     00000011
000012                                                                  00000012
000013     >>DEFINE A B'0' OVERRIDE                                     00000013
000014     >>DEFINE B B'1' OVERRIDE                                     00000014
000015                                                                  00000015
000016     >>IF A                                                       00000016
000017     CALL 'PGM0001C'                                              00000017
000018     >>END-IF                                                     00000018
000019                                                                  00000019
000020     >>IF B                                                       00000020
000021     CALL 'PGM0001D'                                              00000021
000022     >>END-IF                                                     00000022
000023                                                                  00000023
000024     >>DEFINE A AS PARAMETER                                      00000024
000025     >>DEFINE B AS PARAMETER                                      00000025
000026                                                                  00000026
000027     >>IF A                                                       00000027
000028     CALL 'PGM0001E'                                              00000028
000029     >>END-IF                                                     00000029
000030                                                                  00000030
000031     >>IF B                                                       00000031
000032     CALL 'PGM0001F'                                              00000032
000033     >>END-IF                                                     00000033
000034                                                                  00000034
000035     >>IF A                                                       00000035
000036     COPY testantlr351.cpy.                                       00000036
000037     >>END-IF                                                     00000037
000038                                                                  00000038
000039     >>IF B                                                       00000039
000040     CALL 'PGM0001G'                                              00000040
000041     >>END-IF                                                     00000041
000042                                                                  00000042
000043     >>DEFINE B AS PARAMETER                                      00000043
000044                                                                  00000044
000045     >>IF B                                                       00000045
000046     CALL 'PGM0001H'                                              00000046
000047     >>END-IF                                                     00000047
000048                                                                  00000048
000049     GOBACK.                                                      00000049
