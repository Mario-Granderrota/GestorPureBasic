XIncludeFile "nucleo.pbi"
XIncludeFile "tema.pbi"
Enumeration
  #Ventana
  #Lista
  #Detalle
  #EstadoUI
  #Instalar
  #Existente
  #Abrir
  #Oficial
  #Acceso
  #Eliminar
  #TituloUI
  #SubtituloUI
  #VersionUI
  #SeccionUI
  #RutaUI
  #PieUI
  #CabeceraUI
  #AyudaUI
  #ProgresoUI
  #RegistroUI
  #AtajoCancelar
EndEnumeration
Global PerfilArgumento.s, Modo.s, IdArgumento.s, PrimerArgumento.i=-1, ErrorInicio.s
Global DescriptorBloqueo.i=-1
Global NewMap IdFilas.s()
Global Resultado.i, Finalizado.i, AutorizarPurgaExterna.i
Global Paquete.PaquetePB, Trabajo.i, Fase.i, Objetivo.s, Fuente.s, Reemplazar.i, Ocupado.i, OfrecerCorreccion.i, AceptarLimitacion.i
Procedure SalirCLI(texto.s,codigo.i)
  OpenConsole() : PrintN(texto) : End codigo
EndProcedure
Define indice, argumento.s
For indice=0 To CountProgramParameters()-1
  argumento=ProgramParameter(indice)
  Select argumento
    Case "--perfil"
      indice+1 : PerfilArgumento=ProgramParameter(indice)
    Case "--abrir"
      Modo="abrir" : indice+1 : IdArgumento=ProgramParameter(indice)
    Case "--abrir-activa"
      Modo="abrir"
    Case "--compilar"
      Modo="compilar" : indice+1 : IdArgumento=ProgramParameter(indice)
    Case "--"
      PrimerArgumento=indice+1 : Break
    Default
      If Modo="abrir" : PrimerArgumento=indice : Break : EndIf
      SalirCLI("Argumento no reconocido: "+argumento,2)
  EndSelect
