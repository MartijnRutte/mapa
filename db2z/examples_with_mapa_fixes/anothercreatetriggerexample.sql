SET CURRENT SQLID = RLH_DB_OBJECTS_A99E01;
SET SCHEMA RLH_DB_OBJECTS_A99E01;
--
-- Triggers op colums met DOMEINwaarden; check ipv FK's die niet nauwkeurig genoeg zijn.
--
--
--#SET TERMINATOR @

CREATE OR REPLACE TRIGGER STVBI000 
	BEFORE INSERT ON S_TIJDVAK
	REFERENCING  NEW AS NEWDOM
	FOR EACH ROW
--
	DISABLE      DEBUG     MODE    
	QUALIFIER    knaller ---
	ASUTIME      LIMIT     9000    
	-- WLM ENVIRONMENT NIET NODIG:                   
	-- EXECUTED IN THE DBM1 ADDRESS SPACE            
	-- MOET ER VERPLICHT ZIJN FOR DEBUG              
	WLM ENVIRONMENT FOR DEBUG MODE RLHNOP  
	CONCURRENT   ACCESS RESOLUTION
	         USE CURRENTLY COMMITTED      
	DYNAMICRULES RUN   
	APPLICATION  ENCODING SCHEME UNICODE  
	WITH      EXPLAIN ---
	WITHOUT      IMMEDIATE WRITE    
	ISOLATION    LEVEL     CS    
	-- MAG NIET: SQL PATH knaller 
	RELEASE      AT        COMMIT     
	ROUNDING     DEC_ROUND_HALF_EVEN  
	DECIMAL(31)      
	NOT          SECURED
	BUSINESS_TIME SENSITIVE YES
	SYSTEM_TIME   SENSITIVE NO
	ARCHIVE       SENSITIVE NO
	CONCENTRATE   STATEMENTS WITH LITERALS
--
   WHEN (NEWDOM.AANGIFTEFREQUENTIE IS NOT NULL)
BEGIN 
 DECLARE DOMFOUND VARCHAR(5) default NULL;
  SELECT DOMEIN_CODE
    INTO DOMFOUND
    FROM S_DOMEIN
	 FOR BUSINESS_TIME AS OF CURRENT_DATE
   WHERE DOMEIN_CODE = NEWDOM.AANGIFTEFREQUENTIE
     AND DOMEIN_NAAM = 'Aangiftefrequentie';
   IF DOMFOUND is NULL THEN
      signal sqlstate '99DOM'
      set message_text = 'Domein niet correct' ;
   END IF ;
   END@

CREATE OR REPLACE TRIGGER STVBU000 
	BEFORE UPDATE OF AANGIFTEFREQUENTIE ON S_TIJDVAK
	REFERENCING  NEW AS NEWDOM
	FOR EACH ROW
--
	DISABLE      DEBUG     MODE    
	QUALIFIER    knaller ---
	---QUALIFIER RLHO10 ---
	ASUTIME      LIMIT     9000    
	-- WLM ENVIRONMENT NIET NODIG:                   
	-- EXECUTED IN THE DBM1 ADDRESS SPACE            
	-- MOET ER VERPLICHT ZIJN FOR DEBUG              
	WLM ENVIRONMENT FOR DEBUG MODE RLHNOP  
	CONCURRENT   ACCESS RESOLUTION
	         USE CURRENTLY COMMITTED      
	DYNAMICRULES RUN   
	APPLICATION  ENCODING SCHEME UNICODE  
	WITH      EXPLAIN ---
	---WITH EXPLAIN ---
	WITHOUT      IMMEDIATE WRITE    
	ISOLATION    LEVEL     CS    
	-- MAG NIET: SQL PATH knaller 
	RELEASE      AT        COMMIT     
	ROUNDING     DEC_ROUND_HALF_EVEN  
	DECIMAL(31)      
	NOT          SECURED
	BUSINESS_TIME SENSITIVE YES
	SYSTEM_TIME   SENSITIVE NO
	ARCHIVE       SENSITIVE NO
	CONCENTRATE   STATEMENTS WITH LITERALS
--
   WHEN (NEWDOM.AANGIFTEFREQUENTIE IS NOT NULL)
BEGIN 
 DECLARE DOMFOUND VARCHAR(5) default NULL;
  SELECT DOMEIN_CODE
    INTO DOMFOUND
    FROM S_DOMEIN
	 FOR BUSINESS_TIME AS OF CURRENT_DATE
   WHERE DOMEIN_CODE = NEWDOM.AANGIFTEFREQUENTIE
     AND DOMEIN_NAAM = 'Aangiftefrequentie';
   IF DOMFOUND is NULL THEN
      signal sqlstate '99DOM'
      set message_text = 'Domein niet correct' ;
   END IF ;
   END@
   
--#SET TERMINATOR ;