SET CURRENT SQLID = RLHE01;
SET SCHEMA RLHE01;
--#SET TERMINATOR @
 -- 
  -- PROC zonder PARM'S (voor OTA only)
  CREATE PROCEDURE SP_OTA_ONLY_TOTAL_CLEANUP (
           --OUT O_RETURN               INTEGER
          --,OUT F_OMSCHRIJVING_LANG    VARCHAR(260)    
	)
   --
   --
   -- Deze STORED PROCEDURE verwijdert alle (test)data 
   -- In eerste instantie bedoeld de A99 te schonen na proefmigraties,
   --    maar ook bruikbaar in de andere acct-omgevingen (OTA-only).
   -- Ter voorkoming van misbruik op Productie zijn meerdere 
   --    mechanismen ingebouwd.
   -- Er wordt zowel in goed als fout situaties naar Splunk
   --    index="mfpublic" message_id="RLHCLOTA"
   --
          -- N.B. onderstaande SETTINGS zijn GEWOGEN
          VERSION      V1
          LANGUAGE     SQL
          NOT          DETERMINISTIC
          MODIFIES     SQL       DATA
          DYNAMIC      RESULT    SETS  0
          DISABLE      DEBUG     MODE
          PARAMETER    CCSID     UNICODE
          QUALIFIER    RLHE01  ---
          ---QUALIFIER    RLHO10  ---
          PACKAGE      OWNER     RLHE  ---
          ---PACKAGE      OWNER     RLHO10  ---
          -- BENODIGDE ASUTIME KAN BEST HOOG ZIJN, 
          -- HEEFT IE BLIJKBAAR NODIG
          ---ASUTIME      LIMIT 500000 ---     
          ASUTIME      LIMIT 2000000000 ---
          COMMIT       ON RETURN YES
          -- WLM ENVIRONMENT NIET NODIG:
          -- EXECUTED IN THE DBM1 ADDRESS SPACE
          -- MOET ER VERPLICHT ZIJN FOR DEBUG
          WLM ENVIRONMENT FOR DEBUG MODE RLHNOP ---
		  INHERIT      SPECIAL REGISTERS  
          DEFER        PREPARE
          CURRENT      DATA      NO
          DEGREE       ANY
          CONCURRENT   ACCESS RESOLUTION
                       USE CURRENTLY COMMITTED
          DYNAMICRULES RUN
          WITH EXPLAIN  ---
          ---WITH         EXPLAIN ---
          WITHOUT      IMMEDIATE WRITE
          ISOLATION    LEVEL     CS
          WITH         KEEP      DYNAMIC
          -- MAG NIET: SQL PATH RLHE01
          -- QUERY     ACCELERATION NONE
          -- GET_ACCEL_ARCHIVE NO
          RELEASE      AT        DEALLOCATE
          REOPT        ONCE
          VALIDATE     BIND
          ROUNDING     DEC_ROUND_HALF_EVEN
          DECIMAL(31)
		  BUSINESS_TIME SENSITIVE NO       
		  SYSTEM_TIME SENSITIVE NO         
		  ARCHIVE SENSITIVE YES             
		  ---CONCENTRATE STATEMENTS OFF

