SET CURRENT SQLID = PFSE01;
SET SCHEMA PFSE01;
DROP PROCEDURE SP_REPAIR_I_INSTRUCTIE ;
--#SET TERMINATOR @
   CREATE PROCEDURE SP_REPAIR_I_INSTRUCTIE     (
         IN I_I_BESTAND_ID         INTEGER    
		-- Status geeft aan of de opschoning volledig is
		-- of dat de SP nog niet klaar is en opnieuw
		-- aangeroepen moet worden.
		-- B=bezig, nog niet klaar
		-- G=gereed
	   ,OUT O_STATUS_BUSY_OR_READY CHAR(1)
       ,OUT O_RETURN               INTEGER
       ,OUT F_OMSCHRIJVING_LANG    VARCHAR(260) )
   --
   --
   -- Deze STORED PROCEDURE 
   -- wordt door een java-app aangeroepen als ene bestandsverwerking
   -- is afgebroken (abend).
   -- De deels aangebrachte data moeten dan geschoond worden (bezemfunctie),
   -- zodat het bestand opnieuw aangeboden kan worden.
   -- De java-app bepaalt welk bestand_id geschoond moet worden en voert
   -- zo nodig extra controles uit.
   -- Alles wat onder een bestand-id valt (childs) moet 
   -- consistent geschoond worden.
   -- Omdat deze SP door java wordt aangeroepen kan/mag er 
   -- geen rollback of commit in de SP voorkomen. 
   -- Om het aantal uncommitted deletes binnen de perken te houden, regelbaar
   -- via een parameter uit de parameter tabel, moet 
   -- de SP de besturing regelmatig teruggeven aan de app, 
   -- zodat die de commit kan uitvoeren en de SP opnieuw 
   -- moet callen, totdat alles geschoond is (O_STATUS_BUSY_OR_READY)
   -- De deletes vinden plaats op archive-enabled tables. 
   -- In dit geval mogen de verwijderde rijen niet gearchiveerd worden, 
   -- dus moet archivering uit staan!
   -- Er wordt zowel in goed als fout situaties naar Splunk geschrevem
   --    index="mfpublic" message_id="INNPFSRII"
   --
          -- N.B. onderstaande SETTINGS zijn GEWOGEN
          VERSION      V1
          LANGUAGE     SQL
          NOT          DETERMINISTIC
          MODIFIES     SQL       DATA
          DYNAMIC      RESULT    SETS  0
          DISABLE      DEBUG MODE ---
          ---ALLOW               DEBUG MODE  ---
          PARAMETER    CCSID     UNICODE
          QUALIFIER    PFSE01  ---
          ---QUALIFIER    PFSO07  ---
          PACKAGE      OWNER     PFSE  ---
          ---PACKAGE      OWNER     PFSO07  ---
          ASUTIME      LIMIT     500000000  ---
          ---ASUTIME      NO LIMIT ---
          COMMIT       ON RETURN NO
          INHERIT      SPECIAL REGISTERS     
          -- WLM ENVIRONMENT NIET NODIG:
          -- EXECUTED IN THE DBM1 ADDRESS SPACE
          -- MOET ER VERPLICHT ZIJN FOR DEBUG
          WLM ENVIRONMENT FOR DEBUG MODE PFSNOP  ---
          ---WLM ENVIRONMENT FOR DEBUG MODE OPFSSP00 ---
          DEFER        PREPARE
          CURRENT      DATA      NO
          DEGREE       ANY
          CONCURRENT   ACCESS RESOLUTION
                       USE CURRENTLY COMMITTED
          DYNAMICRULES RUN
          WITH EXPLAIN  ---
          ---WITH           EXPLAIN ---
          WITHOUT      IMMEDIATE WRITE
          ISOLATION    LEVEL     CS
          WITH         KEEP      DYNAMIC
          OPTHINT      ''
          -- MAG NIET: SQL PATH PFSE01
          -- QUERY     ACCELERATION NONE
          -- GET_ACCEL_ARCHIVE NO
          RELEASE      AT        COMMIT
          REOPT        ONCE
          VALIDATE     BIND
          ROUNDING     DEC_ROUND_HALF_EVEN
          DECIMAL(31)
          BUSINESS_TIME SENSITIVE YES       
          SYSTEM_TIME   SENSITIVE YES         
          ARCHIVE       SENSITIVE YES             
          -- V12: CONCENTRATE STATEMENTS OFF 

