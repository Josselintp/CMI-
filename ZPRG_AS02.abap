REPORT zprg_as02

NO STANDARD PAGE HEADING LINE-SIZE 255.

"parametro de entrada.
DATA: gt_arch TYPE STANDARD TABLE OF alsmex_tabline,
wa_arch  LIKE LINE OF gt_arch,
lv_count TYPE c.

DATA:   e_group_opened.
TYPES: BEGIN OF ty_as02,
anln1 TYPE anla-anln1, "char12,
sub   TYPE anla-anln2, "char1,
socd  TYPE anla-bukrs, "char4,
val   TYPE anlb-ndjar, "char3,
END OF ty_as02,
ti_as02 TYPE STANDARD TABLE OF ty_as02.

DATA: lt_anlb TYPE TABLE OF anlb,
      ls_anlb TYPE anlb.

DATA: gt_as02 TYPE ti_as02,
      wa_as02 TYPE ty_as02,
      gs_as02 TYPE ty_as02.
DATA:   bdcdata LIKE bdcdata    OCCURS 0 WITH HEADER LINE.
DATA:   messtab LIKE bdcmsgcoll OCCURS 0 WITH HEADER LINE.

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_arch  LIKE rlgrap-filename OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR  p_arch.
  CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
    EXPORTING
      mask          = ', todos los archivos, *.*'
    CHANGING
      file_name     = p_arch
    EXCEPTIONS
      mask_too_long = 1.

  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename    = p_arch
      i_begin_col = 1
      i_begin_row = 2
      i_end_col   = 4
      i_end_row   = 1000
    TABLES
      intern      = gt_arch.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
  IF NOT gt_arch[] IS INITIAL.
    LOOP AT  gt_arch INTO wa_arch.

      CASE wa_arch-col.
        WHEN 1.
          MOVE wa_arch-value TO wa_as02-anln1.
        WHEN 2.
          MOVE wa_arch-value TO wa_as02-sub.
        WHEN 3.
          MOVE wa_arch-value TO wa_as02-socd.
        WHEN 4.
          MOVE wa_arch-value TO wa_as02-val.
      ENDCASE.
      AT END OF row.
        APPEND  wa_as02 TO gt_as02.
      ENDAT.
    ENDLOOP.
  ENDIF.


START-OF-SELECTION.
  DATA: tex TYPE char14,
       lv_texval(3),
       L_MSTRING(480).
*perform open_group.

  IF gt_as02[] IS NOT INITIAL.
    CLEAR lt_anlb.
    SELECT * INTO TABLE lt_anlb
      FROM anlb
      FOR ALL ENTRIES IN gt_as02
      WHERE bukrs EQ gt_as02-socd
        AND anln1 EQ gt_as02-anln1.
*        AND anln2 EQ gt_as02-sub.
    IF sy-subrc = 0.
      DELETE lt_anlb WHERE afabe >= 30.
    ENDIF.
  ENDIF.

  CLEAR gs_as02.
  LOOP AT gt_as02 INTO gs_as02.
    CLEAR: bdcdata[], messtab[].
    READ TABLE lt_anlb INTO ls_anlb WITH KEY anln1 = gs_as02-anln1.
    IF sy-subrc = 0.

      PERFORM bdc_dynpro      USING 'SAPLAIST' '0100'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'ANLA-ANLN1'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '/00'.
**********************************************************************
* Asignar datos de selección
*    READ TABLE  gt_as02  INTO  gs_as02 INDEX 1.
**********************************************************************
      PERFORM bdc_field       USING 'ANLA-ANLN1'  "activo f
                                   gs_as02-anln1.
*                              '240000002009'.
      PERFORM bdc_field       USING 'ANLA-ANLN2'
                                    gs_as02-sub.
*                                  '0'.
      PERFORM bdc_field       USING 'ANLA-BUKRS'
                                    gs_as02-socd.
*                              '6090'.
**********************************************************************
      PERFORM bdc_dynpro      USING 'SAPLAIST' '1000'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=TAB08'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'ANLA-TXT50'.
*perform bdc_field       using 'ANLA-TXT50'
*                              'Panel Solar JINKO SOLAR - JKM385M/72'.
*perform bdc_field       using 'ANLH-ANLHTXT'
*                              'Panel Solar JINKO SOLAR - JKM385M/72'.
*perform bdc_field       using 'ANLA-SERNR'
*                              '303260060'.
*perform bdc_field       using 'ANLA-INVNR'
*                              'GENE001727'.
*perform bdc_field       using 'ANLA-MENGE'
*                              '1'.
*perform bdc_field       using 'ANLA-MEINS'
*                              'UN'.
*perform bdc_field       using 'ANLA-IVDAT'
*                              '31.12.2019'.
**********************************************************************
      PERFORM bdc_dynpro      USING 'SAPLAIST' '1000'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=BUCH'.
*perform bdc_field       using 'BDC_CURSOR'
**                              'ANLB-NDJAR(05)'.   'ANLB-NDJAR(01)'.

      CLEAR lv_count.
      LOOP AT     lt_anlb  INTO  ls_anlb WHERE bukrs = gs_as02-socd
                                           AND anln1 = gs_as02-anln1.
        ADD 1 TO lv_count.

        CONCATENATE 'ANLB-NDJAR' '('lv_count')' INTO tex.
        CONDENSE  tex.
        lv_texval = gs_as02-val.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
          EXPORTING
            input  = lv_texval
          IMPORTING
            output = lv_texval.

        PERFORM bdc_field       USING  tex
                                       lv_texval. "gs_as02-val .

      ENDLOOP.

      CALL TRANSACTION 'AS02' USING bdcdata
                   MODE   'N'
                                      "A: show all dynpros
                                      "E: show dynpro on error only
                                      "N: do not display dynpro
                   UPDATE 'S'
                   MESSAGES INTO messtab.

      LOOP AT MESSTAB WHERE msgv1 NE ' '.
        MESSAGE ID     MESSTAB-MSGID
                TYPE   MESSTAB-MSGTYP
                NUMBER MESSTAB-MSGNR
                INTO L_MSTRING
                WITH MESSTAB-MSGV1
                     MESSTAB-MSGV2
                     MESSTAB-MSGV3
                     MESSTAB-MSGV4.
        WRITE: / MESSTAB-MSGTYP, L_MSTRING(250).
      ENDLOOP.
*      PERFORM close_group.
    ENDIF.


  ENDLOOP.
*&---------------------------------------------------------------------*
*&      Form  CLOSE_GROUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM close_group.
*  IF SESSION = 'X'.
*   close batchinput group
  CALL FUNCTION 'BDC_CLOSE_GROUP'.
  WRITE: /(30) 'BDC_CLOSE_GROUP'(i04),
          (12) 'returncode:'(i05),
               sy-subrc.
*  ELSE.
*    IF E_GROUP_OPENED = 'X'.
  CALL FUNCTION 'BDC_CLOSE_GROUP'.
  WRITE: /.
  WRITE: /(30) 'Fehlermappe wurde erzeugt'(i06).
  e_group_opened = ' '.
*    ENDIF.
*  ENDIF.
ENDFORM.                    "CLOSE_GROUP
*  perform close_group.

**********************************************************************

*include bdcrecx1.
*----------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.                    "BDC_DYNPRO

*----------------------------------------------------------------------*
*        Insert field                                                  *
*----------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
*  IF FVAL <> NODATA.  REVISAR LUEGO
  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.
*  ENDIF.
ENDFORM.                    "BDC_FIELD