BEGIN
  DECLARE O_RETURN               INTEGER      ;
  DECLARE F_OMSCHRIJVING_LANG    VARCHAR(260) ;

  DECLARE PROC_NAAM              VARCHAR(25)
          DEFAULT 'SP_OTA_ONLY_TOTAL_CLEANUP'         ;	  
  DECLARE SQLCODE                INTEGER      DEFAULT 0     ;
  DECLARE SQLSTATE               CHAR(5)      DEFAULT 0     ;
  DECLARE SAVE_SQLCODE           INTEGER      DEFAULT 0     ;
  DECLARE SAVE_SQLSTATE          CHAR(5)      DEFAULT ' '   ;
  DECLARE SAVE_ERRMSG            VARCHAR(260) DEFAULT ' '   ;

  DECLARE WRK_DB2_SCHEMA         CHAR(6)
                                 DEFAULT 'RLHE01'   ; ---
  ---                            DEFAULT 'RLHO10'   ; ---
  DECLARE HV_DB2_SCHEMA_PROD     CHAR(6)
                                 DEFAULT 'RLHE01'           ;

  DECLARE TABLES_COUNTED         INTEGER DEFAULT 0          ;
  DECLARE ALL_ROWS_DELETED       CHAR(1) DEFAULT 'N'        ;
  DECLARE MAX_2_DELETE_AT_ONCE   INTEGER DEFAULT 10000      ; 
  DECLARE HV_Row_Count           DECIMAL(31 , 0)            ;
  DECLARE HV_DELETED_ROWS_SO_FAR INTEGER DEFAULT 0          ;
  DECLARE HV_COMMITS_BY_THEN	 INTEGER DEFAULT 0          ; 
  DECLARE HV_TB_NULL_NAME		 VARCHAR(200)               ;
  
  DECLARE O_COMMITS              INTEGER                    ;
  DECLARE F_ACTIE                VARCHAR(60)                ;
  DECLARE F_SOORT_FOUTCODE       VARCHAR(10)                ;
  DECLARE F_BETREFT_TABEL        VARCHAR(40)                ;
  DECLARE F_SLEUTELWAARDE1       VARCHAR(60)                ;
  DECLARE F_SLEUTELWAARDE2       VARCHAR(60)                ;
  DECLARE F_SLEUTELWAARDE3       VARCHAR(60)                ;
  DECLARE F_OMSCHRIJVING_KORT    VARCHAR(035)               ;
  --DECLARE F_OMSCHRIJVING_LANG    VARCHAR(260)               ;

  -- Declaraties voor SP_WRITE_SPLUNK igv foutsituaties
  DECLARE SPL_MESSAGE_ID      VARCHAR(08) DEFAULT 'CLOTA'  ;
  DECLARE SPL_PGM_NAAM        VARCHAR(45)                   ;
  DECLARE SPL_SOORT_FOUTCODE  VARCHAR(08) DEFAULT 'SQL'     ;
  DECLARE SPL_FOUTCODE_NUM    INTEGER                       ;
  DECLARE SPL_FOUTCODE_CHAR   VARCHAR(15) DEFAULT ' '       ;
  DECLARE SPL_FREE_TEXT       VARCHAR(200)                  ;

  -- Declaraties voor SP_WRITE_SPLUNK_INFO (statistics)
  DECLARE SPLI_MESSAGE_ID     VARCHAR(08) DEFAULT 'CLOTA'  ;
  DECLARE SPLI_INFO_NAAM      VARCHAR(45)
                              DEFAULT 'OTA_CLEANUP'         ;
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

  -- Tabel OTA_ONLY_TABLE_DEL_VOLGORDE:
  DECLARE HV_DELETE_ALS_NUMMER	SMALLINT					;
  DECLARE HV_TABELNAAM			VARCHAR(72)					;
  DECLARE HV_TABELNAAM_HIST		VARCHAR(72)					;
  
  DECLARE My_Dynamic_SQL_Stmt_LOCK VARCHAR(160)             ;
  DECLARE My_Dynamic_SQL_Stmt_DEL  VARCHAR(160)             ;
  
  DECLARE HV_START_TIMESTAMP          TIMESTAMP             ;
  DECLARE HV_DOORLOOP_IN_MINUTEN      INTEGER               ;

  DECLARE HV_RIJ_DELETED              INTEGER DEFAULT 1     ;
  DECLARE HV_COMMIT_NA_XX_DELS        INTEGER DEFAULT 10000 ;

  DECLARE CUR_TABELLEN_OP_VOLGORDE_AT_END	CHAR(1)	DEFAULT 'N' ;
  DECLARE CUR_ONVERMELDE_TABELLEN_AT_END	CHAR(1)	DEFAULT 'N' ;
  
  -- Lijst met tabellen te schonen, op volgorde van (relationele) volgorde
  DECLARE CUR_TABELLEN_OP_VOLGORDE CURSOR
   WITH    HOLD   -- ivm tussentijdse commits
   WITHOUT RETURN -- interne cursor, geen result set
   -- WITH RETURN kan gemakkelijk zijn bij testen igv vastlopen
   FOR
   SELECT DELETE_ALS_NUMMER,TABELNAAM,TABELNAAM_HIST	
     FROM OTA_ONLY_TABLE_DEL_VOLGORDE
    ORDER BY DELETE_ALS_NUMMER,TABELNAAM
          ;  -- END CURSOR DECL

  -- Lijst met tabellen te schonen, op volgorde van (relationele) volgorde
  DECLARE CUR_ONVERMELDE_TABELLEN CURSOR
   WITH    HOLD   -- ivm tussentijdse commits
   WITHOUT RETURN -- interne cursor, geen result set
   -- WITH RETURN kan gemakkelijk zijn bij testen igv vastlopen
   FOR
   -- tabellen die er wel zijn, maar niet geschoond worden
   With Alle_Tabellen as 
    (Select name                    
       from sysibm.systables
      where creator = WRK_DB2_SCHEMA
        and type    = 'T'
        and name not like 'DSN%'
      order by 1  
      ) 
  Select name as Ik_Mis_Tabel
    from Alle_Tabellen
   where name not in (
         Select TABELNAAM
           from OTA_ONLY_TABLE_DEL_VOLGORDE
         )
   With UR
          ;  -- END CURSOR DECL

DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    -- COMMIT EN ROLLBACK MAG OMDAT DEZE StoPro
    -- DOOR EEN COBOL-DRIVER WORDT AANGEROEPEN
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
    -- ROLLBACK tbv consistente situatie
    ROLLBACK ;
    CALL SP_WRITE_SPLUNK(SPL_MESSAGE_ID,SPL_PGM_NAAM,SPL_SOORT_FOUTCODE
        ,SPL_FOUTCODE_NUM,SPL_FOUTCODE_CHAR,SPL_FREE_TEXT);
    Update OTA_ONLY_TABLE_DEL_VOLGORDE 
       set RUNTIME_MESSAGE = F_OMSCHRIJVING_LANG
     where TABELNAAM  = HV_TABELNAAM;    COMMIT;
    RETURN O_RETURN ;
  END ; -- End Declare

  DECLARE CONTINUE HANDLER FOR NOT FOUND
  -- ALS  EXIT     HANDLER KAN NIET, SQLCODE 100 MAG SOMS WEL
  BEGIN
  CASE  F_BETREFT_TABEL
  WHEN 'CUR_TABELLEN_OP_VOLGORDE' THEN
   -- Dit is een legitieme end-of-cursor
   SET CUR_TABELLEN_OP_VOLGORDE_AT_END        = 'J'             ;
   -- en continue
  WHEN 'DEL_ON_TABLE' THEN
   -- Dit is een legitieme end-of-cursor
   SET ALL_ROWS_DELETED				          = 'J'             ;
   -- en continue naar next table
  WHEN 'Bestaat-Tabel?' THEN
   -- Dit is een test. Als je hier komt bestaat de tabel niet.
    Update OTA_ONLY_TABLE_DEL_VOLGORDE 
       set RUNTIME_MESSAGE = 'Tabel komt niet voor. Skipped'
     where TABELNAAM  = HV_TABELNAAM; 
    SET F_BETREFT_TABEL  = 'Tabel bestaat niet'           ;
   -- en continue naar next table
  WHEN 'CUR_ONVERMELDE_TABELLEN' THEN
   -- Dit is een legitieme end-of-cursor
   SET CUR_ONVERMELDE_TABELLEN_AT_END        = 'J'        ;
   -- en continue
  WHEN 'tbnaam' THEN
   -- Voor deze tabel mag geen RNF optreden, zonder parms geen run
   SET O_RETURN            = +100                         ;
   SET F_OMSCHRIJVING_KORT =
      'Parameter afwezig        '                         ;
   SET F_OMSCHRIJVING_LANG = 'Parameter =' concat
       F_SLEUTELWAARDE1 concat ' ' concat
       F_SLEUTELWAARDE2 concat
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

HOOFD:BEGIN

If WRK_DB2_SCHEMA = HV_DB2_SCHEMA_PROD Then
   SIGNAL SQLSTATE '66666' SET MESSAGE_TEXT = 'Nooit op PRODUCTIE!!'  ;
End If ;                                   

 SET F_SOORT_FOUTCODE    = 'SQLCODE'                  ;
 SET O_RETURN            = 0                          ;
 SET HV_START_TIMESTAMP  = CURRENT TIMESTAMP          ;

 SET O_COMMITS           = 0                          ;

 SET SPL_PGM_NAAM        = PROC_NAAM                  ;

 SET F_SLEUTELWAARDE1    = ' '                        ;
 SET F_SLEUTELWAARDE2    = ' '                        ;
 SET F_SLEUTELWAARDE3    = ' '                        ;
 SET F_BETREFT_TABEL     = '        '                 ;
 SET F_ACTIE             = '             '            ;
 SET F_OMSCHRIJVING_KORT = ' '                        ;
 SET F_OMSCHRIJVING_LANG = ' '                        ;
 