BEGIN
  DECLARE PROC_NAAM              VARCHAR(22)
          DEFAULT 'SP_REPAIR_I_INSTRUCTIE'                  ;
  DECLARE SQLCODE                INTEGER      DEFAULT 0     ;
  DECLARE SQLSTATE               CHAR(5)      DEFAULT 0     ;
  DECLARE SAVE_SQLCODE           INTEGER      DEFAULT 0     ;
  DECLARE SAVE_SQLSTATE          CHAR(5)      DEFAULT ' '   ;
  DECLARE SAVE_ERRMSG            VARCHAR(260) DEFAULT ' '   ;

  DECLARE WRK_DB2_SCHEMA         CHAR(6)
                                 DEFAULT 'PFSE01'   ;
  
  DECLARE F_ACTIE                VARCHAR(60)                ;
  DECLARE F_SOORT_FOUTCODE       VARCHAR(10)                ;
  DECLARE F_BETREFT_TABEL        VARCHAR(40)                ;
  DECLARE F_SLEUTELWAARDE1       VARCHAR(60)                ;
  DECLARE F_SLEUTELWAARDE2       VARCHAR(60)                ;
  DECLARE F_SLEUTELWAARDE3       VARCHAR(60)                ;
  DECLARE F_OMSCHRIJVING_KORT    VARCHAR(035)               ;
  --DECLARE F_OMSCHRIJVING_LANG    VARCHAR(260)               ;

  -- Declaraties voor SP_WRITE_SPLUNK igv foutsituaties
  DECLARE SPL_MESSAGE_ID      VARCHAR(08) DEFAULT 'PFSRII'  ;
  DECLARE SPL_PGM_NAAM        VARCHAR(45)                   ;
  DECLARE SPL_SOORT_FOUTCODE  VARCHAR(08) DEFAULT 'SQL'     ;
  DECLARE SPL_FOUTCODE_NUM    INTEGER                       ;
  DECLARE SPL_FOUTCODE_CHAR   VARCHAR(15) DEFAULT ' '       ;
  DECLARE SPL_FREE_TEXT       VARCHAR(200)                  ;

  -- Declaraties voor SP_WRITE_SPLUNK_INFO_V2 (statistics)
  DECLARE SPLI_MESSAGE_ID     VARCHAR(08) DEFAULT 'PFSRII'  ;
  DECLARE SPLI_INFO_NAAM      VARCHAR(23)
                          DEFAULT 'SP_REPAIR_I_INSTRUCTIE'  ;
  DECLARE SPLI_OPT_RUBR01_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR01_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR02_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR02_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR03_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR03_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR04_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR04_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR05_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR05_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR06_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR06_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR07_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR07_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR08_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR08_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR09_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR09_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR10_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR10_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR11_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR11_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR12_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR12_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR13_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR13_VAL VARCHAR(80) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR14_TXT VARCHAR(30) DEFAULT NULL      ;
  DECLARE SPLI_OPT_RUBR14_VAL VARCHAR(80) DEFAULT NULL      ;

  -- # Tabel S_PARAMETER_WAARDE:
  DECLARE SPW_INTG_PARM               BIGINT                ;

  DECLARE HV_AANTAL_HIT_ROWS          INTEGER DEFAULT 0     ;
  DECLARE HV_AANTAL_DELETED_ROWS      INTEGER DEFAULT 0     ;
  
  DECLARE O_BESTAND_DELETED           INTEGER DEFAULT 0     ;
  DECLARE O_BERICHT_SELECTED          INTEGER DEFAULT 0     ;
  DECLARE O_BERICHT_DELETED           INTEGER DEFAULT 0     ;
  DECLARE O_TRANS_SELECTED            INTEGER DEFAULT 0     ;
  DECLARE O_GEBEURTENIS_DELETED       INTEGER DEFAULT 0     ;
  DECLARE O_INSTRUCTIE_DELETED        INTEGER DEFAULT 0     ;    
  DECLARE O_INSTRUCTIEKLASSE_DELETED  INTEGER DEFAULT 0     ;    
  DECLARE O_LUW_DELETED               INTEGER DEFAULT 0     ;    
  DECLARE O_LUW_TRANS_FOUT_DELETED    INTEGER DEFAULT 0     ;    
  DECLARE O_TRANSACTIE_DELETED        INTEGER DEFAULT 0     ;    
  DECLARE O_VALIDATIE_FOUT_DELETED    INTEGER DEFAULT 0     ;            

  DECLARE O_COMMITS                   INTEGER               ;

  DECLARE HV_TS_INSERTED_SCHONING     TIMESTAMP             ;
  DECLARE HV_ENVIRONMENT_OTACP        CHAR(1) 
                                      DEFAULT 'E'; ---
  ---DECLARE HV_ENVIRONMENT_OTACP        CHAR(1) DEFAULT 'O'   ; ---
  
  DECLARE AANTAL_ROWS_UNCOMMITTED     INTEGER DEFAULT 0     ;
  DECLARE HV_COMMIT_NA_XX_DELS        INTEGER               ;

  DECLARE CUR_TE_SCHONEN_BERICHT_AT_END CHAR(1) DEFAULT 'N' ;    

  DECLARE HV_I_BESTAND_ID             INTEGER               ;
  DECLARE HV_I_BERICHT_ID             BIGINT                ;
  
  DECLARE HV_START_TIMESTAMP          TIMESTAMP             ;
  DECLARE HV_DOORLOOP_IN_MINUTEN      INTEGER               ;
  
  -- # Welke berichten binnen 1 bestand kunnen weg?
  DECLARE CUR_TE_SCHONEN_BERICHTEN CURSOR
   WITH    HOLD   -- ivm tussentijdse commits
   WITHOUT RETURN -- interne cursor, geen result set
   -- WITH RETURN kan gemakkelijk zijn bij testen igv vastlopen
   FOR
   SELECT I_BERICHT_ID 
     FROM I_BERICHT
    WHERE I_BESTAND_ID = HV_I_BESTAND_ID 
    ORDER BY I_BERICHT_ID
          ;  -- END CURSOR DECL

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    -- COMMIT EN ROLLBACK MAG NIET OMDAT DEZE StoPro
    -- DOOR JAVA WORDT AANGEROEPEN
    GET DIAGNOSTICS   CONDITION 1
        SAVE_ERRMSG   = MESSAGE_TEXT
       ,SAVE_SQLCODE  = DB2_RETURNED_SQLCODE
       ,SAVE_SQLSTATE = RETURNED_SQLSTATE;
    SET F_OMSCHRIJVING_KORT =
           'SQL=' CONCAT SAVE_SQLCODE  CONCAT
        ' STATE=' CONCAT SAVE_SQLSTATE CONCAT
          ' PGM=' CONCAT PROC_NAAM         ;
    SET F_OMSCHRIJVING_LANG = SAVE_ERRMSG  ;
    SET O_RETURN            = SAVE_SQLCODE ;
    -- SPLUNK message
    SET SPL_FOUTCODE_NUM    = SAVE_SQLCODE               ;
    SET SPL_FREE_TEXT       =
        F_OMSCHRIJVING_KORT concat ' ' concat F_OMSCHRIJVING_LANG ;
    CALL SP_WRITE_SPLUNK(SPL_MESSAGE_ID,SPL_PGM_NAAM,SPL_SOORT_FOUTCODE
        ,SPL_FOUTCODE_NUM,SPL_FOUTCODE_CHAR,SPL_FREE_TEXT);
    -- ROLLBACK mag dus niet
    SIGNAL SQLSTATE '66666' SET MESSAGE_TEXT = F_OMSCHRIJVING_LANG ;
    RETURN SAVE_SQLCODE  ;
  END ; -- End Declare

  DECLARE CONTINUE HANDLER FOR NOT FOUND
  -- ALS  EXIT     HANDLER KAN NIET, SQLCODE 100 MAG SOMS WEL
  BEGIN
  CASE  F_BETREFT_TABEL
  WHEN 'CUR_TE_SCHONEN_BERICHTEN' THEN
   -- Dit is een legitieme end-of-cursor
   SET CUR_TE_SCHONEN_BERICHT_AT_END        = 'J'             ;
   -- en continue
  WHEN 'S_PARAMETER_WAARDE' THEN
   -- Voor deze tabel mag geen RNF optreden, zonder parms geen run
      SET O_RETURN            = +100                      ;
      SET F_OMSCHRIJVING_KORT =
         'Parameter afwezig        '                      ;
      SET F_OMSCHRIJVING_LANG = 'Parameter =' concat
          F_SLEUTELWAARDE1 concat ' ' concat
          F_SLEUTELWAARDE2 concat
         ' niet gevonden in tabel ' concat F_BETREFT_TABEL;
      -- SPLUNK message
      SET SPL_FOUTCODE_NUM    = O_RETURN                  ;
      SET SPL_FREE_TEXT       = F_OMSCHRIJVING_LANG       ;
      CALL SP_WRITE_SPLUNK(SPL_MESSAGE_ID,SPL_PGM_NAAM
          ,SPL_SOORT_FOUTCODE
          ,SPL_FOUTCODE_NUM,SPL_FOUTCODE_CHAR
          ,SPL_FREE_TEXT)                                 ;
      SIGNAL SQLSTATE '66666' SET MESSAGE_TEXT = 
                                      F_OMSCHRIJVING_LANG ;
      -- END OF STORY
  WHEN 'I_BESTAND' THEN
   -- Voor deze tabel mag geen RNF optreden, niet logisch
   SET O_RETURN            = +100                         ;
   SET F_OMSCHRIJVING_KORT =
      'I_BESTAND_ID niet aanwezig'                        ;
   SET F_OMSCHRIJVING_LANG = 'BESTAND_ID=' concat
       F_SLEUTELWAARDE1 concat
      ' niet gevonden in tabel ' concat F_BETREFT_TABEL   ;
   -- SPLUNK message
   SET SPL_FOUTCODE_NUM    = O_RETURN                     ;
   SET SPL_FREE_TEXT       = F_OMSCHRIJVING_LANG          ;
   CALL SP_WRITE_SPLUNK(SPL_MESSAGE_ID,SPL_PGM_NAAM,SPL_SOORT_FOUTCODE
       ,SPL_FOUTCODE_NUM,SPL_FOUTCODE_CHAR,SPL_FREE_TEXT) ;
   RETURN 100                                             ;
  ELSE
   -- Voor de overige tabellen mag wel een not found optreden
   SET O_RETURN          = 0                              ;
  END CASE ;
  END ; -- End declare

