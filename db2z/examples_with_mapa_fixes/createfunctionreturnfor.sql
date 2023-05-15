--#SET TERMINATOR `                                                   
CREATE FUNCTION DBADFN02                                             
  ()                                            
  RETURNS CHAR( 40) FOR SBCS DATA CCSID
  VERSION V1                                    
  LANGUAGE SQL                                  
  SPECIFIC DBADFN02                             
  PARAMETER CCSID EBCDIC                        
  DETERMINISTIC                                 
  NO EXTERNAL ACTION                            
  CALLED ON NULL INPUT                          
  MODIFIES SQL DATA                             
  ASUTIME LIMIT 100000                          
  INHERIT SPECIAL REGISTERS                     
  DISABLE DEBUG MODE                            
  QUALIFIER DBAE01                     
  PACKAGE OWNER DBAE                          
  CURRENT DATA NO                               
  DYNAMICRULES RUN                              
  WITHOUT EXPLAIN                               
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
     CALL DBADSP02(RESULTAAT);         
     IF SQLCODE <> 0 THEN              
       GOTO SQLERROR ;                 
     END IF ;                          
     SUCCES:RETURN RESULTAAT ;         
     SQLERROR:RETURN CHAR(SQLCODE) ;   
   END `

--#SET TERMINATOR ; 
                   
  COMMIT;                              