-- Tabel init (mass-update) 	 	 	    
Update OTA_ONLY_TABLE_DEL_VOLGORDE 
   set DELETED_ROWS_SO_FAR = 0
      ,COMMITS_BY_THEN     = 0
      ,AND_FINISHED        = 'N'
      ,TS_STARTED          = NULL
      ,RUNTIME_MESSAGE     = NULL;
Delete From OTA_ONLY_TABLE_DEL_VOLGORDE
 Where DELETE_ALS_NUMMER = 666;                       
COMMIT;

 -- ================= Lees tabel-tabel in interne tabel ================
 SET F_BETREFT_TABEL  = 'CUR_TABELLEN_OP_VOLGORDE'                    ;
 SET F_ACTIE          = 'OPEN'                                  ;
 SET F_SLEUTELWAARDE1 = ''                                      ;
 SET F_SLEUTELWAARDE2 = ''				                        ;
 SET F_SLEUTELWAARDE3 = ' '                                     ;
 OPEN  CUR_TABELLEN_OP_VOLGORDE                                       ;
 -- Igv open fout is het hier einde verhaal
 SET CUR_TABELLEN_OP_VOLGORDE_AT_END        = 'N'                     ;

 SET F_BETREFT_TABEL  = 'CUR_TABELLEN_OP_VOLGORDE'              ;
 SET F_ACTIE          = 'FIRST_FETCH'                           ;
 FETCH CUR_TABELLEN_OP_VOLGORDE
  INTO HV_DELETE_ALS_NUMMER,HV_TABELNAAM,HV_TABELNAAM_HIST
  ;
 -- Igv Not Found wordt de end-of-cursor-ind gezet

 -- Loop cursor lezen tot at-end
--   --===LOOPer START ============================
WHILE CUR_TABELLEN_OP_VOLGORDE_AT_END = 'N' DO
	SET  TABLES_COUNTED               = TABLES_COUNTED + 1        ;

	Update OTA_ONLY_TABLE_DEL_VOLGORDE 
       set TS_STARTED = Current_Timestamp
     where TABELNAAM  = HV_TABELNAAM;    COMMIT;
     
    -- Kijk of de tabel bestaat, zoniet melden en overslaan
    SET F_BETREFT_TABEL  = 'Bestaat-Tabel?'              ;
    Select  name
       into HV_TB_NULL_NAME           
       from sysibm.systables
      where creator = WRK_DB2_SCHEMA
        and type    = 'T'
        and name    = HV_TABELNAAM
      With UR; 
    If F_BETREFT_TABEL = 'Tabel bestaat niet' Then
       GoTo Als_Tabel_Skipped ;
    End If ;	
     
	SET F_BETREFT_TABEL  = HV_TABELNAAM				              ;
	SET F_ACTIE          = 'LOCK TABLE'                           ;
	Set My_Dynamic_SQL_Stmt_LOCK = 'LOCK TABLE ' concat Strip(HV_TABELNAAM) 
									concat ' IN EXCLUSIVE MODE '  ;
    EXECUTE IMMEDIATE My_Dynamic_SQL_Stmt_LOCK					  ;
      
    Set F_BETREFT_TABEL   = 'DEL_ON_TABLE'                        ;
    Set My_Dynamic_SQL_Stmt_DEL  = 'DELETE FROM '  
									concat Strip(HV_TABELNAAM)
									concat ' FETCH FIRST '
									concat Char(MAX_2_DELETE_AT_ONCE) 
									concat ' ROWS ONLY ' ;									
  ----Set   MOVE_TO_ARCHIVE   = 'N' ; werkt enkel bij archived tables							
  Set   ALL_ROWS_DELETED       = 'N' ;    
  Set   HV_DELETED_ROWS_SO_FAR =  0  ;
  Set   HV_COMMITS_BY_THEN     =  0  ;
  While ALL_ROWS_DELETED  = 'N' Do
  	SET F_ACTIE          = 'LOCK TABLE'         ;
  	EXECUTE IMMEDIATE My_Dynamic_SQL_Stmt_LOCK  ;
  	SET F_ACTIE           = 'DELETE # ROWS'     ;
    EXECUTE IMMEDIATE My_Dynamic_SQL_Stmt_DEL	;
    GET DIAGNOSTICS HV_Row_Count = Row_Count ;
    Set HV_DELETED_ROWS_SO_FAR = 
        HV_DELETED_ROWS_SO_FAR + HV_Row_Count ;
    Set HV_COMMITS_BY_THEN     = HV_COMMITS_BY_THEN + 1  ;
    Update OTA_ONLY_TABLE_DEL_VOLGORDE 
       set DELETED_ROWS_SO_FAR = HV_DELETED_ROWS_SO_FAR
          ,COMMITS_BY_THEN     = HV_COMMITS_BY_THEN  
     where TABELNAAM  = HV_TABELNAAM;
    COMMIT;
    SET O_COMMITS = O_COMMITS + 1 ;
  End While ;	

