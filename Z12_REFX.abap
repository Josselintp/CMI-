*&---------------------------------------------------------------------*
*& Report  Z12_REFX
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  Z12_REFX.

TABLES: vicncn, vibdro, kna1.

TYPES: BEGIN OF ty_reporte,
     CONTRACT_O_T   TYPE  REBDBUSOBJIDCN,
     xmetxt         TYPE vibdro-xmetxt,
     swenr          TYPE vibdro-swenr,
     partner        TYPE bapi_re_partner-partner,
     name1          TYPE kna1-name1,
     industry       TYPE vicncn-industry,
     measvaluecmpl  TYPE vibdmeas-measvaluecmpl,
     recnbeg        TYPE vicncn-recnbeg,
     recndat        TYPE vicncn-recndat,
     ctrate         TYPE vicdcfpay-ctrate,
     termno         TYPE vitmterm-termno,
     BKOND          TYPE vicdcfpay-bkond,
     PRECIO_TOTAL   TYPE vibdmeas-measvaluecmpl,
     BKOND_1        TYPE vicdcfpay-bkond,
     condtype       TYPE tivcdcondtype-condtype,
     condtypel      TYPE TIVCDCONDTYPET-XCONDTYPEL,
         bukrs           TYPE vicncn-bukrs,
         recnnr          TYPE vicncn-recnnr,
         obj_alquiler    TYPE vibdro-imkey,

       END OF ty_reporte.

DATA: lt_reporte TYPE TABLE OF ty_reporte,
      ls_reporte TYPE ty_reporte,
      lt_vicncn  TYPE TABLE OF vicncn,
      ls_vicncn  TYPE vicncn.

" Variables para la BAPI y auxiliares
" Variables para la BAPI y auxiliares
DATA: lt_obj_rel TYPE BAPI_RE_OBJECT_REL  OCCURS 0, " Esto crea la tabla interna
      ls_obj_rel LIKE BAPI_RE_OBJECT_REL,           " Esto crea la estructura de trabajo
      lt_partner TYPE bapi_re_partner OCCURS 0,
      ls_partner LIKE bapi_re_partner,
      lv_imkey   TYPE BAPI_RE_CONTRACT, "vibdro-imkey,
      lv_intreno TYPE vibdro-intreno,
     ls_CONTRACT   like BAPI_RE_CONTRACT,
    lv_imkey_interno TYPE vibdro-imkey.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS: s_bukrs  FOR vicncn-bukrs OBLIGATORY,    " Sociedad [cite: 9]
                s_beg    FOR vicncn-recnbeg OBLIGATORY,  " Fecha inicio [cite: 10]
                s_end    FOR vicncn-recndat, "OBLIGATORY,  " Fecha fin [cite: 11]
                s_type   FOR vicncn-recntype,            " Clase contrato [cite: 12]
                s_nr     FOR vicncn-recnnr.              " Número contrato [cite: 13]
SELECTION-SCREEN END OF BLOCK b1.


START-OF-SELECTION.

  " Selección inicial de contratos [cite: 9, 10, 11]
  SELECT * FROM vicncn
    INTO TABLE lt_vicncn
    WHERE bukrs    IN s_bukrs
      AND recnbeg  IN s_beg
      AND recndat  IN s_end
      AND recntype IN s_type
      AND recnnr   IN s_nr.

  LOOP AT lt_vicncn INTO ls_vicncn.
    CLEAR: ls_reporte, lt_obj_rel, lt_partner.


    " Llamada a la BAPI para obtener CONTRACT_OBJECT_ID [cite: 15]
    CALL FUNCTION 'BAPI_RE_CN_GET_DETAIL'
      EXPORTING
        compcode       = ls_vicncn-bukrs
        contractnumber = ls_vicncn-recnnr
        IMPORTING
           CONTRACT    =  ls_CONTRACT
      TABLES
        object_rel     = lt_obj_rel
        partner        = lt_partner.

*     1. Ubicar posición IM (Inmueble) [cite: 16]
    READ TABLE lt_obj_rel INTO ls_obj_rel WITH KEY OBJECT_type = 'IS'
                                                  CONTRACT_OBJECT_TYPE = 'IM'.
    IF sy-subrc = 0.
      " Concatenación manual (Sintaxis vieja)
      CONCATENATE 'LU' ls_obj_rel-contract_object_id INTO lv_imkey SEPARATED BY space.
* ls_reporte-CONTRACT_O_T = ls_obj_rel-CONTRACT_OBJECT_ID.
    ENDIF.

