SET CURRENT SQLID = PFSE01;
SET SCHEMA PFSE01;
--#SET TERMINATOR @
 --
 -- DROP PROC MET DDL PFSDSFML
 --
  CREATE PROCEDURE SP_FOUTMELDING_NAAR_SPLUNK
              (
     IN  I_F_FOUTMELDING_ID            BIGINT
    ,IN  I_F_FOUTCODE_TYPE_ID          INTEGER
    ,IN  I_TS_DETECTIE                 TIMESTAMP
    ,IN  I_FOUT_KLASSE                 VARCHAR(100)
    ,IN  I_RUNTIME_REFERENCE           VARCHAR(256)
    -- ,IN  I_DATA_REFERENCE       VARCHAR(1024) -- niet ivm prod.data
    ,IN  I_INSTRUCTIE_REFERENCE        VARCHAR(35)
    ,IN  I_TRANSACTIE_REFERENCE        VARCHAR(35)
    ,IN  I_SQL_CODE                    VARCHAR(100)
    ,IN  I_SQL_DIAGNOSTICS             VARCHAR(256)
    ,IN  I_SYSTEEM_VAN_REGISTRATIE     CHAR(3)
     --  Geen output, voor het testen:
    ---, OUT F_OMSCHRIJVING_LANG VARCHAR(2000)
   --
   -- Deze STORED PROCEDURE wordt vanuit een trigger aangeroepen.
   -- Hangt aan tabel F_FOUTMELDING om automatisch alle
   -- fouten te SPLUNKen
   --
              )
          VERSION      V1
          LANGUAGE     SQL
          NOT          DETERMINISTIC
          MODIFIES     SQL       DATA
          DYNAMIC      RESULT    SETS  0
          DISABLE       DEBUG MODE
          ---ALLOW               DEBUG MODE
          PARAMETER    CCSID     UNICODE
          QUALIFIER    PFSE01
          ---QUALIFIER    PFSO04
          PACKAGE      OWNER     PFSE
          ---PACKAGE      OWNER     PFSO04
          ASUTIME      LIMIT     5000
          COMMIT       ON RETURN NO
          -- WLM ENVIRONMENT NIET NODIG:
          -- EXECUTED IN THE DBM1 ADDRESS SPACE
          -- MOET ER VERPLICHT ZIJN FOR DEBUG
          WLM ENVIRONMENT FOR DEBUG MODE PFSNOP
          DEFER        PREPARE
          CURRENT      DATA      NO
          DEGREE       ANY
          CONCURRENT   ACCESS RESOLUTION
                       USE CURRENTLY COMMITTED
          DYNAMICRULES RUN
          WITH EXPLAIN
          ---WITH           EXPLAIN
          WITHOUT      IMMEDIATE WRITE
          ISOLATION    LEVEL     CS
          WITHOUT      KEEP      DYNAMIC
          -- MAG NIET: SQL PATH PFSE01
          -- QUERY     ACCELERATION NONE
          -- GET_ACCEL_ARCHIVE NO
          RELEASE      AT        COMMIT
          REOPT        NONE
          VALIDATE     BIND
          ROUNDING     DEC_ROUND_HALF_EVEN
          DECIMAL(31)

