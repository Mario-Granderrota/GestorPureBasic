Structure ProgresoCopiaPB
  Bytes.q
  Entradas.i
EndStructure
Procedure CopiarArbolInterno(origen.s,destino.s,*progreso.ProgresoCopiaPB,nivel.i)
  Protected listado, nombre.s, entrada.s, salida.s, tipo, bien=#True, permisos
  If nivel>64 Or Cancelacion() : ProcedureReturn Fallar("Copia cancelada o demasiado profunda.") : EndIf
  If Dentro(destino,origen) Or origen=destino : ProcedureReturn Fallar("El destino no puede estar dentro del origen.") : EndIf
  If Not CrearCarpetas(destino) : ProcedureReturn Fallar("No se puede crear: "+destino) : EndIf
  listado=ExamineDirectory(#PB_Any,origen,"*")
  If Not listado : ProcedureReturn Fallar("No se puede leer: "+origen) : EndIf
  While NextDirectoryEntry(listado)
    nombre=DirectoryEntryName(listado)
    If nombre="." Or nombre=".." : Continue : EndIf
    entrada=origen+"/"+nombre : salida=destino+"/"+nombre : tipo=TipoArchivo(entrada) : *progreso\Entradas+1
    If Controles(nombre) Or *progreso\Entradas>30000 Or (tipo<>32768 And tipo<>16384)
      bien=Fallar("El origen contiene enlaces, archivos especiales o demasiadas entradas.") : Break
    EndIf
    If tipo=16384
      bien=CopiarArbolInterno(entrada,salida,*progreso,nivel+1)
    Else
      *progreso\Bytes+FileSize(entrada)
      If *progreso\Bytes>#MAXIMO_TOTAL Or Cancelacion() : bien=Fallar("Copia cancelada o demasiado grande.") : Break : EndIf
      permisos=GetFileAttributes(entrada)&511
      bien=CopyFile(entrada,salida)
      If bien : bien=SetFileAttributes(salida,permisos) : EndIf
      If bien : bien=Bool(FileSize(entrada)=FileSize(salida)) : EndIf
    EndIf
    If Not bien : Break : EndIf
  Wend
  FinishDirectory(listado)
  If Not bien And ErrorActual="" : Fallar("Copia incompleta: "+entrada) : EndIf
  ProcedureReturn bien
EndProcedure
Procedure CopiarArbol(origen.s,destino.s)
  Protected progreso.ProgresoCopiaPB
  ProcedureReturn CopiarArbolInterno(origen,destino,@progreso,0)
EndProcedure
Procedure.s BuscarRaiz(carpeta.s)
  Protected listado, nombre.s, cantidad, candidata.s
  If FileSize(carpeta+"/compilers")=-2 : ProcedureReturn carpeta : EndIf
  listado=ExamineDirectory(#PB_Any,carpeta,"*")
  If listado
    While NextDirectoryEntry(listado)
      nombre=DirectoryEntryName(listado)
      If nombre<>"." And nombre<>".."
        cantidad+1 : If DirectoryEntryType(listado)=#PB_DirectoryEntry_Directory : candidata=carpeta+"/"+nombre : EndIf
      EndIf
    Wend
    FinishDirectory(listado)
  EndIf
  If cantidad=1 And FileSize(candidata+"/compilers")=-2 : ProcedureReturn candidata : EndIf
  Fallar("No se encuentra una única raíz PureBasic con su carpeta compilers.")
EndProcedure
Procedure.s PrepararContenido(origen.s,trabajo.s)
  Protected carpeta.s
  If TipoArchivo(origen)=16384
    carpeta=BuscarRaiz(origen)
    If carpeta<>"" And CopiarArbol(carpeta,trabajo+"/contenido") : ProcedureReturn trabajo+"/contenido" : EndIf
  ElseIf ExtraerTar(origen,trabajo)
    ProcedureReturn BuscarRaiz(trabajo)
  EndIf
  ProcedureReturn ""
EndProcedure
; Persistir un SDK recién extraído antes de publicar su registro.
Procedure SincronizarArbol(carpeta.s,nivel.i=0)
  Protected listado,nombre.s,ruta.s,tipo,bien=#True
  If nivel>64 Or Cancelacion() Or TipoArchivo(carpeta)<>16384 : ProcedureReturn #False : EndIf
  listado=ExamineDirectory(#PB_Any,carpeta,"*")
  If Not listado : ProcedureReturn #False : EndIf
  While NextDirectoryEntry(listado)
    nombre=DirectoryEntryName(listado)
    If nombre="." Or nombre=".." : Continue : EndIf
    ruta=carpeta+"/"+nombre : tipo=TipoArchivo(ruta)
    If Cancelacion() : bien=#False : Break : EndIf
    Select tipo
      Case 32768 : bien=SincronizarArchivo(ruta)
      Case 16384 : bien=SincronizarArbol(ruta,nivel+1)
      Default : bien=#False
    EndSelect
    If Not bien : Break : EndIf
  Wend
  FinishDirectory(listado)
  If bien : bien=SincronizarDirectorio(carpeta) : EndIf
  ProcedureReturn bien
EndProcedure
Procedure CrearManifiesto(carpeta.s,archivo.s)
  Protected NewList lineas.s()
  Protected NewList pendientes.s()
  Protected relativo.s, listado, nombre.s, ruta.s, tipo, texto.s, contador, tamano.q, bytes.q, huella.s, longitud.q
  AddElement(pendientes()) : pendientes()=""
  While ListSize(pendientes())>0
    FirstElement(pendientes()) : relativo=pendientes() : DeleteElement(pendientes())
    listado=ExamineDirectory(#PB_Any,carpeta+"/"+relativo,"*")
    If Not listado : ProcedureReturn Fallar("No se puede examinar el contenido para su manifiesto.") : EndIf
    While NextDirectoryEntry(listado)
      nombre=DirectoryEntryName(listado)
      If nombre="." Or nombre=".." : Continue : EndIf
      ruta=relativo+nombre : tipo=TipoArchivo(carpeta+"/"+ruta) : contador+1
      If Controles(ruta) Or contador>30000 Or (tipo<>32768 And tipo<>16384) Or Cancelacion()
        FinishDirectory(listado) : ProcedureReturn Fallar("El contenido tiene enlaces, archivos especiales o se ha cancelado.")
      EndIf
      If tipo=16384
        AddElement(lineas()) : lineas()="D "+Str(GetFileAttributes(carpeta+"/"+ruta)&511)+" "+ruta
        AddElement(pendientes()) : pendientes()=ruta+"/"
      Else
        longitud=FileSize(carpeta+"/"+ruta)
        If longitud<0 : FinishDirectory(listado) : ProcedureReturn Fallar("No se puede leer el archivo: "+ruta) : EndIf
        tamano+longitud
        If tamano>#MAXIMO_TOTAL : FinishDirectory(listado) : ProcedureReturn Fallar("Contenido demasiado grande.") : EndIf
        huella=FileFingerprint(carpeta+"/"+ruta,#PB_Cipher_SHA2,256)
        If Len(huella)<>64 : FinishDirectory(listado) : ProcedureReturn Fallar("No se pudo calcular la huella: "+ruta) : EndIf
        AddElement(lineas()) : lineas()="F "+Str(GetFileAttributes(carpeta+"/"+ruta)&511)+" "+huella+" "+ruta
      EndIf
    Wend
    FinishDirectory(listado)
  Wend
  SortList(lineas(),#PB_Sort_Ascending)
  ForEach lineas()
    If Cancelacion() : ProcedureReturn Fallar("Registro de contenido cancelado.") : EndIf
    bytes+StringByteLength(lineas(),#PB_UTF8)+1
    If bytes>8388608 : ProcedureReturn Fallar("El manifiesto supera el tamaño admitido.") : EndIf
    texto+lineas()+#LF$
  Next
  ProcedureReturn Guardar(archivo,texto)
EndProcedure
Procedure VerificarContenido(*version.VersionPB)
  Protected temporal.s=Estado+"/comprobacion-"+IdNuevo()+".txt", bien
  If Not IdValido(*version\Id) Or *version\Manifiesto<>Estado+"/versiones/"+*version\Id+".manifest" Or TipoArchivo(*version\Manifiesto)<>32768 Or Canonica(*version\Manifiesto)<>*version\Manifiesto Or Canonica(*version\Ruta)<>*version\Ruta Or TipoArchivo(*version\Ruta)<>16384 Or Len(*version\Huella)<>64 : ProcedureReturn Fallar("La ruta o el manifiesto de la versión no son válidos.") : EndIf
  If FileFingerprint(*version\Manifiesto,#PB_Cipher_SHA2,256)<>*version\Huella : ProcedureReturn Fallar("El manifiesto está alterado o ausente.") : EndIf
  bien=CrearManifiesto(*version\Ruta,temporal)
  If bien : bien=Bool(FileFingerprint(temporal,#PB_Cipher_SHA2,256)=*version\Huella) : EndIf
  DeleteFile(temporal)
  If Not bien And ErrorActual="" : Fallar("La carpeta ha cambiado desde su registro. Se conserva para revisión.") : EndIf
  ProcedureReturn bien
EndProcedure
