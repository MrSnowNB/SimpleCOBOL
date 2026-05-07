      *****************************************************************         
      * Program:     COCRDSLC.CBL                                     *         
      * Layer:       Business logic                                   *         
      * Function:    Credit Card Selection                            *         
      *****************************************************************         
      *                                                               *         
      * Copyright Amazon.com, Inc. or its affiliates.                *         
      * All Rights Reserved.                                          *         
      *                                                               *         
      * Licensed under the Apache License, Version 2.0 (the          *         
      * "License"). You may not use this file except in compliance    *         
      * with the License. A copy of the License is located at         *         
      *                                                               *         
      *    https://www.apache.org/licenses/LICENSE-2.0                *         
      *                                                               *         
      *  or in the "license" file accompanying this file. This file   *         
      *  is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR    *         
      *  CONDITIONS OF ANY KIND, either express or implied. See the   *         
      *  License for the specific language governing permissions and   *         
      *  limitations under the License.                               *         
      *****************************************************************         
      ******************************************************************        
      *                                                                          
      *    CardDemo Application                                                  
      *    Credit Card Selection Program                                         
      *                                                                          
      ******************************************************************        
       IDENTIFICATION DIVISION.                                                  
       PROGRAM-ID.    COCRDSLC.                                                  
      ******************************************************************        
       ENVIRONMENT DIVISION.                                                     
       CONFIGURATION SECTION.                                                    
      ******************************************************************        
       DATA DIVISION.                                                            
      ******************************************************************        
       WORKING-STORAGE SECTION.                                                  
      ******************************************************************        
      * COPY BOOKS - WORKING STORAGE                                             
      ******************************************************************        
           COPY COCOM01Y.                                                        
           COPY COCRDSLI.                                                        
           COPY COTTL01Y.                                                        
           COPY CSDAT01Y.                                                        
           COPY CSMSG01Y.                                                        
           COPY CSUSR01Y.                                                        
           COPY DFHAID.                                                          
           COPY DFHBMSCA.                                                        
      ******************************************************************        
      *    CONSTANTS                                                              
      ******************************************************************        
       01  WS-CONSTANTS.                                                         
           05 LIT-THISPGM         PIC X(8)  VALUE 'COCRDSLC'.                   
           05 LIT-THISTRANID      PIC X(4)  VALUE 'CCS1'.                       
           05 LIT-THISMAPSET      PIC X(8)  VALUE 'COCRDSLS'.                   
           05 LIT-THISMAP         PIC X(7)  VALUE 'CCRDSLA'.                    
           05 LIT-CCLISTPGM       PIC X(8)  VALUE 'COCRDLIC'.                   
           05 LIT-MENUPGM         PIC X(8)  VALUE 'COMEN01C'.                   
           05 LIT-CCVIEWPGM       PIC X(8)  VALUE 'COCRDSVC'.                   
      ******************************************************************        
      *    FLAGS                                                                  
      ******************************************************************        
       01  WS-FLAGS.                                                             
           05 INPUT-FLAG          PIC X(1).                                      
              88 INPUT-OK         VALUE '0'.                                     
              88 INPUT-ERROR      VALUE '1'.                                     
      ******************************************************************        
      *    MISC WORK AREAS                                                        
      ******************************************************************        
       01  WS-MISC-STORAGE.                                                      
           05 WS-PGMNAME          PIC X(8)  VALUE SPACES.                       
           05 WS-TRANID           PIC X(4)  VALUE SPACES.                       
           05 WS-MSG              PIC X(40) VALUE SPACES.                       
           05 WS-TMPVAR           PIC X(50) VALUE SPACES.                       
           05 WS-ERR-FLG          PIC X(01) VALUE '0'.                          
              88 ERR-FLG-ON       VALUE '1'.                                     
              88 ERR-FLG-OFF      VALUE '0'.                                     
           05 WS-RESP-CD          PIC S9(09) COMP VALUE ZEROS.                  
           05 WS-REAS-CD          PIC S9(09) COMP VALUE ZEROS.                  
      ******************************************************************        
      *    PROGRAM COMMUNICATION AREA                                             
      ******************************************************************        
       01  WS-THIS-PROGCOMMAREA.                                                 
           05 WS-CA-FIRST-TIME    PIC X(1)  VALUE '1'.                          
              88 WS-CA-IS-FIRST-TIME  VALUE '1'.                                 
              88 WS-CA-NOT-FIRST-TIME VALUE '0'.                                 
      ******************************************************************        
      *    PROGRAM OUTPUT AREA                                                    
      ******************************************************************        
       01  WS-CC-DATA.                                                           
           05 CC-ACCT-ID-N        PIC 9(11) VALUE ZEROS.                        
           05 CC-CARD-NUM-N       PIC 9(16) VALUE ZEROS.                        
      ******************************************************************        
       LINKAGE SECTION.                                                          
      ******************************************************************        
       01  DFHCOMMAREA.                                                          
           05 LK-COMMAREA         PIC X(1000).                                  
      ******************************************************************        
       PROCEDURE DIVISION.                                                       
      ******************************************************************        
       MAIN-PARA.                                                                
      ******************************************************************        
      *    Check the COMMAREA length                                              
      ******************************************************************        
           IF EIBCALEN = ZEROS                                                   
               MOVE 'COSGN00C'     TO CDEMO-TO-PROGRAM                          
               MOVE 'CSGN'         TO CDEMO-TO-TRANID                           
               MOVE SPACE          TO CDEMO-FROM-PROGRAM                        
               MOVE -1             TO CDEMO-FROM-TRANID                         
               MOVE 'COSGN00C'     TO WS-PGMNAME                                
               SET CDEMO-PGM-ENTER TO TRUE                                       
               PERFORM 9999-RETURN                                               
           END-IF                                                                
      ******************************************************************        
      *    Move the COMMAREA to the Working Storage                               
      ******************************************************************        
           MOVE DFHCOMMAREA        TO CARDDEMO-COMMAREA                         
      ******************************************************************        
      *    Check the last mapset and map                                          
      ******************************************************************        
           IF  NOT CDEMO-LAST-MAPSET-VALID OR                                    
               NOT CDEMO-LAST-MAP-VALID                                          
               MOVE 'BAD-MAP'      TO WS-MSG                                    
               PERFORM 9999-RETURN                                               
           END-IF                                                                
      ******************************************************************        
      *    Process based on the program state                                     
      ******************************************************************        
           EVALUATE TRUE                                                         
      ******************************************************************        
      *            NOT FIRST TIME INTO CARDDEMO AND NOT A CANCEL                 
      *            TYPE A CFG FIX: plain WHEN + nested IF/END-IF                 
      ******************************************************************        
               WHEN CDEMO-PGM-REENTER                                            
                   IF NOT CCARD-AID-CLEAR                                        
                  AND NOT CCARD-AID-PFK03                                        
                  AND NOT CCARD-AID-PFK12                                        
                       PERFORM 2000-PROCESS-INPUTS                               
                          THRU 2000-PROCESS-INPUTS-EXIT                          
                       IF INPUT-ERROR                                            
                           PERFORM 1000-SEND-MAP                                 
                              THRU 1000-SEND-MAP-EXIT                            
                           PERFORM COMMON-RETURN                                 
                       END-IF                                                    
                       MOVE CDEMO-ACCT-ID  TO CC-ACCT-ID-N                      
                       MOVE CDEMO-CARD-NUM TO CC-CARD-NUM-N                      
                       PERFORM 9000-READ-DATA                                    
                          THRU 9000-READ-DATA-EXIT                               
                       PERFORM 1000-SEND-MAP                                     
                          THRU 1000-SEND-MAP-EXIT                                
                       PERFORM COMMON-RETURN                                     
                   END-IF                                                        
      ******************************************************************        
      *            USER PRESSED CLEAR - GO BACK TO MAIN MENU                     
      ******************************************************************        
               WHEN CCARD-AID-CLEAR                                             
                    MOVE LIT-MENUPGM        TO CDEMO-TO-PROGRAM                 
                    MOVE 'CMEN'             TO CDEMO-TO-TRANID                   
                    MOVE LIT-THISPGM        TO CDEMO-FROM-PROGRAM               
                    SET  CDEMO-USRTYP-USER  TO TRUE                              
                    SET  CDEMO-PGM-ENTER    TO TRUE                              
                    MOVE LIT-THISMAPSET     TO CDEMO-LAST-MAPSET                 
                    MOVE LIT-THISMAP        TO CDEMO-LAST-MAP                    
                    PERFORM 9999-RETURN                                          
      ******************************************************************        
      *            USER PRESSED PFK03 - GO BACK TO MAIN MENU                     
      ******************************************************************        
               WHEN CCARD-AID-PFK03                                              
                    MOVE LIT-MENUPGM        TO CDEMO-TO-PROGRAM                 
                    MOVE 'CMEN'             TO CDEMO-TO-TRANID                   
                    MOVE LIT-THISPGM        TO CDEMO-FROM-PROGRAM               
                    SET  CDEMO-USRTYP-USER  TO TRUE                              
                    SET  CDEMO-PGM-ENTER    TO TRUE                              
                    MOVE LIT-THISMAPSET     TO CDEMO-LAST-MAPSET                 
                    MOVE LIT-THISMAP        TO CDEMO-LAST-MAP                    
                    PERFORM 9999-RETURN                                          
      ******************************************************************        
      *            USER PRESSED PFK12 - GO BACK TO CC LIST SCREEN                
      ******************************************************************        
               WHEN CCARD-AID-PFK12                                              
                    MOVE LIT-CCLISTPGM      TO CDEMO-TO-PROGRAM                 
                    MOVE 'CCL1'             TO CDEMO-TO-TRANID                   
                    MOVE LIT-THISPGM        TO CDEMO-FROM-PROGRAM               
                    SET  CDEMO-USRTYP-USER  TO TRUE                              
                    SET  CDEMO-PGM-ENTER    TO TRUE                              
                    MOVE LIT-THISMAPSET     TO CDEMO-LAST-MAPSET                 
                    MOVE LIT-THISMAP        TO CDEMO-LAST-MAP                    
      *                                                                          
                    EXEC CICS XCTL                                               
                              PROGRAM (CDEMO-TO-PROGRAM)                        
                              COMMAREA(CARDDEMO-COMMAREA)                        
                    END-EXEC                                                     
      ******************************************************************        
      *            COMING FROM CREDIT CARD LIST SCREEN                           
      *            TYPE A CFG FIX: plain WHEN + nested IF/END-IF                 
      *            GO TO replaced with PERFORM for smojol CFG compat             
      ******************************************************************        
               WHEN CDEMO-PGM-ENTER                                              
                   IF CDEMO-FROM-PROGRAM EQUAL LIT-CCLISTPGM                    
                       SET INPUT-OK TO TRUE                                      
                       MOVE CDEMO-ACCT-ID       TO CC-ACCT-ID-N                 
                       MOVE CDEMO-CARD-NUM      TO CC-CARD-NUM-N                
                       PERFORM 9000-READ-DATA                                    
                          THRU 9000-READ-DATA-EXIT                               
                       PERFORM 1000-SEND-MAP                                     
                         THRU 1000-SEND-MAP-EXIT                                 
                       PERFORM COMMON-RETURN                                     
                   ELSE                                                          
                       PERFORM 1000-SEND-MAP                                     
                          THRU 1000-SEND-MAP-EXIT                                
                       PERFORM COMMON-RETURN                                     
                   END-IF                                                        
               WHEN OTHER                                                        
                    MOVE 'UNEXPECTED STATE' TO WS-MSG                           
                    PERFORM 1000-SEND-MAP                                        
                       THRU 1000-SEND-MAP-EXIT                                   
                    PERFORM COMMON-RETURN                                        
           END-EVALUATE                                                          
                                                                                 
       COMMON-RETURN.                                                            
           MOVE WS-THIS-PROGCOMMAREA TO DFHCOMMAREA (1:LENGTH OF                
                                        WS-THIS-PROGCOMMAREA)                   
           EXEC CICS RETURN                                                      
                TRANSID (LIT-THISTRANID)                                        
                COMMAREA(CARDDEMO-COMMAREA)                                      
           END-EXEC.                                                             
      ******************************************************************        
      *                                                                          
      *    SEND MAP SECTION                                                       
      *                                                                          
      ******************************************************************        
       1000-SEND-MAP.                                                            
      ******************************************************************        
      *    Populate header information                                            
      ******************************************************************        
           MOVE FUNCTION CURRENT-DATE     TO WS-CURDATE-DATA                    
           MOVE WS-CURDATE-YEAR           TO WS-SDTYME-YEAR                     
           MOVE WS-CURDATE-MONTH          TO WS-SDTYME-MONTH                    
           MOVE WS-CURDATE-DAY            TO WS-SDTYME-DAY                      
           MOVE WS-CURDATE-HOURS          TO WS-SDTYME-HOURS                    
           MOVE WS-CURDATE-MINS           TO WS-SDTYME-MINS                     
           MOVE WS-CURDATE-SECS           TO WS-SDTYME-SECS                     
      ******************************************************************        
      *    Move header data to the map                                            
      ******************************************************************        
           MOVE CDEMO-CUST-FNAME          TO CCRDSLAO-FNAME                     
           MOVE CDEMO-CUST-LNAME          TO CCRDSLAO-LNAME                     
           MOVE LIT-THISTRANID            TO CCRDSLAO-TRNID                     
           MOVE LIT-THISPGM               TO CCRDSLAO-PGMNAM                    
           MOVE WS-SDTYME                 TO CCRDSLAO-SDTYME                    
           MOVE CDEMO-CARD-NUM            TO CCRDSLAO-CARNUM                    
           MOVE CDEMO-ACCT-ID             TO CCRDSLAO-ACTNUM                    
      ******************************************************************        
      *    Send map                                                               
      ******************************************************************        
           EXEC CICS SEND MAP('CCRDSLA')                                        
                          MAPSET('COCRDSLS')                                     
                          FROM(CCRDSLAO)                                         
                          ERASE                                                  
           END-EXEC                                                              
       1000-SEND-MAP-EXIT.                                                       
           EXIT.                                                                 
      ******************************************************************        
      *                                                                          
      *    PROCESS INPUTS SECTION                                                 
      *                                                                          
      ******************************************************************        
       2000-PROCESS-INPUTS.                                                      
      ******************************************************************        
      *    Receive map                                                            
      ******************************************************************        
           EXEC CICS RECEIVE MAP('CCRDSLA')                                     
                             MAPSET('COCRDSLS')                                  
                             INTO(CCRDSLAI)                                      
           END-EXEC                                                              
      ******************************************************************        
      *    Validate account number                                                
      ******************************************************************        
           SET INPUT-OK TO TRUE                                                  
           IF CCRDSLAI-ACCT-ID-L > 0                                            
               MOVE CCRDSLAI-ACCT-ID-D     TO CC-ACCT-ID-N                     
           ELSE                                                                  
               MOVE 0                      TO CC-ACCT-ID-N                     
           END-IF                                                                
      ******************************************************************        
      *    Validate card number                                                   
      ******************************************************************        
           IF CCRDSLAI-CARD-NUM-L > 0                                           
               MOVE CCRDSLAI-CARD-NUM-D    TO CC-CARD-NUM-N                    
           ELSE                                                                  
               MOVE 0                      TO CC-CARD-NUM-N                    
           END-IF                                                                
           IF CC-ACCT-ID-N = ZEROS AND                                          
              CC-CARD-NUM-N = ZEROS                                              
               SET INPUT-ERROR TO TRUE                                           
               MOVE 'ACCT ID OR CARD NUMBER MUST BE ENTERED'                    
                                           TO WS-MSG                            
           END-IF                                                                
           MOVE WS-MSG                     TO CCRDSLAO-ERRMSGO                  
       2000-PROCESS-INPUTS-EXIT.                                                 
           EXIT.                                                                 
      ******************************************************************        
      *                                                                          
      *    READ DATA SECTION                                                      
      *                                                                          
      ******************************************************************        
       9000-READ-DATA.                                                           
           MOVE CDEMO-ACCT-ID             TO CC-ACCT-ID-N                       
           MOVE CDEMO-CARD-NUM            TO CC-CARD-NUM-N                      
       9000-READ-DATA-EXIT.                                                      
           EXIT.                                                                 
      ******************************************************************        
      *                                                                          
      *    RETURN SECTION                                                         
      *                                                                          
      ******************************************************************        
       9999-RETURN.                                                              
           MOVE LIT-THISPGM               TO CDEMO-FROM-PROGRAM                 
           MOVE CDEMO-TO-PROGRAM          TO WS-PGMNAME                         
           EXEC CICS XCTL                                                        
                     PROGRAM (WS-PGMNAME)                                       
                     COMMAREA(CARDDEMO-COMMAREA)                                 
           END-EXEC.                                                             
      *                                                                          
      * Ver: CardDemo_v1.0-15-g27d6c6f-68 Date: 2022-07-19 23:12:33 CDT        
      *
