000001 Identification Division.
000002 Program-ID. testantlr133.
000003 Data Division.
000004 Working-Storage Section.
000005 01  CONSTANTS.
000006     05  MYNAME               PIC X(012) VALUE 'testantlr133'.
000007
000008* 
000009 01  SWITCHES.
000010     05  SD-001-TRUTH-SW      PIC X(008).
000011         88  SD-001-TRUTH     VALUE 'ZAPHOD'.
000012         88  SD-001-ALSO-TRUE VALUE 'FPREFECT'.
000013
000014 01  SOME-DATA.
000015     05  SD-001               PIC X(008).
000016     05  SD-002.
000017         10  SD-002-A         PIC X(001).
000018         10  SD-002-B         PIC X(001).
000019     05  SD-003               PIC X(008).
000020
000021 01  WS-BUF                   PIC X(100).
000022
000023 77  WS-COUNT                 PIC 9(008) COMP-5 VALUE 0.
000024
000025 Procedure Division.
000026     DISPLAY MYNAME ' Begin'
000027     
000028     JSON PARSE WS-BUF INTO SOME-DATA END-JSON
000029
000030     JSON PARSE
000031         WS-BUF INTO SOME-DATA
000032         DETAIL
000033         NAME SD-001 'ARTHUR'
000034              SD-002 'DENT'
000035         SUPPRESS 
000036              SD-001
000037              SD-002
000038         ON EXCEPTION CALL 'CEE3ABD' END-CALL
000039         NOT ON EXCEPTION PERFORM 1000-para
000040     END-JSON
000041
000042     JSON PARSE
000043         WS-BUF INTO SOME-DATA
000044         WITH DETAIL
000045         NAME OF SD-001 IS 'ARTHUR'
000046                 SD-002 IS OMITTED
000047         SUPPRESS SD-001 SD-003
000048         ON EXCEPTION CALL 'CEE3ABD' END-CALL
000049         NOT ON EXCEPTION PERFORM 1000-para
000050     END-JSON
000051
000052     JSON PARSE
000053         WS-BUF INTO SOME-DATA
000054         WITH DETAIL
000055         NAME OF SD-001 IS 'ARTHUR'
000056                 SD-002 IS OMITTED
000057         SUPPRESS SD-001 SD-003
000058         CONVERTING SD-001 FROM JSON BOOLEAN USING SD-001-TRUTH
000059         ON EXCEPTION CALL 'CEE3ABD' END-CALL
000060         NOT ON EXCEPTION PERFORM 1000-para
000061     END-JSON
000062
000063     JSON PARSE
000064         WS-BUF INTO SOME-DATA
000065         WITH DETAIL
000066         NAME OF SD-001 IS 'ARTHUR'
000067                 SD-002 IS OMITTED
000068         SUPPRESS SD-001 SD-003
000069         CONVERTING 
000070                SD-001 FROM JSON BOOLEAN 
000071                    USING SD-001-TRUTH AND SD-001-ALSO-TRUE
000072         ON EXCEPTION CALL 'CEE3ABD' END-CALL
000073         NOT ON EXCEPTION PERFORM 1000-para
000074     END-JSON
000075
000076     JSON PARSE
000077         WS-BUF INTO SOME-DATA
000078         WITH DETAIL
000079         NAME OF SD-001 IS 'ARTHUR'
000080                 SD-002 IS OMITTED
000081         SUPPRESS SD-001 SD-003
000082         CONVERTING 
000083                SD-001 FROM JSON BOOLEAN 
000084                    USING 'TRILLIAN' AND 'MARVIN'
000085         ON EXCEPTION CALL 'CEE3ABD' END-CALL
000086         NOT ON EXCEPTION PERFORM 1000-para
000087     END-JSON
000088
000089     JSON PARSE
000090         WS-BUF INTO SOME-DATA
000091         WITH DETAIL
000092         NAME OF SD-001 IS 'ARTHUR'
000093                 SD-002 IS OMITTED
000094         SUPPRESS SD-001 SD-003
000095         CONVERTING 
000096                SD-001 FROM JSON BOOLEAN 
000097                    USING SD-001-TRUTH AND SD-001-ALSO-TRUE
000098           ALSO
000099                SD-002 FROM BOOL USING '%%'
000100         ON EXCEPTION CALL 'CEE3ABD' END-CALL
000101         NOT ON EXCEPTION PERFORM 1000-para
000102     END-JSON
000103
000104     JSON PARSE
000105         WS-BUF INTO SOME-DATA
000106         WITH DETAIL
000107         NAME OF SD-001 IS 'ARTHUR'
000108                 SD-002 IS OMITTED
000109         SUPPRESS SD-001 SD-003
000110         CONVERTING 
000111                SD-001 FROM JSON BOOLEAN 
000112                    USING SD-001-TRUTH AND SD-001-ALSO-TRUE
000113           ALSO
000114                SD-002 FROM BOOL USING '%%' AND '##'
000115         ON EXCEPTION CALL 'CEE3ABD' END-CALL
000116         NOT ON EXCEPTION PERFORM 1000-para
000117     END-JSON
000118
000119
000120     DISPLAY MYNAME ' End'
000121     
000122     GOBACK
000123     .
000124
000125 1000-para.
000126
000127     .
000128
