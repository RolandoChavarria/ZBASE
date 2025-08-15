FUNCTION ZST_GEN_JOB_INTERFACE.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     VALUE(PROGRAM) TYPE  PROGRAMM
*"     VALUE(FILENAME) TYPE  DDFILENAME
*"     VALUE(JOBNAME) TYPE  JOBNA_07A OPTIONAL
*"  EXPORTING
*"     VALUE(STATUS) TYPE  ABI_EXEC_STTS
*"     VALUE(REASON) TYPE  IS_FAILURE
*"----------------------------------------------------------------------

  DATA: v_prog    LIKE d010sinf-prog,
        v_jobname  TYPE btcjob.

*-* Valida Campo Program
  IF program IS INITIAL.
    status = 'ER'.
    reason = 'PROGRAM_INITIAL'.
    EXIT.
  ENDIF.

*-* Valida Campo path
  IF filename IS INITIAL.
    status = 'ER'.
    reason = 'FILENAME_INITIAL'.
    EXIT.
  ENDIF.

*-* Valida que exista el Programa en SAP
  SELECT SINGLE prog INTO v_prog FROM d010sinf
  WHERE prog EQ program.
  IF sy-subrc <> 0.
    status = 'ER'.
    reason = 'PROGRAM_NOT_EXIST'.
    EXIT.
  ENDIF.

*-* Arma el nombre del JOB
  IF jobname IS INITIAL.
    CONCATENATE program(14) '/' filename(17) INTO v_jobname.
  ELSE.
    CONCATENATE jobname(14)  '/' filename(17) INTO v_jobname.
  ENDIF.

  PERFORM lanza_job_prog USING program filename v_jobname
                         CHANGING status  reason.

ENDFUNCTION.


*&---------------------------------------------------------------------*
*&      Form  lanza_job_prog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM lanza_job_prog USING program filename v_jobname CHANGING status  reason.
***
  DATA: v_numjob  TYPE btcjobcnt,
        v_jobok   TYPE btcchar1.

*-* Crea el numero de JOB
  CALL FUNCTION 'JOB_OPEN'
    EXPORTING
      jobname          = v_jobname
    IMPORTING
      jobcount         = v_numjob
    EXCEPTIONS
      cant_create_job  = 1
      invalid_job_data = 2
      jobname_missing  = 3
      OTHERS           = 4.
*-* valida JOB OPEN
  IF sy-subrc <> 0.
    status = 'ER'.
    reason = 'ERROR JOB_OPEN'.
    EXIT.
  ENDIF.

*-*   Asigna Programa e Interfaz
  SUBMIT (program) WITH p_filein = filename
    AND RETURN
    VIA JOB v_jobname NUMBER v_numjob
      TO SAP-SPOOL
      DESTINATION   'LP01'
      IMMEDIATELY   ' '
      KEEP IN SPOOL ' '
      WITHOUT SPOOL DYNPRO.

*-* Termina de Programar el JOB
  CALL FUNCTION 'JOB_CLOSE'
    EXPORTING
      jobcount         = v_numjob
      jobname          = v_jobname
      strtimmed        = 'X'
    IMPORTING
      job_was_released = v_jobok
    EXCEPTIONS
      jobname_missing  = 3
      job_close_failed = 4
      job_notex        = 6
      OTHERS           = 8.

  IF sy-subrc <>  0.
    status = 'ER'.
    reason = 'ERROR JOB_OPEN'.
    EXIT.
  ENDIF.

  IF v_jobok <>  'X'.
    status = 'ER'.
    reason = 'JOB_NOT_RELEASED'.
    EXIT.
  ENDIF.

  status = 'OK'.
  CONCATENATE 'JOB_PROGRAMED:' v_jobname INTO reason
  SEPARATED BY space.
***
ENDFORM.                    "lanza_job_prog