BEGIN
  DECLARE PROC_NAAM              VARCHAR(26)
          DEFAULT 'SP_FOUTMELDING_NAAR_SPLUNK'              ;
  DECLARE SQLCODE                INTEGER      DEFAULT 0     ;
  DECLARE SQLSTATE               CHAR(5)      DEFAULT 0     ;
  DECLARE SAVE_SQLCODE           INTEGER      DEFAULT 0     ;
  DECLARE SAVE_SQLSTATE          CHAR(5)      DEFAULT ' '   ;
  DECLARE SAVE_ERRMSG            VARCHAR(260) DEFAULT ' '   ;

  DECLARE F_ACTIE                VARCHAR(60)                ;
  DECLARE F_SOORT_FOUTCODE       VARCHAR(10)                ;
  DECLARE F_BETREFT_TABEL        VARCHAR(40)                ;
  DECLARE F_SLEUTELWAARDE1       VARCHAR(60)                ;
  DECLARE F_SLEUTELWAARDE2       VARCHAR(60)                ;
  DECLARE F_SLEUTELWAARDE3       VARCHAR(60)                ;
  DECLARE F_OMSCHRIJVING_KORT    VARCHAR(035)               ;
  DECLARE F_OMSCHRIJVING_LANG    VARCHAR(260)               ;

  DECLARE WRK_DB2_SCHEMA         CHAR(6)
                                 DEFAULT 'PFSE01'   ;
  DECLARE WRK_TIMESTAMP          TIMESTAMP                  ;

  DECLARE WRK_SPLUNK_HEADER      CHAR(34)
          DEFAULT '"SSDFDB2TOKEN":"SDFDB2MainfIndex"{'      ;
  DECLARE WRK_SPLUNK_FOOTER      CHAR(01)
          DEFAULT '}'                                       ;

  DECLARE WRK_SPLUNK_MESSAGE_TXT VARCHAR(4090)              ;

  -- Declaraties voor SP_WRITE_SPLUNK igv foutsituaties
  DECLARE SPL_MESSAGE_ID      VARCHAR(08) DEFAULT 'PFSFML'  ;
  DECLARE SPL_PGM_NAAM        VARCHAR(45) DEFAULT 'PFSSPFML';
  DECLARE SPL_SOORT_FOUTCODE  VARCHAR(08) DEFAULT 'SQL'     ;
  DECLARE SPL_FOUTCODE_NUM    INTEGER                       ;
  DECLARE SPL_FOUTCODE_CHAR   VARCHAR(15) DEFAULT ' '       ;
  DECLARE SPL_FREE_TEXT       VARCHAR(200)                  ;

  -- Benodigde cols van tabel F_FOUTCODE_TYPE
  DECLARE WRK_PROCES_NAAM        VARCHAR(256)               ;
  DECLARE WRK_PROCES_DEEL        VARCHAR(256)               ;
  DECLARE WRK_FOUT_MELDING       VARCHAR(256)               ;
  DECLARE WRK_ACTIE              VARCHAR(1024)              ;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS   CONDITION 1
        SAVE_ERRMSG   = MESSAGE_TEXT
       ,SAVE_SQLCODE  = DB2_RETURNED_SQLCODE
       ,SAVE_SQLSTATE = RETURNED_SQLSTATE;
    --SET F_OMSCHRIJVING_KORT =
    --       'SQL=' CONCAT SAVE_SQLCODE  CONCAT
    --    ' STATE=' CONCAT SAVE_SQLSTATE CONCAT
    --      ' PGM=' CONCAT PROC_NAAM         ;
    --SET F_OMSCHRIJVING_LANG = SAVE_ERRMSG  ;
  END ; -- End Declare

  DECLARE CONTINUE HANDLER FOR NOT FOUND
  BEGIN
  CASE  F_BETREFT_TABEL
  WHEN 'F_FOUTCODE_TYPE' THEN
   -- Voor deze tabel mag geen RNF optreden, FCT moet er zijn
   SET F_OMSCHRIJVING_KORT =
      'FCT afwezig '                                      ;
   SET F_OMSCHRIJVING_LANG = 'Key=' concat
       F_SLEUTELWAARDE1 concat ' ' concat
       F_SLEUTELWAARDE2 concat ' ' concat
       F_SLEUTELWAARDE3 concat
      ' niet gevonden in tabel ' concat F_BETREFT_TABEL   ;
   -- SPLUNK message
   SET SPL_FREE_TEXT       = F_OMSCHRIJVING_LANG          ;
   CALL SP_WRITE_SPLUNK(SPL_MESSAGE_ID,SPL_PGM_NAAM,SPL_SOORT_FOUTCODE
       ,SPL_FOUTCODE_NUM,SPL_FOUTCODE_CHAR,SPL_FREE_TEXT) ;
   SIGNAL SQLSTATE '66666' SET MESSAGE_TEXT = F_OMSCHRIJVING_LANG ;
  --ELSE
   -- Voor de overige tabellen mag wel een not found optreden
  END CASE ;
  END ; -- End declare

