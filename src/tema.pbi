; Presentacion GTK3: no modifica las preferencias del escritorio ni el nucleo.
DeclareModule Tema
  Declare Inicializar()
  Declare Ventana(numero.i)
  Declare Clase(gadget.i, nombre.s)
  Declare Pulso(gadget.i)
  Declare QuitarClase(gadget.i, nombre.s)
EndDeclareModule

Module Tema
  ImportC ""
    CrearProveedor.i() As "gtk_css_provider_new"
    CargarCSS.i(proveedor.i, texto.p-utf8, longitud.i, *error) As "gtk_css_provider_load_from_data"
    Pantalla.i() As "gdk_screen_get_default"
    InstalarProveedor(pantalla.i, proveedor.i, prioridad.l) As "gtk_style_context_add_provider_for_screen"
    Contexto.i(widget.i) As "gtk_widget_get_style_context"
    AgregarClase(contexto.i, nombre.p-utf8) As "gtk_style_context_add_class"
    RetirarClase(contexto.i, nombre.p-utf8) As "gtk_style_context_remove_class"
    PulsarBarra(widget.i) As "gtk_progress_bar_pulse"
    LiberarObjeto(objeto.i) As "g_object_unref"
    LiberarError(error.i) As "g_error_free"
  EndImport
  Global aplicado.i
  Procedure Inicializar()
    Protected proveedor.i, error.i, css.s, pantallaActual.i
    If aplicado : ProcedureReturn #True : EndIf
    pantallaActual=Pantalla()
    If Not pantallaActual : ProcedureReturn #False : EndIf
    proveedor=CrearProveedor()
    If Not proveedor : ProcedureReturn #False : EndIf
    css="window.pb-ventana { background-color: #f2f5f8; color: #203247; font-family: Sans; font-size: 11pt; }"+#LF$
    css+".pb-ventana label { color: #203247; }"+#LF$
    css+".pb-ventana .pb-titulo, .pb-ventana .pb-titulo label { color: #17364a; font-size: 22pt; font-weight: bold; }"+#LF$
    css+".pb-ventana .pb-subtitulo, .pb-ventana .pb-subtitulo label { color: #52677a; font-size: 10pt; }"+#LF$
    css+".pb-ventana .pb-seccion, .pb-ventana .pb-seccion label { color: #28586a; font-size: 11pt; font-weight: bold; }"+#LF$
    css+".pb-ventana .pb-version, .pb-ventana .pb-version label { color: #126b70; font-size: 10pt; font-weight: bold; }"+#LF$
    css+".pb-ventana .pb-cabecera { background-color: #183e4b; border-radius: 10px; }"+#LF$
    css+".pb-ventana .pb-cabecera .pb-titulo, .pb-ventana .pb-cabecera .pb-titulo label { color: #ffffff; font-size: 24pt; }"+#LF$
    css+".pb-ventana .pb-cabecera .pb-subtitulo, .pb-ventana .pb-cabecera .pb-subtitulo label { color: #d3e9eb; font-size: 10pt; }"+#LF$
    css+".pb-ventana .pb-cabecera .pb-version, .pb-ventana .pb-cabecera .pb-version label { color: #d9f5ee; font-size: 11pt; }"+#LF$
    css+".pb-ventana .pb-secundario, .pb-ventana .pb-secundario label { color: #52677a; font-size: 10pt; }"+#LF$
    css+".pb-ventana progressbar trough { background-color: #dce7eb; border: none; border-radius: 4px; min-height: 6px; }"+#LF$
    css+".pb-ventana progressbar progress { background-image: none; background-color: #16878a; border: none; border-radius: 4px; min-height: 6px; }"+#LF$
    css+".pb-ventana button { background-image: none; background-color: #ffffff; border: 1px solid #c5d1dc; border-radius: 7px; color: #203247; box-shadow: none; text-shadow: none; padding: 4px 9px; font-size: 10pt; }"+#LF$
    css+".pb-ventana button label { color: inherit; }"+#LF$
    css+".pb-ventana button:hover { background-color: #e7eff3; border-color: #7198a6; }"+#LF$
    css+".pb-ventana button:active { background-color: #d6e5ec; }"+#LF$
    css+".pb-ventana button:focus { outline: 2px solid #36858a; outline-offset: -3px; }"+#LF$
    css+".pb-ventana button.pb-primario { background-color: #126b70; border-color: #126b70; color: #ffffff; font-weight: bold; }"+#LF$
    css+".pb-ventana button.pb-primario:hover { background-color: #0b5559; }"+#LF$
    css+".pb-ventana button.pb-peligro { color: #9e3535; border-color: #d4a4a4; background-color: #fffafa; }"+#LF$
    css+".pb-ventana button.pb-peligro:hover { background-color: #fbe4e4; }"+#LF$
    css+".pb-ventana button:disabled, .pb-ventana button.pb-primario:disabled, .pb-ventana button.pb-peligro:disabled { color: #697887; background-color: #e5eaf0; border-color: #d5dde4; }"+#LF$
    css+".pb-ventana treeview.view { background-color: #ffffff; color: #203247; font-size: 11pt; }"+#LF$
    css+".pb-ventana treeview.view:selected { background-color: #d7eeed; color: #123c40; }"+#LF$
    css+".pb-ventana treeview header button { background-color: #e5edf2; border-radius: 0; border-color: #d3dfe5; color: #28586a; font-weight: bold; }"+#LF$
    css+".pb-ventana entry, .pb-ventana textview, .pb-ventana textview text { background-color: #ffffff; color: #203247; font-size: 10pt; }"+#LF$
    css+".pb-ventana .pb-estado, .pb-ventana .pb-estado label { color: #28586a; font-size: 10pt; }"+#LF$
    css+".pb-ventana .pb-ocupado, .pb-ventana .pb-ocupado label { color: #9a530b; font-weight: bold; }"+#LF$
    css+".pb-ventana .pb-aviso, .pb-ventana .pb-aviso label { color: #9a530b; font-size: 17pt; font-weight: bold; }"+#LF$
    If Not CargarCSS(proveedor,css,-1,@error)
      If error : LiberarError(error) : EndIf
      LiberarObjeto(proveedor) : ProcedureReturn #False
    EndIf
    InstalarProveedor(pantallaActual,proveedor,800)
    LiberarObjeto(proveedor) : aplicado=#True
    ProcedureReturn #True
  EndProcedure
  Procedure Ventana(numero.i)
    If aplicado And IsWindow(numero) : AgregarClase(Contexto(WindowID(numero)),"pb-ventana") : EndIf
  EndProcedure
  Procedure Clase(gadget.i,nombre.s)
    If aplicado And IsGadget(gadget) : AgregarClase(Contexto(GadgetID(gadget)),nombre) : EndIf
  EndProcedure
  Procedure Pulso(gadget.i)
    If IsGadget(gadget) : PulsarBarra(GadgetID(gadget)) : EndIf
  EndProcedure
  Procedure QuitarClase(gadget.i,nombre.s)
    If aplicado And IsGadget(gadget) : RetirarClase(Contexto(GadgetID(gadget)),nombre) : EndIf
  EndProcedure
EndModule