Next
If geteuid_()=0 : SalirCLI("Ejecuta el gestor como usuario normal, sin sudo.",1) : EndIf
If Not Inicializar(PerfilArgumento) : SalirCLI(ErrorActual,1) : EndIf
If Modo<>""
  Define seleccion.VersionPB, parametros.s, anterior.s, programa.s, proceso, resultadoProceso.ResultadoProcesoPB
  If IdArgumento="" : IdArgumento=Activa() : EndIf
  Define bloqueoVersionActual=BloqueoVersion(IdArgumento,1)
  If bloqueoVersionActual<0 : SalirCLI(ErrorActual,1) : EndIf
  If Not LeerVersion(IdArgumento,@seleccion) Or seleccion\Estado<>"disponible" Or Not EstructuraValida(seleccion\Ruta) : SalirCLI("No hay una versión disponible válida seleccionada.",1) : EndIf
  If seleccion\Tipo="gestionada" And Not seleccion\Comprobada : SalirCLI("La instalación está pendiente de validación. Compruébala desde el gestor antes de abrirla.",1) : EndIf
  If Modo="compilar" And PrimerArgumento<0 : SalirCLI("Uso: gestor-purebasic --compilar ID -- fuente.pb --output programa",2) : EndIf
  SetEnvironmentVariable("PUREBASIC_HOME",seleccion\Ruta)
  If Not EntornoCompatible(@seleccion)
    If Modo="compilar" : SalirCLI(ErrorActual,1) : Else : MessageRequester("PureBasic",ErrorActual) : End 1 : EndIf
  EndIf
  If Modo="abrir"
    If Not PrepararPerfil(@seleccion) : SalirCLI(ErrorActual,1) : EndIf
    parametros=ArgumentosIDE(@seleccion)
    If PrimerArgumento<0
      ; Los archivos procedentes de %F siguen a --abrir-activa sin separador explícito.
      PrimerArgumento=CountProgramParameters()
    EndIf
    programa=seleccion\Ruta+"/compilers/purebasic"
  Else
    programa=seleccion\Ruta+"/compilers/pbcompiler"
    If seleccion\Motor="C" : programa=seleccion\Ruta+"/compilers/pbcompilerc" : EndIf
  EndIf
  For indice=PrimerArgumento To CountProgramParameters()-1 : parametros+" "+Citar(ProgramParameter(indice)) : Next
  If Modo="compilar"
    OpenConsole()
    If EjecutarProceso(programa,parametros,GetCurrentDirectory(),@resultadoProceso,3600) : Print(resultadoProceso\Salida) : End 0 : Else : Print(resultadoProceso\Salida) : End 1 : EndIf
  EndIf
  EjecutarProceso(programa,"--version",GetCurrentDirectory(),@resultadoProceso,15)
  If (resultadoProceso\Codigo<>0 And resultadoProceso\Codigo<>1) Or Not FindString(resultadoProceso\Salida,"PureBasic")
    MessageRequester("PureBasic","El IDE no puede iniciarse en este equipo. "+Right(resultadoProceso\Salida,1200)) : End 1
  EndIf
  proceso=RunProgram(programa,parametros,GetCurrentDirectory(),#PB_Program_Open)
  If Not proceso : MessageRequester("PureBasic","No se pudo abrir el IDE seleccionado.") : End 1 : EndIf
  Define espera
  For espera=1 To 40
    If Not ProgramRunning(proceso) : Break : EndIf
    Delay(20)
  Next
  If Not ProgramRunning(proceso) And ProgramExitCode(proceso)<>0
    CloseProgram(proceso) : MessageRequester("PureBasic","El IDE terminó con un error al arrancar. Consulta su configuración y sus bibliotecas.") : End 1
  EndIf
  WaitProgram(proceso)
  Define codigoIDE=ProgramExitCode(proceso)
  CloseProgram(proceso) : End Bool(codigoIDE<>0)
EndIf
DescriptorBloqueo=open_(Estado+"/instancia.lock",131138,384) ; O_RDWR|O_CREAT|O_NOFOLLOW
If DescriptorBloqueo<0 : MessageRequester("Gestor PureBasic","No se puede abrir el bloqueo del gestor.") : End 1 : EndIf
If BloquearNativo(DescriptorBloqueo,6)<>0 : MessageRequester("Gestor PureBasic","Ya hay otro gestor abierto para este perfil.") : CerrarNativo(DescriptorBloqueo) : End 1 : EndIf
If Not RecuperarMovimiento() Or Not RecuperarTransaccion() : ErrorInicio=ErrorActual : EndIf
If ErrorInicio="" And Not PrepararEjecutable() : ErrorInicio=ErrorActual : EndIf

Procedure.s SeleccionId()
  Protected fila=GetGadgetState(#Lista)
  If fila>=0 And FindMapElement(IdFilas(),Str(fila)) : ProcedureReturn IdFilas() : EndIf
  ProcedureReturn ""
EndProcedure

Procedure Detalle()
  Protected dato.VersionPB, disponible, retirada, abrirPermitido
  If LeerVersion(SeleccionId(),@dato)
    SetGadgetText(#Detalle,dato\Ruta)
    disponible=Bool(dato\Estado="disponible" And EstructuraValida(dato\Ruta))
    retirada=Bool(dato\Estado="retirada")
    abrirPermitido=Bool(disponible And (dato\Tipo<>"gestionada" Or dato\Comprobada))
  Else
    SetGadgetText(#Detalle,"No hay una instalación disponible seleccionada.")
  EndIf
  SetGadgetText(#Abrir,"Abrir versión seleccionada")
  If retirada : SetGadgetText(#Abrir,"Restaurar versión retirada") : EndIf
  DisableGadget(#Abrir,Bool(Ocupado Or (Not abrirPermitido And Not retirada)))
  DisableGadget(#Acceso,Bool(Ocupado Or Not disponible))
  SetGadgetText(#Eliminar,"Retirar versión seleccionada...")
  If retirada : SetGadgetText(#Eliminar,"Eliminar definitivamente...") : EndIf
  DisableGadget(#Eliminar,Bool(Ocupado Or (Not disponible And Not retirada)))
EndProcedure

Procedure Refrescar(preferida.s="")
  Protected fila, estadoTexto.s, activa.s=Activa()
  If preferida="" : preferida=activa : EndIf
  CargarVersiones() : ClearGadgetItems(#Lista) : ClearMap(IdFilas())
  ForEach Versiones()
    If Versiones()\Estado<>"disponible" And Versiones()\Estado<>"retirada" And Versiones()\Estado<>"borrando" : Continue : EndIf
    estadoTexto="Disponible" : If Versiones()\Id=activa : estadoTexto="Predeterminada" : EndIf
    If Versiones()\Estado="retirada" : estadoTexto="Retirada · recuperable" : EndIf
    If Versiones()\Estado="borrando" : estadoTexto="Borrado incompleto · revisar" : EndIf
    If Versiones()\Estado="disponible" And Not EstructuraValida(Versiones()\Ruta) : estadoTexto="Carpeta ausente o dañada" : EndIf
    If Versiones()\Correccion<>"" : estadoTexto+" (corrección local)" : EndIf
    If Versiones()\Limitacion<>"" : estadoTexto+" (limitación)" : EndIf
    If Versiones()\Comprobada And Versiones()\Motor<>"AUTO" : estadoTexto+" · "+Versiones()\Motor : EndIf
    If Versiones()\Tipo="gestionada" And Not Versiones()\Comprobada : estadoTexto+" (sin validar)" : EndIf
    AddGadgetItem(#Lista,-1,Etiqueta(@Versiones())+#LF$+Versiones()\Edicion+#LF$+estadoTexto)
    fila=CountGadgetItems(#Lista)-1 : IdFilas(Str(fila))=Versiones()\Id
    If Versiones()\Estado="retirada" Or Versiones()\Estado="borrando" Or Versiones()\Limitacion<>"" Or (Versiones()\Tipo="gestionada" And Not Versiones()\Comprobada)
      SetGadgetItemColor(#Lista,fila,#PB_Gadget_FrontColor,RGB(140,82,21),2)
    ElseIf Versiones()\Id=activa
      SetGadgetItemColor(#Lista,fila,#PB_Gadget_FrontColor,RGB(18,107,112),2)
    EndIf
    If Versiones()\Id=preferida : SetGadgetState(#Lista,fila) : EndIf
  Next
  If GetGadgetState(#Lista)<0 And CountGadgetItems(#Lista)>0 : SetGadgetState(#Lista,0) : EndIf
  SetGadgetText(#SeccionUI,"INSTALACIONES  ·  "+Str(CountGadgetItems(#Lista)))
  If CountGadgetItems(#Lista)=0
    SetGadgetText(#AyudaUI,"Sin instalaciones: selecciona o arrastra un paquete.")
  Else
    SetGadgetText(#AyudaUI,"Selecciona una versión para gestionarla.")
  EndIf
  Detalle()
EndProcedure

Procedure BloquearUI(valor.i)
  Ocupado=valor
  HideGadget(#ProgresoUI,Bool(Not valor))
  DisableGadget(#RegistroUI,Bool(valor Or FileSize(Estado+"/registro.log")<0))
  If valor : Tema::Clase(#EstadoUI,"pb-ocupado") : SetGadgetText(#PieUI,"EN CURSO") : Else : Tema::QuitarClase(#EstadoUI,"pb-ocupado") : SetGadgetText(#PieUI,"ESTADO") : EndIf
  DisableGadget(#Lista,valor) : DisableGadget(#Instalar,valor) : DisableGadget(#Existente,valor) : DisableGadget(#Oficial,valor)
  Detalle()
EndProcedure

Procedure Trabajar(parametro.i)
  Protected bien
  ErrorActual=""
  Select Fase
    Case 1
      DetectarExistentes() : DetectarCarpetas(Hogar) : DetectarCarpetas(Hogar+"/Apps") : DetectarExistentes() : bien=1
    Case 2 : bien=PrepararPaquete(Fuente,@Paquete)
    Case 3 : bien=ConfirmarPaquete(@Paquete,Objetivo,Reemplazar,AceptarLimitacion,OfrecerCorreccion)
    Case 4 : bien=RegistrarExistente(Fuente)
    Case 5
      Protected datoRetirar.VersionPB
      If LeerVersion(Objetivo,@datoRetirar) And datoRetirar\Estado="disponible"
        bien=RetirarRecuperable(Objetivo)
        If bien : bien=2 : EndIf
      ElseIf datoRetirar\Estado="retirada"
        bien=DesinstalarVersion(Objetivo,AutorizarPurgaExterna)
      EndIf
    Case 6 : bien=CrearAccesoVersion(Objetivo)
    Case 7 : bien=RestaurarVersionRetirada(Objetivo)
      If bien : If Not CrearAccesoVersion(Objetivo,0) : Registrar("Versión restaurada; el acceso puede crearse manualmente.") : bien=2 : EndIf : EndIf
  EndSelect
  LockMutex(Mutex) : Resultado=bien : Finalizado=1 : UnlockMutex(Mutex)
EndProcedure

Procedure Lanzar(faseNueva.i,texto.s)
  If Not OperacionDisponible() : MessageRequester("Recuperación pendiente",ErrorActual) : ProcedureReturn : EndIf
  Fase=faseNueva : CambiarCancelacion(0) : Finalizado=0 : BloquearUI(1) : SetGadgetText(#EstadoUI,texto)
  Trabajo=CreateThread(@Trabajar(),0)
  If Not Trabajo
    BloquearUI(0) : LimpiarPaquete(@Paquete) : MessageRequester("Error","No se pudo iniciar la operación.")
  EndIf
EndProcedure

Procedure IniciarPaquete(ruta.s)
  If Ocupado Or ErrorInicio<>"" : ProcedureReturn : EndIf
  ruta=RTrim(ruta,#LF$)
  If FindString(ruta,#LF$) Or FindString(ruta,#CR$)
    MessageRequester("Selecciona un solo paquete","Arrastra únicamente un archivo TAR o TGZ cada vez.") : ProcedureReturn
  EndIf
  Fuente=Normalizar(ruta)
  If Fuente="" : MessageRequester("Paquete",ErrorActual) : ProcedureReturn : EndIf
  Protected previa.VersionPB
  Objetivo=SeleccionId()
  If Not LeerVersion(Objetivo,@previa) Or previa\Estado<>"disponible" : Objetivo="" : EndIf
  Lanzar(2,"Identificando el paquete, sin ejecutar su contenido...")
EndProcedure

Procedure ElegirInstalacion(titulo.s, texto.s, ruta.s, puedeReemplazar.i, hayAnterior.i, limitacion.i=0, puedeCorregir.i=0, puedeConservar.i=1)
  Protected ventana, botonSustituir=-1, botonCorregir=-1, botonConservar, botonCancelar, botonCopiar, evento, eleccion, alto=370, etiqueta.s, cabecera, detalle, textoCompleto.s
  If limitacion : alto=440 : EndIf
  DisableWindow(#Ventana,1)
  ventana=OpenWindow(#PB_Any,0,0,720,alto,titulo,#PB_Window_SystemMenu|#PB_Window_WindowCentered,WindowID(#Ventana))
  If Not ventana : DisableWindow(#Ventana,0) : ProcedureReturn 0 : EndIf
  Tema::Ventana(ventana)
  cabecera=TextGadget(#PB_Any,22,17,676,40,titulo)
  If limitacion : Tema::Clase(cabecera,"pb-aviso") : Else : Tema::Clase(cabecera,"pb-titulo") : EndIf
  textoCompleto=texto
  If puedeReemplazar
    textoCompleto+#LF$+#LF$+"Al sustituir, esta carpeta se retirará de forma recuperable después de validar la nueva:"+#LF$+ruta+#LF$+"No se borrará automáticamente. Podrás restaurarla o eliminarla después."
  EndIf
  detalle=EditorGadget(#PB_Any,22,66,676,alto-158,#PB_Editor_ReadOnly|#PB_Editor_WordWrap)
  SetGadgetText(detalle,textoCompleto)
  botonCopiar=ButtonGadget(#PB_Any,22,alto-84,200,30,"Copiar información")
  If puedeReemplazar
    botonSustituir=ButtonGadget(#PB_Any,22,alto-44,220,34,"Sustituir anterior")
    Tema::Clase(botonSustituir,"pb-primario")
  EndIf
  If puedeCorregir
    botonCorregir=ButtonGadget(#PB_Any,22,alto-44,220,34,"Corregir y comprobar")
    Tema::Clase(botonCorregir,"pb-primario")
  EndIf
  etiqueta="Instalar" : If hayAnterior : etiqueta="Conservar ambas" : EndIf
  If limitacion : etiqueta="Aceptar limitada" : EndIf
  botonConservar=ButtonGadget(#PB_Any,254,alto-44,220,34,etiqueta)
  If Not puedeConservar : DisableGadget(botonConservar,1) : EndIf
  If Not puedeReemplazar And Not puedeCorregir And puedeConservar : Tema::Clase(botonConservar,"pb-primario") : EndIf
  botonCancelar=ButtonGadget(#PB_Any,486,alto-44,212,34,"Cancelar")
  AddKeyboardShortcut(ventana,#PB_Shortcut_Escape,#AtajoCancelar)
  SetActiveGadget(botonCancelar)
  Repeat
    evento=WaitWindowEvent()
    If EventWindow()<>ventana : Continue : EndIf
    If evento=#PB_Event_CloseWindow : Break : EndIf
    If evento=#PB_Event_Menu And EventMenu()=#AtajoCancelar : Break : EndIf
    If evento=#PB_Event_Gadget
      Select EventGadget()
        Case botonSustituir : eleccion=1 : Break
        Case botonCorregir : eleccion=3 : Break
        Case botonConservar : eleccion=2 : Break
        Case botonCopiar : SetClipboardText(textoCompleto) : SetGadgetText(botonCopiar,"Información copiada")
        Case botonCancelar : Break
      EndSelect
    EndIf
  ForEver
  CloseWindow(ventana) : DisableWindow(#Ventana,0) : SetActiveWindow(#Ventana)
  ProcedureReturn eleccion
EndProcedure

Procedure ConfirmarBorrado(texto.s, definitiva.i=1)
  Protected ventana, eliminar, cancelar, copiar, detalle, evento, resultado, cabecera
  DisableWindow(#Ventana,1)
  ventana=OpenWindow(#PB_Any,0,0,720,424,"Confirmar mantenimiento",#PB_Window_SystemMenu|#PB_Window_WindowCentered,WindowID(#Ventana))
  If Not ventana : DisableWindow(#Ventana,0) : ProcedureReturn #False : EndIf
  Tema::Ventana(ventana)
  cabecera=TextGadget(#PB_Any,22,16,676,38,"Retirar instalación")
  If definitiva : SetGadgetText(cabecera,"Eliminar definitivamente") : EndIf
  Tema::Clase(cabecera,"pb-aviso")
  detalle=EditorGadget(#PB_Any,22,62,676,260,#PB_Editor_ReadOnly|#PB_Editor_WordWrap)
  SetGadgetText(detalle,texto)
  copiar=ButtonGadget(#PB_Any,22,334,200,30,"Copiar información")
  eliminar=ButtonGadget(#PB_Any,22,378,332,34,"Eliminar definitivamente")
  If definitiva : Tema::Clase(eliminar,"pb-peligro") : EndIf
  If Not definitiva : SetGadgetText(eliminar,"Retirar (recuperable)") : EndIf
  cancelar=ButtonGadget(#PB_Any,366,378,332,34,"Cancelar")
  AddKeyboardShortcut(ventana,#PB_Shortcut_Escape,#AtajoCancelar)
  SetActiveGadget(cancelar)
  Repeat
    evento=WaitWindowEvent()
    If EventWindow()<>ventana : Continue : EndIf
    If evento=#PB_Event_CloseWindow : Break : EndIf
    If evento=#PB_Event_Menu And EventMenu()=#AtajoCancelar : Break : EndIf
    If evento=#PB_Event_Gadget
      If EventGadget()=copiar : SetClipboardText(texto) : SetGadgetText(copiar,"Información copiada") : EndIf
      If EventGadget()=eliminar : resultado=#True : Break : EndIf
      If EventGadget()=cancelar : Break : EndIf
    EndIf
  ForEver
  CloseWindow(ventana) : DisableWindow(#Ventana,0) : SetActiveWindow(#Ventana)
  ProcedureReturn resultado
EndProcedure

Procedure Decision()
  Protected anterior.VersionPB, texto.s, opcion, puedeReemplazar.i, hayAnterior.i, nueva.s=Etiqueta(@Paquete\Dato)+" ("+Paquete\Dato\Edicion+")"
  Reemplazar=0 : AceptarLimitacion=0
  If LeerVersion(Objetivo,@anterior)
    hayAnterior=1
    texto="Instalada: PureBasic "+Etiqueta(@anterior)+" ("+anterior\Edicion+")"+#LF$+"Paquete: PureBasic "+nueva+#LF$+#LF$+RelacionVersion(@Paquete\Dato,@anterior)
    If Not Politica::LicenciaCompatible(anterior\Edicion,Paquete\Dato\Edicion)
      texto+#LF$+#LF$+"No se autoriza la sustitución por la edición o licencia detectada. Solo puede instalarse por separado."
    Else : puedeReemplazar=1
    EndIf
  Else
    texto="Paquete: PureBasic "+nueva+#LF$+"No hay una instalación anterior seleccionada."
  EndIf
  texto+#LF$+#LF$+"Continúa solo si el paquete procede de una fuente de confianza."
  opcion=ElegirInstalacion("Versión detectada",texto,anterior\Ruta,puedeReemplazar,hayAnterior)
  If opcion=0
    LimpiarPaquete(@Paquete) : SetGadgetText(#EstadoUI,"Instalación cancelada. No se ha cambiado ninguna versión.") : ProcedureReturn
  EndIf
  Reemplazar=Bool(opcion=1) : OfrecerCorreccion=1
  Lanzar(3,"Instalando y comprobando PureBasic...")
EndProcedure

Procedure Drenar()
  Protected terminado,bien,texto.s,archivo,preferida.s, aviso.s, opcion, anterior.VersionPB, puedeCorregir, hayAnterior
  LockMutex(Mutex)
  ForEach Mensajes() : texto+Mensajes()+#LF$ : Next
  ClearList(Mensajes()) : terminado=Finalizado : bien=Resultado : Finalizado=0
  UnlockMutex(Mutex)
  If texto<>""
    texto="["+FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss",Date())+"]"+#LF$+texto
    archivo=OpenFile(#PB_Any,Estado+"/registro.log")
    If archivo : FileSeek(archivo,Lof(archivo)) : WriteString(archivo,texto,#PB_UTF8) : CloseFile(archivo) : EndIf
  EndIf
  If Not terminado
    If Ocupado : Tema::Pulso(#ProgresoUI) : EndIf
    ProcedureReturn
  EndIf
  WaitThread(Trabajo) : BloquearUI(0)
  If Fase=2 And bien : Decision() : ProcedureReturn : EndIf
  If Fase=3 And bien=Politica::#SustitucionBloqueada
    hayAnterior=LeerVersion(Objetivo,@anterior) : puedeCorregir=PuedeOfrecerCorreccion(@Paquete\Dato)
    texto=ErrorActual+#LF$+#LF$+"No se ha borrado ninguna instalación."
    If puedeCorregir
      texto+#LF$+"Corregir y comprobar: activa un adaptador privado de GCC, sin cambiar PureBasic ni el sistema. Solo se sustituirá la anterior si lo solicitaste y todas las pruebas pasan. Usa los accesos del gestor para beneficiarte de la corrección."
    Else
      texto+#LF$+"La validación completa no está acreditada. Puedes aceptar la instalación limitada por separado o cancelar."
    EndIf
    If Not Paquete\Dato\Comprobada : texto+#LF$+"No se ha validado ningún backend utilizable sin corregir. No puede instalarse todavía." : EndIf
    opcion=ElegirInstalacion("Limitación del compilador",texto,anterior\Ruta,0,hayAnterior,1,puedeCorregir,Paquete\Dato\Comprobada)
    If opcion=0
      LimpiarPaquete(@Paquete) : SetGadgetText(#EstadoUI,"Instalación cancelada.") : ProcedureReturn
    EndIf
    OfrecerCorreccion=0
    If opcion=3
      AceptarLimitacion=0 : Paquete\Dato\Correccion=#CORRECCION_MEMCPY : Paquete\Dato\Comprobada=0
      Lanzar(3,"Aplicando corrección local y repitiendo las pruebas...") : ProcedureReturn
    EndIf
    Reemplazar=0 : AceptarLimitacion=1
    Lanzar(3,"Terminando la instalación...") : ProcedureReturn
  EndIf
  aviso=ErrorActual
  If Fase=3 And bien : preferida=LeerTexto(Estado+"/ultima.txt") : EndIf
  If Fase>=5 : preferida=Objetivo : EndIf
  Refrescar(preferida)
  Select Fase
    Case 1 : SetGadgetText(#EstadoUI,"Selecciona un paquete para instalar o actualizar.")
    Case 4
      If bien : SetGadgetText(#EstadoUI,"Instalación existente registrada.") : Else : SetGadgetText(#EstadoUI,"No se pudo registrar.") : MessageRequester("Aviso",aviso) : EndIf
    Case 5
      If bien=2 : SetGadgetText(#EstadoUI,"Versión retirada y recuperable.") : MessageRequester("PureBasic","La carpeta y el perfil se conservan. Puedes restaurar la versión o eliminarla definitivamente desde la lista.") : ElseIf bien : SetGadgetText(#EstadoUI,"Versión eliminada.") : MessageRequester("PureBasic","La instalación seleccionada se ha eliminado. Se conservan las otras versiones y las copias de preferencias personales.") : Else : SetGadgetText(#EstadoUI,"Desinstalación no completada.") : MessageRequester("Aviso",aviso) : EndIf
    Case 6
      If bien : SetGadgetText(#EstadoUI,"Acceso directo creado.") : MessageRequester("PureBasic","Acceso actualizado en el escritorio y el menú. Si Cinnamon lo solicita, permite su ejecución."+#LF$+aviso) : Else : SetGadgetText(#EstadoUI,"No se pudo crear el acceso.") : MessageRequester("Aviso",aviso) : EndIf
    Case 7
      If bien : SetGadgetText(#EstadoUI,"Versión restaurada.") : If bien=2 : MessageRequester("PureBasic","La versión se ha restaurado. Puedes crear su acceso manualmente."+#LF$+aviso) : EndIf : Else : SetGadgetText(#EstadoUI,"No se pudo restaurar.") : MessageRequester("Aviso",aviso) : EndIf
    Case 2,3
      If bien=Politica::#Instalada
        SetGadgetText(#EstadoUI,"Instalación completada.")
        If Reemplazar : texto="La nueva versión está instalada y la anterior se conserva retirada. Puedes restaurarla o eliminarla definitivamente." : Else : texto="La nueva versión está instalada. Las anteriores se conservan." : EndIf
        If LeerVersion(preferida,@anterior) And anterior\Correccion<>"" : texto+#LF$+#LF$+"Corrección local activa. Abre PureBasic desde los accesos del gestor." : EndIf
        If aviso<>"" : texto+#LF$+#LF$+"Limitación detectada: "+aviso : EndIf
        MessageRequester("PureBasic",texto)
      ElseIf bien=Politica::#InstaladaLimitada
        SetGadgetText(#EstadoUI,"Instalada en paralelo · validación limitada.")
        MessageRequester("Instalación limitada","La nueva versión está disponible, pero no supera todas las pruebas. No se ha sustituido la instalación anterior."+#LF$+#LF$+aviso)
      ElseIf bien=Politica::#ConIncidencias
        SetGadgetText(#EstadoUI,"Instalación nueva conservada; revisa el aviso.")
        MessageRequester("Instalación con incidencias","La nueva versión está instalada, pero no se completaron todas las operaciones. Revisa el estado de la anterior y los accesos."+#LF$+#LF$+aviso)
      Else
        SetGadgetText(#EstadoUI,"No se completó la instalación.") : MessageRequester("Instalación no completada",aviso)
      EndIf
  EndSelect
EndProcedure

Procedure DistribuirVentana()
  Protected ancho=WindowWidth(#Ventana), alto=WindowHeight(#Ventana), interior=ancho-48, mitad=(interior-12)/2, yBotones=alto-206, xDerecha=24+mitad+12, yRuta=yBotones-62
  ResizeGadget(#CabeceraUI,24,20,interior,94)
  ResizeGadget(#TituloUI,20,10,interior-180,44)
  ResizeGadget(#SubtituloUI,20,56,interior-40,25)
  ResizeGadget(#VersionUI,interior-140,20,120,26)
  ResizeGadget(#SeccionUI,24,130,220,24)
  ResizeGadget(#AyudaUI,244,130,interior-220,24)
  ResizeGadget(#Lista,24,162,interior,yRuta-170)
  SetGadgetItemAttribute(#Lista,0,#PB_ListIcon_ColumnWidth,160,0)
  SetGadgetItemAttribute(#Lista,1,#PB_ListIcon_ColumnWidth,120,1)
  SetGadgetItemAttribute(#Lista,2,#PB_ListIcon_ColumnWidth,interior-300,2)
  ResizeGadget(#RutaUI,24,yRuta,interior,18)
  ResizeGadget(#Detalle,24,yRuta+22,interior,30)
  ResizeGadget(#Instalar,24,yBotones,mitad,46)
  ResizeGadget(#Abrir,xDerecha,yBotones,mitad,46)
  ResizeGadget(#Existente,24,yBotones+56,mitad,36)
  ResizeGadget(#Oficial,xDerecha,yBotones+56,mitad,36)
  ResizeGadget(#Acceso,24,yBotones+100,mitad,36)
  ResizeGadget(#Eliminar,xDerecha,yBotones+100,mitad,36)
  ResizeGadget(#ProgresoUI,24,alto-60,interior,8)
  ResizeGadget(#PieUI,24,alto-46,84,32)
  ResizeGadget(#EstadoUI,112,alto-46,interior-236,40)
  ResizeGadget(#RegistroUI,ancho-166,alto-46,142,32)
EndProcedure

If Not OpenWindow(#Ventana,0,0,880,570,"Gestor PureBasic · "+#VERSION_GESTOR,#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget|#PB_Window_SizeGadget|#PB_Window_MaximizeGadget) : End 1 : EndIf
WindowBounds(#Ventana,800,550,#PB_Ignore,#PB_Ignore)
Define temaActivo=Tema::Inicializar()
Tema::Ventana(#Ventana)
ContainerGadget(#CabeceraUI,24,20,832,94) : Tema::Clase(#CabeceraUI,"pb-cabecera")
If temaActivo : SetGadgetColor(#CabeceraUI,#PB_Gadget_BackColor,RGB(24,62,75)) : EndIf
TextGadget(#TituloUI,20,10,620,44,"Gestor PureBasic") : Tema::Clase(#TituloUI,"pb-titulo")
TextGadget(#SubtituloUI,20,56,790,25,"Instala, actualiza y conserva tus entornos de desarrollo.") : Tema::Clase(#SubtituloUI,"pb-subtitulo")
TextGadget(#VersionUI,692,20,120,26,"VERSIÓN "+#VERSION_GESTOR,#PB_Text_Right) : Tema::Clase(#VersionUI,"pb-version")
CloseGadgetList()
TextGadget(#SeccionUI,24,130,220,24,"INSTALACIONES") : Tema::Clase(#SeccionUI,"pb-seccion")
TextGadget(#AyudaUI,244,130,612,24,"Selecciona una versión para gestionarla.",#PB_Text_Right) : Tema::Clase(#AyudaUI,"pb-secundario")
ListIconGadget(#Lista,24,162,832,140,"Versión",160,#PB_ListIcon_FullRowSelect|#PB_ListIcon_AlwaysShowSelection)
AddGadgetColumn(#Lista,1,"Edición",120) : AddGadgetColumn(#Lista,2,"Estado",532)
TextGadget(#RutaUI,24,302,832,18,"UBICACIÓN SELECCIONADA") : Tema::Clase(#RutaUI,"pb-subtitulo")
StringGadget(#Detalle,24,324,832,30,"",#PB_String_ReadOnly)
ButtonGadget(#Instalar,24,364,410,46,"Instalar / actualizar desde paquete…") : Tema::Clase(#Instalar,"pb-primario")
ButtonGadget(#Abrir,446,364,410,46,"Abrir versión seleccionada")
ButtonGadget(#Existente,24,420,410,36,"Añadir instalación existente…")
ButtonGadget(#Oficial,446,420,410,36,"Descargas oficiales")
ButtonGadget(#Acceso,24,464,410,36,"Crear acceso directo en escritorio")
ButtonGadget(#Eliminar,446,464,410,36,"Retirar versión seleccionada…") : Tema::Clase(#Eliminar,"pb-peligro")
ProgressBarGadget(#ProgresoUI,24,510,832,8,0,100) : HideGadget(#ProgresoUI,1)
TextGadget(#PieUI,24,524,84,32,"ESTADO") : Tema::Clase(#PieUI,"pb-seccion")
TextGadget(#EstadoUI,112,524,596,40,"Preparado.") : Tema::Clase(#EstadoUI,"pb-estado")
ButtonGadget(#RegistroUI,714,524,142,32,"Ver registro")
GadgetToolTip(#Instalar,"Selecciona un paquete oficial o arrástralo a esta ventana.")
GadgetToolTip(#Acceso,"Crea o recupera el acceso de la versión seleccionada.")
GadgetToolTip(#Eliminar,"Retira primero la versión de forma recuperable. La eliminación definitiva requiere otra confirmación.")
GadgetToolTip(#RegistroUI,"Abre el registro técnico con el visor de texto del sistema.")
DistribuirVentana()
EnableWindowDrop(#Ventana,#PB_Drop_Files,#PB_Drag_Copy)
EnableWindowDrop(#Ventana,#PB_Drop_Text,#PB_Drag_Copy)
AddWindowTimer(#Ventana,1,100)
If ErrorInicio<>""
  MessageRequester("Recuperación pendiente",ErrorInicio) : End 1
EndIf
Lanzar(1,"Buscando instalaciones existentes...")
Define evento,ruta.s,dato.VersionPB
Repeat
  evento=WaitWindowEvent()
  Select evento
    Case #PB_Event_SizeWindow : DistribuirVentana()
    Case #PB_Event_Timer : Drenar()
    Case #PB_Event_WindowDrop
      If EventDropType()=#PB_Drop_Files : IniciarPaquete(EventDropFiles()) : Else : IniciarPaquete(EventDropText()) : EndIf
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Lista : Detalle()
        Case #Instalar
          ruta=OpenFileRequester("Paquete oficial PureBasic Linux x64",Hogar+"/Descargas/","Paquetes TAR/GZIP|*.tgz;*.tar.gz;*.tar|Todos|*",0)
          If ruta<>"" : IniciarPaquete(ruta) : EndIf
        Case #Existente
          ruta=PathRequester("Carpeta raíz de PureBasic",Hogar)
          If ruta<>"" : Fuente=Normalizar(ruta) : If Fuente<>"" : Lanzar(4,"Registrando instalación existente...") : EndIf : EndIf
        Case #Abrir
          If Not Ocupado And LeerVersion(SeleccionId(),@dato)
            If dato\Estado="retirada"
              Objetivo=dato\Id : Lanzar(7,"Restaurando la carpeta retirada...")
            ElseIf dato\Estado="disponible"
              RunProgram(ProgramFilename(),"--perfil "+Citar(Hogar)+" --abrir "+Citar(dato\Id),Hogar)
            EndIf
          EndIf
        Case #Acceso
          If Not Ocupado And LeerVersion(SeleccionId(),@dato) And dato\Estado="disponible"
            Objetivo=dato\Id : Lanzar(6,"Comprobando y creando el acceso de esta versión...")
          EndIf
        Case #Eliminar
          If Not Ocupado And LeerVersion(SeleccionId(),@dato) And (dato\Estado="disponible" Or dato\Estado="retirada")
            ruta="Eliminar definitivamente PureBasic "+Etiqueta(@dato)+" ("+dato\Edicion+")?"+#LF$+#LF$+dato\Ruta+#LF$+#LF$+"Se borrará toda esa carpeta y sus accesos reconocidos. Las preferencias separadas se conservarán en copias; no se borrarán configuraciones compartidas ni otras versiones."+#LF$+#LF$+"Antes de continuar, guarda fuera de la carpeta cualquier proyecto personal. Los cambios posteriores al registro impedirán el borrado. Los archivos personales que ya existían al registrar la carpeta también se borrarían."
            If dato\Estado="disponible"
              ruta="Retirar PureBasic "+Etiqueta(@dato)+" de forma recuperable?"+#LF$+#LF$+dato\Ruta+#LF$+#LF$+"La carpeta completa, incluidos tus proyectos y preferencias, se conserva. Se retirarán los accesos asociados. Puedes restaurarla o eliminarla posteriormente."
            EndIf
            AutorizarPurgaExterna=0
            If ConfirmarBorrado(ruta,Bool(dato\Estado="retirada"))
              If dato\Estado="retirada" And dato\Tipo="externa"
                If InputRequester("Archivos de origen desconocido","Esta instalación fue importada. Revisa y respalda su contenido antes de borrarlo. Escribe ELIMINAR para confirmar la pérdida de todos sus archivos.","")<>"ELIMINAR" : Continue : EndIf
                AutorizarPurgaExterna=1
              EndIf
              Objetivo=dato\Id : Lanzar(5,"Comprobando la operación de mantenimiento...")
            EndIf
          EndIf
        Case #RegistroUI
          If Not Ocupado And FileSize(Estado+"/registro.log")>=0
            If Not RunProgram("/usr/bin/xdg-open",Citar(Estado+"/registro.log"),Hogar) : MessageRequester("Registro técnico","No se pudo abrir el registro: "+Estado+"/registro.log") : EndIf
          EndIf
        Case #Oficial : RunProgram("/usr/bin/xdg-open","https://www.purebasic.com/securedownload/",Hogar)
      EndSelect
    Case #PB_Event_CloseWindow
      If Ocupado
        MessageRequester("Operación en curso","La operación debe terminar antes de cerrar. No se interrumpirá el borrado ni la integración.")
      Else : Break
      EndIf
  EndSelect
ForEver
LimpiarPaquete(@Paquete)
BloquearNativo(DescriptorBloqueo,8) : CerrarNativo(DescriptorBloqueo)