HOOFD:BEGIN
      SELECT CURRENT TIMESTAMP
        INTO WRK_TIMESTAMP
        FROM SYSIBM.SYSDUMMY1;

 SET F_BETREFT_TABEL     = 'F_FOUTCODE_TYPE'               ;
 SET F_ACTIE             = 'SINGLE SELECT'                 ;
 SET F_SLEUTELWAARDE1    = I_F_FOUTCODE_TYPE_ID            ;
 SET F_SLEUTELWAARDE2    = ' '                             ;
 SET F_SLEUTELWAARDE3    = ' '                             ;
      SELECT PROCES_NAAM,
             PROCES_DEEL,
             FOUT_MELDING,
             ACTIE
        INTO WRK_PROCES_NAAM,
             WRK_PROCES_DEEL,
             WRK_FOUT_MELDING,
             WRK_ACTIE
        FROM F_FOUTCODE_TYPE
       WHERE F_FOUTCODE_TYPE_ID = I_F_FOUTCODE_TYPE_ID ;

 SET WRK_SPLUNK_MESSAGE_TXT =
     WRK_SPLUNK_HEADER concat
        '"timestamp":"'    concat CHAR(WRK_TIMESTAMP)  concat '", '
 concat '"message_id":"'   concat 'INN'
 concat I_SYSTEEM_VAN_REGISTRATIE concat 'FML", '
 concat '"Db2-schema":"'   concat WRK_DB2_SCHEMA             concat '"'
 concat ', "foutmelding_id":"' concat
        STRIP(CHAR(I_F_FOUTMELDING_ID))   concat '"'
 concat ', "foutcodetype_id":"' concat
        STRIP(CHAR(I_F_FOUTCODE_TYPE_ID)) concat '"'
 concat ', "procesnaam":"'  concat
        STRIP(WRK_PROCES_NAAM)            concat '"'
 concat ', "procesdeel":"'  concat
        STRIP(WRK_PROCES_DEEL)            concat '"'
 concat ', "foutmelding":"' concat
        STRIP(WRK_FOUT_MELDING)           concat '"'
 concat ', "actie":"'       concat
        STRIP(WRK_ACTIE)                  concat '"'
 concat ', "TS_detect":"'  concat CHAR(I_TS_DETECTIE)        concat '"';
 IF I_FOUT_KLASSE IS NOT NULL THEN
         SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
        ', "foutklasse":"'  concat STRIP(I_FOUT_KLASSE)      concat '"';
 END IF ;
 IF I_RUNTIME_REFERENCE IS NOT NULL THEN
         SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
    ', "runtimeref":"'  concat STRIP(I_RUNTIME_REFERENCE) concat '"';
 END IF ;
 --IF I_DATA_REFERENCE IS NOT NULL THEN
 --        SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
 --       ', "dataref":"'  concat STRIP(I_DATA_REFERENCE)      concat '"';
 --END IF ;
 IF I_INSTRUCTIE_REFERENCE IS NOT NULL THEN
         SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
  ', "instructref":"'  concat STRIP(I_INSTRUCTIE_REFERENCE)  concat '"';
 END IF ;
 IF I_TRANSACTIE_REFERENCE IS NOT NULL THEN
         SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
        ', "transactref":"'  concat STRIP(I_TRANSACTIE_REFERENCE)
        concat '"';
 END IF ;
 IF I_SQL_CODE IS NOT NULL THEN
         SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
        ', "SQLCODE":"'  concat STRIP(I_SQL_CODE)            concat '"';
 END IF ;
 IF I_SQL_DIAGNOSTICS IS NOT NULL THEN
         SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
        ', "SQL-diagnos":"' concat STRIP(I_SQL_DIAGNOSTICS)  concat '"';
 END IF ;

 SET WRK_SPLUNK_MESSAGE_TXT = WRK_SPLUNK_MESSAGE_TXT concat
     WRK_SPLUNK_FOOTER                 ;

      --- SET F_OMSCHRIJVING_LANG = WRK_SPLUNK_MESSAGE_TXT ;

 CALL SDZ.SDFDB2 (WRK_SPLUNK_MESSAGE_TXT)  ;

END HOOFD;    -- laatste END (van het hoofd-compound)
--SIGNAL SQLSTATE '66666' SET MESSAGE_TEXT = 'Na JNR' ;


END @
--#SET TERMINATOR ;
COMMIT;
--
--
--===============GRANTEN===============================================
-- AANROEP VANUIT JAVA ONLY
GRANT EXECUTE ON PROCEDURE SP_FOUTMELDING_NAAR_SPLUNK
      TO $EPFS60 ;
 GRANT EXECUTE ON PROCEDURE SP_FOUTMELDING_NAAR_SPLUNK
               TO PFSE;
--===============GRANTEN===============================================

