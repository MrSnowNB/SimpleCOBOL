      *****************************************************************         
      * Program:     COCRDUPC.CBL                                     *         
      * Layer:       Business logic                                   *         
      * Function:    Credit Card Update                               *         
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
      *    Credit Card Update Program                                            
      *                                                                          
      ******************************************************************        
       IDENTIFICATION DIVISION.                                                  
       PROGRAM-ID.    COCRDUPC.                                                  
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
           COPY COCRDUPI.                                                        
           COPY COTTL01Y.                                                        
           COPY CSDAT01Y.                                                        
           COPY CSMSG01Y.                                                        
           COPY CSUSR01Y.                                                        
           COPY DFHAID.                                                          
           COPY DFHBMSCA.                                                        
           COPY CVACT01Y.                                                        
           COPY CVACT03Y.                                                        
           COPY CVCRD01Y.                                                        
      ******************************************************************        
      *    CONSTANTS                                                              
      ******************************************************************        
       01  WS-CONSTANTS.                                                         
           05 LIT-THISPGM         PIC X(8)  VALUE 'COCRDUPC'.                   
           05 LIT-THISTRANID      PIC X(4)  VALUE 'CCC2'.                       
           05 LIT-THISMAPSET      PIC X(8)  VALUE 'COCRDUPS'.                   
           05 LIT-THISMAP         PIC X(7)  VALUE 'CCRDUPA'.                    
           05 LIT-CCLISTPGM       PIC X(8)  VALUE 'COCRDLIC'.                   
           05 LIT-MENUPGM         PIC X(8)  VALUE 'COMEN01C'.                   
      ******************************************************************        
      *    FLAGS                                                                  
      ******************************************************************        
       01  WS-FLAGS.                                                             
           05 INPUT-FLAG          PIC X(1).                                      
              88 INPUT-OK         VALUE '0'.                                     
              88 INPUT-ERROR      VALUE '1'.                                     
           05 FLG-ACCTFILTER-ISVALID  PIC X(1) VALUE '0'.                      
              88 FLG-ACCTFILTER-ISVALID   VALUE '1'.                            
              88 FLG-ACCTFILTER-NOT-OK    VALUE '0'.                            
           05 FLG-CARDFILTER-ISVALID  PIC X(1) VALUE '0'.                      
              88 FLG-CARDFILTER-ISVALID   VALUE '1'.                            
              88 FLG-CARDFILTER-NOT-OK    VALUE '0'.                            
           05 CCUP-DETAILS-FLAG   PIC X(1) VALUE '0'.                           
              88 CCUP-DETAILS-FETCHED     VALUE '1'.                            
              88 CCUP-DETAILS-NOT-FETCHED VALUE '0'.                            
           05 CCUP-SHOW-FLAG      PIC X(1) VALUE '0'.                           
              88 CCUP-SHOW-DETAILS        VALUE '1'.                            
              88 CCUP-HIDE-DETAILS        VALUE '0'.                            
           05 CCUP-CHANGES-FLAG   PIC X(1) VALUE '0'.                           
              88 CCUP-CHANGES-OKAYED-AND-DONE  VALUE '1'.                       
              88 CCUP-CHANGES-FAILED            VALUE '2'.                      
              88 CCUP-CHANGES-NOT-DONE          VALUE '0'.                      
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
      *    Move the COMMAREA to Working Storage                                   
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
      *       USER PRESSED CLEAR - RETURN TO MAIN MENU                          
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
      *       USER PRESSED PFK03 - RETURN TO MAIN MENU                          
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
      *       USER PRESSED PFK12 - RETURN TO CC LIST SCREEN                     
      ******************************************************************        
               WHEN CCARD-AID-PFK12                                              
                AND NOT CDEMO-PGM-ENTER                                          
                    MOVE LIT-CCLISTPGM      TO CDEMO-TO-PROGRAM                 
                    MOVE 'CCL1'             TO CDEMO-TO-TRANID                   
                    MOVE LIT-THISPGM        TO CDEMO-FROM-PROGRAM               
                    SET  CDEMO-USRTYP-USER  TO TRUE                              
                    SET  CDEMO-PGM-ENTER    TO TRUE                              
                    MOVE LIT-THISMAPSET     TO CDEMO-LAST-MAPSET                 
                    MOVE LIT-THISMAP        TO CDEMO-LAST-MAP                    
      *                                                                          
                    EXEC CICS                                                    
                         SYNCPOINT                                               
                    END-EXEC                                                     
      *                                                                          
                    EXEC CICS XCTL                                               
                         PROGRAM (CDEMO-TO-PROGRAM)                              
                         COMMAREA(CARDDEMO-COMMAREA)                             
                    END-EXEC                                                     
      ******************************************************************        
      *       USER CAME FROM CREDIT CARD LIST SCREEN                            
      *            TYPE A CFG FIX: two plain WHENs + single nested IF/END-IF    
      *            TYPE B CFG FIX (B1): GO TO COMMON-RETURN -> PERFORM          
      ******************************************************************        
               WHEN CDEMO-PGM-ENTER                                              
               WHEN CCARD-AID-PFK12                                              
                   IF CDEMO-FROM-PROGRAM  EQUAL LIT-CCLISTPGM                   
                          SET CDEMO-PGM-REENTER    TO TRUE                       
                          SET INPUT-OK             TO TRUE                       
                          SET FLG-ACCTFILTER-ISVALID  TO TRUE                   
                          SET FLG-CARDFILTER-ISVALID  TO TRUE                   
                          MOVE CDEMO-ACCT-ID       TO CC-ACCT-ID-N              
                          MOVE CDEMO-CARD-NUM      TO CC-CARD-NUM-N             
                          PERFORM 9000-READ-DATA                                 
                             THRU 9000-READ-DATA-EXIT                            
                          SET CCUP-SHOW-DETAILS TO TRUE                          
                          PERFORM 3000-SEND-MAP                                  
                             THRU 3000-SEND-MAP-EXIT                             
                          PERFORM COMMON-RETURN                                  
                   END-IF                                                        
      ******************************************************************        
      *       FRESH ENTRY INTO PROGRAM                                           
      *            ASK THE USER FOR THE KEYS TO FETCH CARD TO BE UPDATED        
      *            TYPE A CFG FIX (Rule 3): split two compound WHEN..AND        
      *            with different guards into separate WHEN + nested IF/END-IF  
      *            Body extracted to 3001-INIT-AND-SHOW-MAP paragraph           
      ******************************************************************        
               WHEN CCUP-DETAILS-NOT-FETCHED                                    
                   IF CDEMO-PGM-ENTER                                            
                       PERFORM 3001-INIT-AND-SHOW-MAP                           
                           THRU 3001-INIT-AND-SHOW-MAP-EXIT                     
                   END-IF                                                        
               WHEN CDEMO-FROM-PROGRAM   EQUAL LIT-MENUPGM                      
                   IF NOT CDEMO-PGM-REENTER                                     
                       PERFORM 3001-INIT-AND-SHOW-MAP                           
                           THRU 3001-INIT-AND-SHOW-MAP-EXIT                     
                   END-IF                                                        
      ******************************************************************        
      *       CARD DATA CHANGES REVIEWED, OKAYED AND DONE SUCESSFULLY           
      *            RESET THE SEARCH KEYS                                        
      *            ASK THE USER FOR FRESH SEARCH CRITERIA                       
      *            TYPE B CFG FIX (B2): GO TO COMMON-RETURN -> PERFORM          
      ******************************************************************        
               WHEN CCUP-CHANGES-OKAYED-AND-DONE                                
               WHEN CCUP-CHANGES-FAILED                                          
                    INITIALIZE WS-THIS-PROGCOMMAREA                              
                               WS-MISC-STORAGE                                   
                               CDEMO-ACCT-ID                                     
                               CDEMO-CARD-NUM                                    
                    SET CDEMO-PGM-ENTER            TO TRUE                       
                    PERFORM 3000-SEND-MAP THRU                                   
                            3000-SEND-MAP-EXIT                                   
                    SET CCUP-DETAILS-NOT-FETCHED   TO TRUE                       
                    PERFORM COMMON-RETURN                                        
      ******************************************************************        
      *       PROCESSING USER INPUT FOR CARD UPDATE                             
      *            TYPE A CFG FIX (Rule 1): plain WHEN + nested IF/END-IF      
      *            TYPE B CFG FIX (B1a/B1b): GO TO COMMON-RETURN -> PERFORM    
      ******************************************************************        
               WHEN CCUP-DETAILS-FETCHED                                         
                   IF CDEMO-PGM-REENTER                                         
                       PERFORM 2000-PROCESS-INPUTS                               
                          THRU 2000-PROCESS-INPUTS-EXIT                          
                       IF INPUT-ERROR                                            
                           PERFORM 3000-SEND-MAP                                 
                              THRU 3000-SEND-MAP-EXIT                            
                           PERFORM COMMON-RETURN                                 
                       END-IF                                                    
                       PERFORM 5000-UPDATE-RECORD                                
                          THRU 5000-UPDATE-RECORD-EXIT                           
                       PERFORM 3000-SEND-MAP                                     
                          THRU 3000-SEND-MAP-EXIT                                
                       PERFORM COMMON-RETURN                                     
                   END-IF                                                        
               WHEN OTHER                                                        
      *            TYPE B CFG FIX (B2): GO TO COMMON-RETURN -> PERFORM          
                    MOVE 'UNEXPECTED STATE' TO WS-MSG                           
                    PERFORM 3000-SEND-MAP                                        
                       THRU 3000-SEND-MAP-EXIT                                   
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
       3000-SEND-MAP.                                                            
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
      *    Move header data to map                                                
      ******************************************************************        
           MOVE CDEMO-CUST-FNAME          TO CCRDUPAD-FNAME                     
           MOVE CDEMO-CUST-LNAME          TO CCRDUPAD-LNAME                     
           MOVE LIT-THISTRANID            TO CCRDUPAD-TRNID                     
           MOVE LIT-THISPGM               TO CCRDUPAD-PGMNAM                    
           MOVE WS-SDTYME                 TO CCRDUPAD-SDTYME                    
      ******************************************************************        
      *    Move card data to map if details fetched                               
      ******************************************************************        
           IF CCUP-DETAILS-FETCHED                                               
               MOVE CC-ACCT-ID-N          TO CCRDUPAD-ACCT-ID                   
               MOVE CC-CARD-NUM-N         TO CCRDUPAD-CARD-NUM                  
           END-IF                                                                
           MOVE WS-MSG                    TO CCRDUPAD-ERRMSGO                   
      ******************************************************************        
      *    Send map                                                               
      ******************************************************************        
           EXEC CICS SEND MAP('CCRDUPA')                                        
                          MAPSET('COCRDUPS')                                     
                          FROM(CCRDUPAD)                                         
                          ERASE                                                  
           END-EXEC                                                              
       3000-SEND-MAP-EXIT.                                                       
           EXIT.                                                                 
      ******************************************************************        
      *                                                                          
      *    INIT AND SHOW MAP SECTION                                             
      *    Extracted from compound WHEN..AND fallthrough (Rule 3 CFG fix)       
      *    TYPE B CFG FIX (B3): GO TO COMMON-RETURN -> PERFORM                  
      *                                                                          
      ******************************************************************        
       3001-INIT-AND-SHOW-MAP.                                                   
                    INITIALIZE WS-THIS-PROGCOMMAREA                              
                    PERFORM 3000-SEND-MAP THRU                                   
                            3000-SEND-MAP-EXIT                                   
                    SET CDEMO-PGM-REENTER        TO TRUE                         
                    SET CCUP-DETAILS-NOT-FETCHED TO TRUE                         
                    PERFORM COMMON-RETURN                                        
       3001-INIT-AND-SHOW-MAP-EXIT.                                              
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
           EXEC CICS RECEIVE MAP('CCRDUPA')                                     
                             MAPSET('COCRDUPS')                                  
                             INTO(CCRDUPAI)                                      
           END-EXEC                                                              
      ******************************************************************        
      *    Validate inputs                                                        
      ******************************************************************        
           SET INPUT-OK TO TRUE                                                  
           IF CCRDUPAI-CARD-NUM-L > 0                                           
               MOVE CCRDUPAI-CARD-NUM-D   TO CC-CARD-NUM-N                     
           ELSE                                                                  
               SET INPUT-ERROR TO TRUE                                           
               MOVE 'CARD NUMBER MUST BE ENTERED'                                
                                           TO WS-MSG                            
           END-IF                                                                
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
      *    UPDATE RECORD SECTION                                                  
      *                                                                          
      ******************************************************************        
       5000-UPDATE-RECORD.                                                       
           MOVE CC-CARD-NUM-N             TO CDEMO-CARD-NUM                     
       5000-UPDATE-RECORD-EXIT.                                                  
           EXIT.                                                                 
      ******************************************************************        
      *                                                                          
      *    RETURN SECTION                                                         
      *                                                                          
      ******************************************************************        
       9999-RETURN.                                                              
           MOVE LIT-THISPGM               TO CDEMO-FROM-PROGRAM                 
           MOVE CDEMO-TO-PROGRAM          TO WS-PGMNAME                         
           EXEC CICS                                                             
                SYNCPOINT                                                        
           END-EXEC                                                              
           EXEC CICS XCTL                                                        
                     PROGRAM (WS-PGMNAME)                                       
                     COMMAREA(CARDDEMO-COMMAREA)                                 
           END-EXEC.                                                             
      *                                                                          
      * Ver: CardDemo_v1.0-15-g27d6c6f-68 Date: 2022-07-19 23:12:33 CDT        
      *