CALL FUNCTION 'CONVERSION_EXIT_IMKEY_INPUT'
  EXPORTING
    input  = lv_imkey
  IMPORTING
    output = lv_imkey_interno.


      SELECT SINGLE xmetxt swenr intreno
        FROM vibdro
        INTO (ls_reporte-xmetxt, ls_reporte-swenr, lv_intreno)
        WHERE imkey = lv_imkey_interno.

ls_reporte-CONTRACT_O_T = ls_reporte-xmetxt.

 READ TABLE lt_partner INTO ls_partner INDEX 1.
    IF sy-subrc = 0.
      ls_reporte-partner = ls_partner-partner.


*      Nombre del cliente desde KNA1 [cite: 23]
      SELECT SINGLE name1 FROM kna1 INTO ls_reporte-name1
        WHERE kunnr = ls_partner-partner.

*
    ENDIF.

    Ls_reporte-industry = ls_vicncn-industry. " Sector [cite: 24]
*    *      " Área desde VIBDMEAS [cite: 28]
      IF lv_intreno IS NOT INITIAL.
        SELECT SINGLE measvaluecmpl FROM vibdmeas
          INTO ls_reporte-measvaluecmpl
          WHERE intreno = lv_intreno.
      ENDIF.


    ls_reporte-recnbeg  = ls_vicncn-recnbeg. " Inicio [cite: 30]
    ls_reporte-recndat  = ls_vicncn-recndat. " Fin [cite: 32]
*     ls_reporte-recnnr   = ls_vicncn-recnnr.

    SELECT SINGLE ctrate FROM vicdcfpay INTO ls_reporte-ctrate
      WHERE intreno = ls_vicncn-intreno.

 SELECT SINGLE TERMNO FROM VITMTERM INTO ls_reporte-TERMNO
      WHERE intreno = ls_vicncn-intreno AND TERMTYPE  = '1300' .  "10	% de de incremento de renta




    SELECT SINGLE bkond FROM vicdcfpay INTO ls_reporte-BKOND
      WHERE intreno  = ls_vicncn-intreno
        AND condtype = 'XR04'.

  ls_reporte-precio_total = ls_reporte-measvaluecmpl * ls_reporte-BKOND .


    SELECT SINGLE bkond FROM vicdcfpay INTO ls_reporte-BKOND_1
      WHERE intreno  = ls_vicncn-intreno
        AND condtype = 'XR19'.

   SELECT SINGLE CONDTYPE  FROM vicdcfpay INTO   ls_reporte-CONDTYPE
      WHERE intreno  = ls_vicncn-intreno.

SELECT SINGLE XCONDTYPEL FROM TIVCDCONDTYPET INTO ls_reporte-condtypel
  WHERE SPRAS = SY-LANGU
    AND CONDTYPE = ls_reporte-CONDTYPE.

    APPEND ls_reporte TO lt_reporte.

  ENDLOOP.

  " Visualización del reporte
  IF lt_reporte IS NOT INITIAL.
    PERFORM display_alv.
  ELSE.
    MESSAGE 'No se encontraron datos' TYPE 'I'.
  ENDIF.

FORM display_alv.

  DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
        ls_fieldcat TYPE slis_fieldcat_alv.

  CLEAR lt_fieldcat.

  DEFINE m_fieldcat.
    clear ls_fieldcat.
    ls_fieldcat-fieldname = &1.
    ls_fieldcat-seltext_l = &2.
    append ls_fieldcat to lt_fieldcat.
  END-OF-DEFINITION.

  " IMPORTANTE: Los nombres de fieldname deben ser EXACTOS a tu TYPES y en MAYUSCULAS
  m_fieldcat 'CONTRACT_O_T'   'Objeto de alquiler'.
  m_fieldcat 'SWENR'          'Centro comercial'.
  m_fieldcat 'PARTNER'        'Codigo socio'.
  m_fieldcat 'NAME1'          'Nombre'.
  m_fieldcat 'INDUSTRY'       'Sector industrial'.
  m_fieldcat 'MEASVALUECMPL'  'Area'.
  m_fieldcat 'RECNBEG'        'Inicio del contrato'.
  m_fieldcat 'RECNDAT'        'Fin del contrato'.
  m_fieldcat 'CTRATE'         'Tasa de cambio'.
  m_fieldcat 'TERMNO'         '% Incremento Renta'.
  m_fieldcat 'BKOND'          'Precio Mant. XR04'.
  m_fieldcat 'PRECIO_TOTAL'   'Precio Total Condicion'.
  m_fieldcat 'BKOND_1'        'Precio Alq. XR19'.
  m_fieldcat 'CONDTYPE'       'Clase de condicion'.
  m_fieldcat 'CONDTYPEL'      'Texto clase condicion'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat   = lt_fieldcat
    TABLES
      t_outtab      = lt_reporte
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.
ENDFORM.