HOOFD:BEGIN -- #
  -- In dit geval mogen de verwijderde rijen niet gearchiveerd worden, 
  -- dus moet archivering uit staan!
 SET GET_ARCHIVE         = 'N' ;
 SET MOVE_TO_ARCHIVE     = 'N' ;
 
 SET F_SOORT_FOUTCODE    = 'SQLCODE'                  ;
 SET O_STATUS_BUSY_OR_READY = 'B'                     ;
 SET O_RETURN            = 0                          ;
 SET HV_START_TIMESTAMP  = CURRENT TIMESTAMP          ;

 SET O_COMMITS           = 0                          ;
 
 SET O_BERICHT_DELETED           = 0                  ;
 SET O_GEBEURTENIS_DELETED       = 0                  ;
 SET O_INSTRUCTIE_DELETED        = 0                  ;    
 SET O_INSTRUCTIEKLASSE_DELETED  = 0                  ;    
 SET O_LUW_DELETED               = 0                  ;    
 SET O_LUW_TRANS_FOUT_DELETED    = 0                  ;    
 SET O_TRANSACTIE_DELETED        = 0                  ;    
 SET O_VALIDATIE_FOUT_DELETED    = 0                  ;            

 SET SPL_PGM_NAAM        = PROC_NAAM                  ;

 SET F_SLEUTELWAARDE1    = ' '                        ;
 SET F_SLEUTELWAARDE2    = ' '                        ;
 SET F_SLEUTELWAARDE3    = ' '                        ;
 SET F_BETREFT_TABEL     = '        '                 ;
 SET F_ACTIE             = '             '            ;
 SET F_OMSCHRIJVING_KORT = ' '                        ;
 SET F_OMSCHRIJVING_LANG = ' '                        ;

 SET F_BETREFT_TABEL     = 'S_PARAMETER_WAARDE  '    ;
 SET F_ACTIE             = 'SINGLE SELECT'           ;
 SET F_SLEUTELWAARDE1    = 'REPRII'                  ;
 SET F_SLEUTELWAARDE2    = 'COMD'                    ;
 SELECT SPW.INTG_PARM
   INTO SPW_INTG_PARM
   FROM S_PARAMETER_WAARDE        SPW
  WHERE SPW.PARAMETER_CATEGORIE = 'REPRII'
    AND SPW.PARAMETER_NAAM      = 'COMD'             ;
  -- Igv Not Found is het hier einde verhaal
  SET HV_COMMIT_NA_XX_DELS      = SPW_INTG_PARM      ;
  SET AANTAL_ROWS_UNCOMMITTED   = 0                  ;
                   