Als_Tabel_Skipped:
  Update OTA_ONLY_TABLE_DEL_VOLGORDE 
     set AND_FINISHED = 'Y'  
   where TABELNAAM  = HV_TABELNAAM;   COMMIT;	
  
  If HV_TABELNAAM_HIST <> '' Then 
  	 Set My_Dynamic_SQL_Stmt_DEL  = 'TRUNCATE ' concat Strip(HV_TABELNAAM_HIST) 
  			concat ' REUSE STORAGE IGNORE DELETE TRIGGERS IMMEDIATE ' ;
  	 EXECUTE IMMEDIATE My_Dynamic_SQL_Stmt_DEL	; 		
  End If ;													
  
	SET F_BETREFT_TABEL  = 'CUR_TABELLEN_OP_VOLGORDE'             ;
	SET F_ACTIE          = 'NEXT FETCH'                           ;
	SET F_SLEUTELWAARDE1 = ' '                                    ;
	SET F_SLEUTELWAARDE2 = ' '                                    ;
	SET F_SLEUTELWAARDE3 = ' '                                    ;
	FETCH CUR_TABELLEN_OP_VOLGORDE
		INTO HV_DELETE_ALS_NUMMER,HV_TABELNAAM,HV_TABELNAAM_HIST
		;
		-- Igv Not Found wordt de end-of-cursor-ind gezet

END WHILE; -- Einde loop cursor
   --===LOOPer STOPT  ============================

  -- Sluit de CURSOR
  SET F_BETREFT_TABEL  = 'CUR_TABELLEN_OP_VOLGORDE'              ;
  SET F_ACTIE          = 'CLOSE'                                 ;
  SET F_SLEUTELWAARDE1 = ' '                                     ;
  SET F_SLEUTELWAARDE2 = ' '                                     ;
  SET F_SLEUTELWAARDE3 = ' '                                     ;
  CLOSE CUR_TABELLEN_OP_VOLGORDE;
  -- Igv close fout is het hier einde verhaal

-- END WHILE; -- Einde loop cursor

 -- KIJK EENS! een COMMIT!
 COMMIT                                                         ;
	
-- Toegift: Bepalen welke tabellen niet genoemd worden voor schoning
--          en deze vermelden in de tabel
 SET F_BETREFT_TABEL  = 'CUR_ONVERMELDE_TABELLEN'               ;
 SET F_ACTIE          = 'OPEN'                                  ;
 SET F_SLEUTELWAARDE1 = ''                                      ;
 SET F_SLEUTELWAARDE2 = ''				                        ;
 SET F_SLEUTELWAARDE3 = ''                                      ;
 OPEN  CUR_ONVERMELDE_TABELLEN                                  ;
 -- Igv open fout is het hier einde verhaal

 SET F_ACTIE          = 'FIRST_FETCH'                           ;
 FETCH CUR_ONVERMELDE_TABELLEN
  INTO HV_TABELNAAM
  ;
 -- Igv Not Found wordt de end-of-cursor-ind gezet

 WHILE CUR_ONVERMELDE_TABELLEN_AT_END = 'N' DO
   INSERT into OTA_ONLY_TABLE_DEL_VOLGORDE 
          (DELETE_ALS_NUMMER,TABELNAAM,RUNTIME_MESSAGE) 
    values( 666 ,HV_TABELNAAM,'Tabel bestaat, hoeft niet geschoond?') ;
    
    SET F_ACTIE          = 'NEXT FETCH'                         ;
    FETCH CUR_ONVERMELDE_TABELLEN
     INTO HV_TABELNAAM                                          ;

 END WHILE; -- Einde loop cursor

 SET F_ACTIE          = 'CLOSE'                                 ;
 CLOSE CUR_ONVERMELDE_TABELLEN                                  ;
 -- Igv close fout is het hier einde verhaal
 COMMIT;

END HOOFD;    -- laatste END (van het hoofd-compound)

END @
--#SET TERMINATOR ;
