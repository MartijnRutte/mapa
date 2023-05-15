SET CURRENT SQLID = RLH_DB_OBJECTS_A99E01;
SET SCHEMA RLH_DB_OBJECTS_A99E01;
--
Update S_DOMEIN
   Set DOMEIN_WAARDE = 'Verzoek ' concat Lower(Left(DOMEIN_WAARDE, 1)) concat Strip(Substr(DOMEIN_WAARDE, 2, Length(DOMEIN_WAARDE)-1))
      ,USERID        = SESSION_USER
 Where DOMEIN_NAAM   = 'Verzoeksoort'
   And DOMEIN_WAARDE NOT Like 'Verzoek %'
   ;
--   
--
Update S_DOMEIN
   Set DOMEIN_WAARDE = 'Verzoek melding vervroegen inhoudingsplicht LH'
      ,USERID        = SESSION_USER
 Where DOMEIN_NAAM   = 'Verzoeksoort'
   And DOMEIN_CODE   = 'VVIHP'
   ; 
--
--
Update S_DOMEIN
   Set DOMEIN_WAARDE = 'Signaal Percentage GDP WHK mutatie'
      ,USERID        = SESSION_USER
 Where DOMEIN_NAAM   = 'Signaalsoort'
   And DOMEIN_CODE   = 'PWHKM'
   ;    
--   