-- ===== Deleten van Children naar Parents (bottom-up) =========

-- Berichten (ID's) bepalen die bij een bestand-id horen
-- Die ID's zijn bepalend voor de child-tabellen
-- Dus dit MOET met een cursor
  SET HV_I_BESTAND_ID  = I_I_BESTAND_ID                          ;
  
  SET F_BETREFT_TABEL  = 'CUR_TE_SCHONEN_BERICHTEN'              ;
  SET F_ACTIE          = 'OPEN'                                  ;
  SET F_SLEUTELWAARDE1 = CHAR(HV_I_BESTAND_ID)                   ;
  SET F_SLEUTELWAARDE2 = ' '                                     ;
  SET F_SLEUTELWAARDE3 = ' '                                     ;
  OPEN  CUR_TE_SCHONEN_BERICHTEN                                 ;
  -- Igv open fout is het hier einde verhaal
  SET CUR_TE_SCHONEN_BERICHT_AT_END        = 'N'                 ;

  SET F_BETREFT_TABEL  = 'CUR_TE_SCHONEN_BERICHTEN'             ;
  SET F_ACTIE          = 'FIRST_FETCH'                          ;
  FETCH CUR_TE_SCHONEN_BERICHTEN
   INTO HV_I_BERICHT_ID                                         ;
   -- Igv Not Found wordt de end-of-cursor-ind gezet
  
   --===LOOPer START (per bericht-id) ========================== #
   WHILE CUR_TE_SCHONEN_BERICHT_AT_END = 'N' DO
    SET  O_BERICHT_SELECTED            = O_BERICHT_SELECTED + 1  ;
    SET F_SLEUTELWAARDE2 = CHAR(HV_I_BERICHT_ID)                 ;
    SET F_SLEUTELWAARDE3 = ' '                                   ;   

-- ======================== G_GEBEURTENIS start================
  SET F_BETREFT_TABEL  = 'G_GEBEURTENIS'             ;
  SET F_ACTIE          = 'SELECT OP TRAN_ID'         ;
-- Select om gebeurtenissen te bepalen via transacties
   SELECT COUNT(*)
     INTO HV_AANTAL_HIT_ROWS
     FROM G_GEBEURTENIS GEB
    WHERE GEB.CD_OBJECT_TYPE = 'IT'
      AND GEB.OBJECT_ID IN (
          SELECT TRAN.I_TRANSACTIE_ID 
            FROM I_TRANSACTIE TRAN
           WHERE TRAN.I_BERICHT_ID = HV_I_BERICHT_ID
                           );
  
 IF    HV_AANTAL_HIT_ROWS > 0 THEN
 -- als gebeurtenissen gevonden dan bepalen hoe te deleten
   IF  HV_AANTAL_HIT_ROWS < HV_COMMIT_NA_XX_DELS THEN
      SET F_ACTIE          = 'DELETE MASS'               ;   
      -- Past het aantal gebeurtenissen in een commit-scope?
      -- Dan lekker mass-deleten, ivm commit returnen
      DELETE FROM G_GEBEURTENIS GEB
       WHERE GEB.CD_OBJECT_TYPE = 'IT'
         AND GEB.OBJECT_ID IN (
             SELECT TRAN.I_TRANSACTIE_ID 
               FROM I_TRANSACTIE TRAN
              WHERE TRAN.I_BERICHT_ID = HV_I_BERICHT_ID) ;
      SET O_GEBEURTENIS_DELETED = 
          O_GEBEURTENIS_DELETED + HV_AANTAL_HIT_ROWS     ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_HIT_ROWS    ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                            ;     
      END IF ;
   ELSE
    SET F_ACTIE          = 'DELETE LOOPED'               ;
    SET   HV_AANTAL_DELETED_ROWS = 1   ;
    WHILE HV_AANTAL_DELETED_ROWS > 0 DO
      -- Past het aantal gebeurtenissen NIET in een commit-scope?
      -- Dan mass-deleten in blokken
      DELETE FROM G_GEBEURTENIS GEB
       WHERE GEB.CD_OBJECT_TYPE = 'IT'
         AND GEB.OBJECT_ID IN (
             SELECT TRAN.I_TRANSACTIE_ID 
               FROM I_TRANSACTIE TRAN
              WHERE TRAN.I_BERICHT_ID = HV_I_BERICHT_ID) 
       FETCH FIRST HV_COMMIT_NA_XX_DELS ROWS ONLY          ;
      GET CURRENT DIAGNOSTICS 
          HV_AANTAL_DELETED_ROWS = row_count               ;
      SET O_GEBEURTENIS_DELETED = 
          O_GEBEURTENIS_DELETED + HV_AANTAL_DELETED_ROWS   ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_DELETED_ROWS ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                              ;     
      END IF ;     
   END WHILE ;
  END IF ;
END IF ;  
-- ======================== G_GEBEURTENIS stop=================  
-- ======================== I_VALIDATIE_FOUT start================
  SET F_BETREFT_TABEL  = 'I_VALIDATIE_FOUT'          ;
  SET F_ACTIE          = 'COUNT'                     ;
-- Select om aantal rijen te deleten te bepalen
   SELECT COUNT(*)
     INTO HV_AANTAL_HIT_ROWS
     FROM I_VALIDATIE_FOUT IVF
    WHERE IVF.I_BERICHT_ID = HV_I_BERICHT_ID         ;
  
 IF    HV_AANTAL_HIT_ROWS > 0 THEN
 -- als rijen gevonden dan bepalen hoe te deleten
   IF  HV_AANTAL_HIT_ROWS < HV_COMMIT_NA_XX_DELS THEN
      SET F_ACTIE          = 'DELETE MASS'                      ;   
      -- Past het aantal gebeurtenissen in een commit-scope?
      -- Dan lekker mass-deleten, wel met een commit
      DELETE FROM I_VALIDATIE_FOUT IVF
       WHERE IVF.I_BERICHT_ID = HV_I_BERICHT_ID                 ;
      SET O_VALIDATIE_FOUT_DELETED = 
          O_VALIDATIE_FOUT_DELETED + HV_AANTAL_HIT_ROWS         ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_HIT_ROWS    ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                            ;     
      END IF ;
   ELSE
    SET F_ACTIE          = 'DELETE LOOPED'             ;
    SET   HV_AANTAL_DELETED_ROWS = 1   ;
    WHILE HV_AANTAL_DELETED_ROWS > 0 DO
      -- Past het aantal rijen NIET in een commit-scope?
      -- Dan mass-deleten in blokken
      DELETE FROM I_VALIDATIE_FOUT IVF
       WHERE IVF.I_BERICHT_ID = HV_I_BERICHT_ID          
       FETCH FIRST HV_COMMIT_NA_XX_DELS ROWS ONLY        ;
      GET CURRENT DIAGNOSTICS 
          HV_AANTAL_DELETED_ROWS = row_count             ;
      SET O_VALIDATIE_FOUT_DELETED = 
          O_VALIDATIE_FOUT_DELETED + HV_AANTAL_DELETED_ROWS     ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_DELETED_ROWS ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                              ;     
      END IF ; 
   END WHILE ;
  END IF ;
END IF ;  
-- ======================== I_VALIDATIE_FOUT stop=================
-- ======================== I_TRANSACTIE start================
  SET F_BETREFT_TABEL  = 'I_TRANSACTIE'          ;
  SET F_ACTIE          = 'COUNT'                     ;
-- Select om aantal rijen te deleten te bepalen
   SELECT COUNT(*)
     INTO HV_AANTAL_HIT_ROWS
     FROM I_TRANSACTIE ITR
    WHERE ITR.I_BERICHT_ID = HV_I_BERICHT_ID         ;
 
 IF    HV_AANTAL_HIT_ROWS > 0 THEN
 -- als rijen gevonden dan bepalen hoe te deleten
   IF  HV_AANTAL_HIT_ROWS < HV_COMMIT_NA_XX_DELS THEN
      SET F_ACTIE          = 'DELETE MASS'                      ;   
      -- Past het aantal gebeurtenissen in een commit-scope?
      -- Dan lekker mass-deleten, wel met een commit
      DELETE FROM I_TRANSACTIE ITR
       WHERE ITR.I_BERICHT_ID = HV_I_BERICHT_ID                 ;
      SET O_TRANSACTIE_DELETED = 
          O_TRANSACTIE_DELETED + HV_AANTAL_HIT_ROWS             ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_HIT_ROWS    ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                            ;     
      END IF ;
   ELSE
    SET F_ACTIE          = 'DELETE LOOPED'             ;
    SET   HV_AANTAL_DELETED_ROWS = 1   ;
    WHILE HV_AANTAL_DELETED_ROWS > 0 DO
      -- Past het aantal rijen NIET in een commit-scope?
      -- Dan mass-deleten in blokken
      DELETE FROM I_TRANSACTIE ITR
       WHERE ITR.I_BERICHT_ID = HV_I_BERICHT_ID          
       FETCH FIRST HV_COMMIT_NA_XX_DELS ROWS ONLY        ;
      GET CURRENT DIAGNOSTICS 
          HV_AANTAL_DELETED_ROWS = row_count             ;
      SET O_TRANSACTIE_DELETED = 
          O_TRANSACTIE_DELETED + HV_AANTAL_DELETED_ROWS  ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_DELETED_ROWS ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                              ;     
      END IF ; 
   END WHILE ;
  END IF ;
END IF ;  
-- ======================== I_TRANSACTIE stop=================
-- ======================== I_LUW_TRANS_FOUT start================
  SET F_BETREFT_TABEL  = 'I_LUW_TRANS_FOUT'          ;
  SET F_ACTIE          = 'COUNT'                     ;
-- Select om aantal rijen te deleten te bepalen
   SELECT COUNT(*)
     INTO HV_AANTAL_HIT_ROWS
     FROM I_LUW_TRANS_FOUT ITF
    WHERE ITF.I_BERICHT_ID = HV_I_BERICHT_ID         ;
 
 IF    HV_AANTAL_HIT_ROWS > 0 THEN
 -- als rijen gevonden dan bepalen hoe te deleten
   IF  HV_AANTAL_HIT_ROWS < HV_COMMIT_NA_XX_DELS THEN
      SET F_ACTIE          = 'DELETE MASS'                      ;   
      -- Past het aantal gebeurtenissen in een commit-scope?
      -- Dan lekker mass-deleten, wel met een commit
      DELETE FROM I_LUW_TRANS_FOUT ITF
       WHERE ITF.I_BERICHT_ID = HV_I_BERICHT_ID                 ;
      SET O_LUW_TRANS_FOUT_DELETED = 
          O_LUW_TRANS_FOUT_DELETED + HV_AANTAL_HIT_ROWS         ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_HIT_ROWS    ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                            ;     
      END IF ;    
   ELSE
    SET F_ACTIE          = 'DELETE LOOPED'               ;
    SET   HV_AANTAL_DELETED_ROWS = 1   ;
    WHILE HV_AANTAL_DELETED_ROWS > 0 DO
      -- Past het aantal rijen NIET in een commit-scope?
      -- Dan mass-deleten in blokken
      DELETE FROM I_LUW_TRANS_FOUT ITF
       WHERE ITF.I_BERICHT_ID = HV_I_BERICHT_ID          
       FETCH FIRST HV_COMMIT_NA_XX_DELS ROWS ONLY        ;
      GET CURRENT DIAGNOSTICS 
          HV_AANTAL_DELETED_ROWS = row_count             ;
      SET O_LUW_TRANS_FOUT_DELETED = 
          O_LUW_TRANS_FOUT_DELETED + HV_AANTAL_DELETED_ROWS ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_DELETED_ROWS ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                              ;     
      END IF ; 
   END WHILE ;
  END IF ;
END IF ;  
-- ======================== I_LUW_TRANS_FOUT stop=================    
-- ======================== I_LUW start================
  SET F_BETREFT_TABEL  = 'I_LUW'          ;
  SET F_ACTIE          = 'COUNT'                     ;
-- Select om aantal rijen te deleten te bepalen
   SELECT COUNT(*)
     INTO HV_AANTAL_HIT_ROWS
     FROM I_LUW ILU
    WHERE ILU.I_BERICHT_ID = HV_I_BERICHT_ID         ;
 
 IF    HV_AANTAL_HIT_ROWS > 0 THEN
 -- als rijen gevonden dan bepalen hoe te deleten
   IF  HV_AANTAL_HIT_ROWS < HV_COMMIT_NA_XX_DELS THEN
      SET F_ACTIE          = 'DELETE MASS'                      ;   
      -- Past het aantal gebeurtenissen in een commit-scope?
      -- Dan lekker mass-deleten, wel met een commit
      DELETE FROM I_LUW ILU
       WHERE ILU.I_BERICHT_ID = HV_I_BERICHT_ID                 ;
      SET O_LUW_DELETED = 
          O_LUW_DELETED + HV_AANTAL_HIT_ROWS                    ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_HIT_ROWS    ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                            ;     
      END IF ;      
   ELSE
    SET F_ACTIE          = 'DELETE LOOPED'               ;
    SET   HV_AANTAL_DELETED_ROWS = 1   ;
    WHILE HV_AANTAL_DELETED_ROWS > 0 DO
      -- Past het aantal rijen NIET in een commit-scope?
      -- Dan mass-deleten in blokken
      DELETE FROM I_LUW ILU
       WHERE ILU.I_BERICHT_ID = HV_I_BERICHT_ID          
       FETCH FIRST HV_COMMIT_NA_XX_DELS ROWS ONLY        ;
      GET CURRENT DIAGNOSTICS 
          HV_AANTAL_DELETED_ROWS = row_count             ;
      SET O_LUW_DELETED = 
          O_LUW_DELETED + HV_AANTAL_DELETED_ROWS         ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_DELETED_ROWS ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                              ;     
      END IF ;     
   END WHILE ;
  END IF ;
END IF ;  
-- ======================== I_LUW stop=================
-- ======================== I_INSTRUCTIEKLASSE start================
  SET F_BETREFT_TABEL  = 'I_INSTRUCTIEKLASSE'          ;
  SET F_ACTIE          = 'COUNT'                     ;
-- Select om aantal rijen te deleten te bepalen
   SELECT COUNT(*)
     INTO HV_AANTAL_HIT_ROWS
     FROM I_INSTRUCTIEKLASSE IIK
    WHERE IIK.I_BERICHT_ID = HV_I_BERICHT_ID         ;
 
 IF    HV_AANTAL_HIT_ROWS > 0 THEN
 -- als rijen gevonden dan bepalen hoe te deleten
   IF  HV_AANTAL_HIT_ROWS < HV_COMMIT_NA_XX_DELS THEN
      SET F_ACTIE          = 'DELETE MASS'                      ;   
      -- Past het aantal gebeurtenissen in een commit-scope?
      -- Dan lekker mass-deleten, wel met een commit
      DELETE FROM I_INSTRUCTIEKLASSE IIK
       WHERE IIK.I_BERICHT_ID = HV_I_BERICHT_ID                 ;
      SET O_INSTRUCTIEKLASSE_DELETED = 
          O_INSTRUCTIEKLASSE_DELETED + HV_AANTAL_HIT_ROWS       ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_HIT_ROWS    ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                            ;     
      END IF ;      
   ELSE
    SET F_ACTIE          = 'DELETE LOOPED'               ;
    SET   HV_AANTAL_DELETED_ROWS = 1   ;
    WHILE HV_AANTAL_DELETED_ROWS > 0 DO
      -- Past het aantal rijen NIET in een commit-scope?
      -- Dan mass-deleten in blokken
      DELETE FROM I_INSTRUCTIEKLASSE IIK
       WHERE IIK.I_BERICHT_ID = HV_I_BERICHT_ID          
       FETCH FIRST HV_COMMIT_NA_XX_DELS ROWS ONLY        ;
      GET CURRENT DIAGNOSTICS 
          HV_AANTAL_DELETED_ROWS = row_count             ;
      SET O_INSTRUCTIEKLASSE_DELETED = 
          O_INSTRUCTIEKLASSE_DELETED + HV_AANTAL_DELETED_ROWS   ; 
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_DELETED_ROWS ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                              ;     
      END IF ;      
   END WHILE ;
  END IF ;
END IF ;  
-- ======================== I_INSTRUCTIEKLASSE stop=================
-- ======================== I_INSTRUCTIE start================
  SET F_BETREFT_TABEL  = 'I_INSTRUCTIE'          ;
  SET F_ACTIE          = 'COUNT'                     ;
-- Select om aantal rijen te deleten te bepalen
   SELECT COUNT(*)
     INTO HV_AANTAL_HIT_ROWS
     FROM I_INSTRUCTIE INS
    WHERE INS.I_BERICHT_ID = HV_I_BERICHT_ID         ;
  
 IF    HV_AANTAL_HIT_ROWS > 0 THEN
 -- als rijen gevonden dan bepalen hoe te deleten
   IF  HV_AANTAL_HIT_ROWS < HV_COMMIT_NA_XX_DELS THEN
      SET F_ACTIE          = 'DELETE MASS'                      ;   
      -- Past het aantal gebeurtenissen in een commit-scope?
      -- Dan lekker mass-deleten, wel met een commit
      DELETE FROM I_INSTRUCTIE INS
       WHERE INS.I_BERICHT_ID = HV_I_BERICHT_ID                 ;
      SET O_INSTRUCTIE_DELETED = 
          O_INSTRUCTIE_DELETED + HV_AANTAL_HIT_ROWS             ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_HIT_ROWS    ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                            ;     
      END IF ;      
   ELSE
    SET F_ACTIE          = 'DELETE LOOPED'               ;
    SET   HV_AANTAL_DELETED_ROWS = 1   ;
    WHILE HV_AANTAL_DELETED_ROWS > 0 DO
      -- Past het aantal rijen NIET in een commit-scope?
      -- Dan mass-deleten in blokken
      DELETE FROM I_INSTRUCTIE INS
       WHERE INS.I_BERICHT_ID = HV_I_BERICHT_ID          
       FETCH FIRST HV_COMMIT_NA_XX_DELS ROWS ONLY        ;
      GET CURRENT DIAGNOSTICS 
          HV_AANTAL_DELETED_ROWS = row_count             ;
      SET O_INSTRUCTIE_DELETED = 
          O_INSTRUCTIE_DELETED + HV_AANTAL_DELETED_ROWS         ;
      SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED
                                  + HV_AANTAL_DELETED_ROWS ;
      IF  AANTAL_ROWS_UNCOMMITTED > HV_COMMIT_NA_XX_DELS THEN
      -- Ik heb een hekel aan goto's, maar dit blok komt zo vaak voor...
          GOTO TIJDVOORCOMMIT                              ;     
      END IF ;     
   END WHILE ;
  END IF ;
END IF ;  
-- ======================== I_INSTRUCTIE stop=================
  
  -- DELETE op BERICHT child
  SET F_ACTIE          = 'DELETE'                               ;
  SET F_BETREFT_TABEL  = 'I_BERICHT'                            ;
  DELETE FROM I_BERICHT                    
   WHERE      I_BERICHT_ID = HV_I_BERICHT_ID                    ;
   -- moet er zijn, is voorwaarde in select
  SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED + 1     ;
  SET O_BERICHT_DELETED       = O_BERICHT_DELETED + 1           ;

  -- Next Fetch
  SET F_BETREFT_TABEL  = 'CUR_TE_SCHONEN_BERICHTEN'             ;
  SET F_ACTIE          = 'NEXT FETCH'                           ;
  SET F_SLEUTELWAARDE1 = CHAR(HV_I_BESTAND_ID)                  ;
  SET F_SLEUTELWAARDE2 = ' '                                    ;
  SET F_SLEUTELWAARDE3 = ' '                                    ;
  FETCH CUR_TE_SCHONEN_BERICHTEN
   INTO HV_I_BERICHT_ID                                         ;
   -- Igv Not Found wordt de end-of-cursor-ind gezet

   END WHILE; -- Einde loop cursor
   --===LOOPer STOPT (per bericht-id) ============================

  -- Sluit de CURSOR
  SET F_BETREFT_TABEL  = 'CUR_TE_SCHONEN_BERICHTEN'              ;
  SET F_ACTIE          = 'CLOSE'                                 ;
  SET F_SLEUTELWAARDE1 = CHAR(HV_I_BESTAND_ID)                   ;
  SET F_SLEUTELWAARDE2 = ' '                                     ;
  SET F_SLEUTELWAARDE3 = ' '                                     ;
  CLOSE CUR_TE_SCHONEN_BERICHTEN;
  -- Igv close fout is het hier einde verhaal
  
  -- DELETE op BESTAND (alle kinderen verwijderd)
  SET F_ACTIE          = 'DELETE'                               ;
  SET F_BETREFT_TABEL  = 'I_BESTAND'                            ;
  SET F_SLEUTELWAARDE1 = CHAR(HV_I_BESTAND_ID)                  ;
  SET F_SLEUTELWAARDE2 = ' '                                    ;
  DELETE FROM I_BESTAND                    
   WHERE      I_BESTAND_ID = HV_I_BESTAND_ID                    ;
   -- moet er zijn, is voorwaarde in select
  SET AANTAL_ROWS_UNCOMMITTED = AANTAL_ROWS_UNCOMMITTED + 1     ;
  SET O_BESTAND_DELETED       = O_BESTAND_DELETED + 1           ;

 -- KIJK EENS! Geen COMMIT!
 -- Status op G(ereed), ik ben er klaar mee, 
 -- Java moet nog wel een laatste commit doen!
 SET O_STATUS_BUSY_OR_READY = 'G'                               ;
 SET O_COMMITS               = O_COMMITS + 1                    ;
 SET AANTAL_ROWS_UNCOMMITTED = 0                                ; 
 GOTO AFRONDEN                                                  ;

TIJDVOORCOMMIT:
      SET F_BETREFT_TABEL  = 'CUR_TE_SCHONEN_BERICHTEN'         ;
      SET F_ACTIE          = 'CLOSE'                            ;
      SET F_SLEUTELWAARDE1 = CHAR(HV_I_BESTAND_ID)              ;
      SET F_SLEUTELWAARDE2 = ' '                                ;
      SET F_SLEUTELWAARDE3 = ' '                                ;
      CLOSE CUR_TE_SCHONEN_BERICHTEN                            ;
      --SET O_COMMITS               = O_COMMITS + 1               ;
      SET AANTAL_ROWS_UNCOMMITTED = 0                           ;
      --RETURN 0                                                  ;     

AFRONDEN:
 -- Doorlooptijd berekenen
 SET HV_DOORLOOP_IN_MINUTEN =
     TIMESTAMPDIFF(1, CHAR(
     CURRENT TIMESTAMP - HV_START_TIMESTAMP)) / 60000000        ;

 -- Informational Splunk schrijven per bestand
 SET SPLI_OPT_RUBR01_TXT = 'VerwijderI_Bestand'                 ;
 SET SPLI_OPT_RUBR01_VAL = Strip(CHAR(HV_I_BESTAND_ID)) 
     concat ' Aantal ' concat Strip(CHAR(O_BESTAND_DELETED))
     concat ' Status ' concat O_STATUS_BUSY_OR_READY            ;
 SET SPLI_OPT_RUBR02_TXT = 'DeletedBER&INS'                     ;
 SET SPLI_OPT_RUBR02_VAL = CHAR(O_BERICHT_DELETED) 
         concat ' ' concat CHAR(O_INSTRUCTIE_DELETED)           ;
 SET SPLI_OPT_RUBR03_TXT = 'DeletedIKL&LUW'                     ;
 SET SPLI_OPT_RUBR03_VAL = CHAR(O_INSTRUCTIEKLASSE_DELETED)                  
         concat ' ' concat CHAR(O_LUW_DELETED)                  ;
 SET SPLI_OPT_RUBR04_TXT = 'DeletedTRN&GEB'                     ;
 SET SPLI_OPT_RUBR04_VAL = CHAR(O_TRANSACTIE_DELETED)               
         concat ' ' concat CHAR(O_GEBEURTENIS_DELETED)          ;
 SET SPLI_OPT_RUBR05_TXT = 'DeletedTRF&VFT'                     ;
 SET SPLI_OPT_RUBR05_VAL = CHAR(O_LUW_TRANS_FOUT_DELETED)              
         concat ' ' concat CHAR(O_VALIDATIE_FOUT_DELETED)       ;
 SET SPLI_OPT_RUBR06_TXT = 'Db2-schema'                         ;
 SET SPLI_OPT_RUBR06_VAL = WRK_DB2_SCHEMA                       ;
 SET SPLI_OPT_RUBR07_TXT = '#COMMITs+Doorloop-Min'              ;
 SET SPLI_OPT_RUBR07_VAL = CHAR(O_COMMITS)      concat ' '
                   concat  CHAR(HV_DOORLOOP_IN_MINUTEN)         ;
 CALL SP_WRITE_SPLUNK_INFO_V2(SPLI_MESSAGE_ID
                          ,SPLI_INFO_NAAM
                          ,SPLI_OPT_RUBR01_TXT
                          ,SPLI_OPT_RUBR01_VAL
                          ,SPLI_OPT_RUBR02_TXT
                          ,SPLI_OPT_RUBR02_VAL
                          ,SPLI_OPT_RUBR03_TXT
                          ,SPLI_OPT_RUBR03_VAL
                          ,SPLI_OPT_RUBR04_TXT
                          ,SPLI_OPT_RUBR04_VAL
                          ,SPLI_OPT_RUBR05_TXT
                          ,SPLI_OPT_RUBR05_VAL
                          ,SPLI_OPT_RUBR06_TXT
                          ,SPLI_OPT_RUBR06_VAL
                          ,SPLI_OPT_RUBR07_TXT
                          ,SPLI_OPT_RUBR07_VAL
                          ,SPLI_OPT_RUBR08_TXT
                          ,SPLI_OPT_RUBR08_VAL
                          ,SPLI_OPT_RUBR09_TXT
                          ,SPLI_OPT_RUBR09_VAL
                          ,SPLI_OPT_RUBR10_TXT
                          ,SPLI_OPT_RUBR10_VAL
                          ,SPLI_OPT_RUBR11_TXT
                          ,SPLI_OPT_RUBR11_VAL
                          ,SPLI_OPT_RUBR12_TXT
                          ,SPLI_OPT_RUBR12_VAL
                          ,SPLI_OPT_RUBR13_TXT
                          ,SPLI_OPT_RUBR13_VAL
                          ,SPLI_OPT_RUBR14_TXT
                          ,SPLI_OPT_RUBR14_VAL)                 ;

 --SIGNAL SQLSTATE '66666' SET MESSAGE_TEXT = 'Tbv testen'      ;

END HOOFD;    -- laatste END (van het hoofd-compound)

END @
--#SET TERMINATOR ;
COMMIT;

-- Wordt door Java-app gecalled
GRANT EXECUTE ON PROCEDURE SP_REPAIR_I_INSTRUCTIE TO $EPFS60 ;

