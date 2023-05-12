SET CURRENT SQLID = RLH_DB_OBJECTS_A99E01;
SET SCHEMA RLH_DB_OBJECTS_A99E01;
--#SET TERMINATOR @
--
CREATE OR REPLACE TRIGGER SPWBI000
-- Deze trigger voorkomt het toevoegen van WAARDEn in de tabel
-- waarbij geen bijbehorend TYPE (combinatie CATEGORIE/NAAM) bestaat
    BEFORE INSERT ON S_PARAMETER_WAARDE
    REFERENCING  NEW AS NEWSPW
    FOR EACH ROW
----
    -- N.B. onderstaande SETTINGS zijn GEWOGEN
    DISABLE     DEBUG MODE
    APPLICATION ENCODING SCHEME  UNICODE
    QUALIFIER    knaller
    ASUTIME      NO LIMIT
    WLM ENVIRONMENT FOR DEBUG MODE RLHNOP
    CURRENT      DATA      NO
    CONCURRENT   ACCESS RESOLUTION
                 USE CURRENTLY COMMITTED
    DYNAMICRULES RUN
    WITH EXPLAIN
    WITHOUT      IMMEDIATE WRITE
    ISOLATION    LEVEL     CS
    RELEASE      AT        COMMIT
    ROUNDING     DEC_ROUND_HALF_EVEN
    DECIMAL(31)
    BUSINESS_TIME SENSITIVE YES
    SYSTEM_TIME   SENSITIVE NO
----
BEGIN
 DECLARE TYPEFOUND SMALLINT default NULL;
  SELECT COUNT(*)
    INTO TYPEFOUND
    FROM S_PARAMETER_TYPE
   WHERE (ID                   = NEWSPW.PARAMETER_TYPE_ID
     AND  PARAMETER_NAAM       = NEWSPW.PARAMETER_NAAM
     AND  PARAMETER_CATEGORIE  = NEWSPW.PARAMETER_CATEGORIE );
   IF TYPEFOUND <> 1 THEN
      signal sqlstate '99SPW'
      set message_text = 'Parmwaarde heeft geen correct ParmType' ;
   END IF ;
   END  @
--#SET TERMINATOR ;

