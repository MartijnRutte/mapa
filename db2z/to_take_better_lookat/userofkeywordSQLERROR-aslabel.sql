SET CURRENT SQLID = DBAE01;
SET SCHEMA DBAE01;
-- ***************************************************************** 
-- * DOBRA   DB2 FUNCTION DBADFN03                                 * 
-- *                                                               * 
-- * BETREFT     : AANROEPEN VAN STORED PROCEDURE DBADSP03         * 
-- *                                                               * 
-- * BESTEMD VOOR: DBA (DOBRA) DCP                                 * 
-- *                                                               * 
-- * OPMERKING   : AANROEPEN MET EEN SELECT                        * 
-- *               SELECT DBADFN03() FROM SYSIBM.SYSDUMMY1;        * 
-- *                                                               * 
-- * FEQUENTIE   : ADHOC                                           * 
-- *                                                               * 
-- * INVOER      : NVT                                             * 
-- *                                                               * 
-- * UITVOER     : FOUTBOODSCHAP- CHAR 50                          * 
-- *             : OF AANTAL VERWERKTE RECORDS                     * 
-- *                                                               * 
-- ***************************************************************** 
--                                                                   

--#SET TERMINATOR `
CREATE FUNCTION DBADFN03                                             
  ()                                            
  RETURNS CHAR( 40) FOR SBCS DATA CCSID EBCDIC  
  VERSION V1                                    
  LANGUAGE SQL                                  
  SPECIFIC DBADFN03                             
  PARAMETER CCSID EBCDIC                        
  DETERMINISTIC                                 
  NO EXTERNAL ACTION                            
  CALLED ON NULL INPUT                          
  MODIFIES SQL DATA                             
  ASUTIME LIMIT 1000000                          
  INHERIT SPECIAL REGISTERS                     
  DISABLE DEBUG MODE                            
  QUALIFIER DBAE01                     
  PACKAGE OWNER DBAE                          
  CURRENT DATA NO                               
  DYNAMICRULES RUN                              
  WITH EXPLAIN                               
  WITHOUT IMMEDIATE WRITE                       
  ISOLATION LEVEL CS                            
  OPTHINT ''                                    
  REOPT NONE                                    
  VALIDATE RUN                         
  ROUNDING DEC_ROUND_HALF_EVEN         
  DECIMAL(31)                          
  NOT SECURED                          
  BUSINESS_TIME SENSITIVE YES          
  SYSTEM_TIME SENSITIVE YES            
  ARCHIVE SENSITIVE YES                
  APPLCOMPAT V12R1                     
  CONCENTRATE STATEMENTS OFF           
   BEGIN                               
     DECLARE SQLCODE INTEGER ;         
     DECLARE RESULTAAT CHAR(50);       
     CALL DBADSP03(RESULTAAT);         
     IF SQLCODE <> 0 THEN              
       GOTO SQLERROR ;                 
     END IF ;                          
     SUCCES:RETURN RESULTAAT ;         
     SQLERROR:RETURN CHAR(SQLCODE) ;   
   END `

--#SET TERMINATOR ;
                   
  COMMIT;                              
