Procedure Controles(texto.s)
  Protected indice, codigo
  For indice=1 To Len(texto)
    codigo=Asc(Mid(texto,indice,1))
    If codigo<32 Or codigo=127 : ProcedureReturn #True : EndIf
  Next
EndProcedure
Procedure.s Canonica(ruta.s)
  Protected *nombre=UTF8(ruta), *buffer=AllocateMemory(4096), salida.s
  If *buffer And realpath_(*nombre,*buffer) : salida=PeekS(*buffer,-1,#PB_UTF8) : EndIf
  FreeMemory(*nombre) : If *buffer : FreeMemory(*buffer) : EndIf : ProcedureReturn salida
EndProcedure
Procedure TipoArchivo(ruta.s)
  Protected Dim informacion.a(255)
  If EstadoNativo(ruta,@informacion())<>0 : ProcedureReturn 0 : EndIf
  ProcedureReturn PeekL(@informacion()+24)&$F000
EndProcedure
Procedure Enlace(ruta.s)
  ProcedureReturn Bool(TipoArchivo(ruta)=40960)
EndProcedure
Procedure Dentro(ruta.s, padre.s)
  ProcedureReturn Bool(Left(ruta,Len(padre)+1)=padre+"/")
EndProcedure
Procedure CrearCarpetas(ruta.s)
  Protected indice, actual.s, parte.s
  ruta=RTrim(ruta,"/")
  If Left(ruta,1)<>"/" Or Controles(ruta) : ProcedureReturn #False : EndIf
  For indice=2 To CountString(ruta,"/")+1
    parte=StringField(ruta,indice,"/")
    If parte="." Or parte=".." : ProcedureReturn #False : EndIf
    If parte<>""
      actual+"/"+parte
      If Enlace(actual) : ProcedureReturn #False : EndIf
      If FileSize(actual)<>-2 And Not CreateDirectory(actual) : ProcedureReturn #False : EndIf
    EndIf
  Next
  ProcedureReturn #True
EndProcedure
Procedure IdValido(texto.s)
  Protected indice
  If Len(texto)<3 Or Len(texto)>80 Or Left(texto,1)="." : ProcedureReturn #False : EndIf
  For indice=1 To Len(texto)
    If Not FindString("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.",Mid(texto,indice,1)) : ProcedureReturn #False : EndIf
  Next
  ProcedureReturn #True
EndProcedure
Procedure.s IdNuevo()
  ProcedureReturn FormatDate("%yyyy%mm%dd-%hh%ii%ss",Date())+"-"+RSet(Hex(Random($7FFFFFFF)),8,"0")
EndProcedure
; fsync sobre directorios: persistencia de las entradas, no solo de los datos.
Procedure SincronizarDirectorio(ruta.s)
  Protected fd, bien
  fd=open_(ruta,655360|65536,0) ; O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC
  If fd<0 : ProcedureReturn #False : EndIf
  bien=Bool(SincronizarNativo(fd)=0)
  If CerrarNativo(fd)<>0 : bien=#False : EndIf
  ProcedureReturn bien
EndProcedure
Procedure SincronizarPadre(ruta.s)
  ProcedureReturn SincronizarDirectorio(RTrim(GetPathPart(ruta),"/"))
EndProcedure
Procedure SincronizarMovimiento(origen.s,destino.s)
  Protected bien=SincronizarPadre(origen)
  If GetPathPart(origen)<>GetPathPart(destino)
    If Not SincronizarPadre(destino) : bien=#False : EndIf
  EndIf
  If Not bien : PersistenciaIncierta=1 : Fallar("No se pudo sincronizar el traslado; se conserva el diario para recuperación.") : EndIf
  ProcedureReturn bien
EndProcedure
Procedure SincronizarArchivo(ruta.s)
  Protected fd=open_(ruta,655360,0), bien ; O_NOFOLLOW|O_CLOEXEC
  If fd<0 : ProcedureReturn #False : EndIf
  bien=Bool(SincronizarNativo(fd)=0)
  If CerrarNativo(fd)<>0 : bien=#False : EndIf
  ProcedureReturn bien
EndProcedure
Procedure BorrarPersistente(ruta.s)
  If Not DeleteFile(ruta) : ProcedureReturn #False : EndIf
  If Not SincronizarPadre(ruta)
    PersistenciaIncierta=1 : Registrar("No se pudo sincronizar el directorio tras eliminar: "+ruta)
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure
Procedure LeerTextoSeguro(ruta.s,*salida.String)
  Protected archivo, *buffer, cantidad.q,bien
  *salida\s=""
  If TipoArchivo(ruta)<>32768 Or FileSize(ruta)>8388608 : ProcedureReturn #False : EndIf
  archivo=ReadFile(#PB_Any,ruta)
  If Not archivo : ProcedureReturn #False : EndIf
  cantidad=Lof(archivo)
  If cantidad=0
    bien=#True
  ElseIf cantidad>0 And cantidad<=8388608
    *buffer=AllocateMemory(cantidad+1)
    If *buffer
      If ReadData(archivo,*buffer,cantidad)=cantidad And TextoSeguro::UTF8Valido(*buffer,cantidad)
        *salida\s=PeekS(*buffer,cantidad,#PB_UTF8|#PB_ByteLength) : bien=#True
      EndIf
      FreeMemory(*buffer)
    EndIf
  EndIf
  CloseFile(archivo) : ProcedureReturn bien
EndProcedure
Procedure.s LeerTexto(ruta.s)
  Protected salida.String
  LeerTextoSeguro(ruta,@salida) : ProcedureReturn salida\s
EndProcedure
Procedure Guardar(ruta.s, texto.s, permisos.i=384)
  Protected temporal.s=ruta+".nuevo-"+IdNuevo(), descriptor, *buffer, longitud.i, escritos.i, cantidad, bien
  CompilerIf #MODO_PRUEBAS
    If FalloEscritura<>"" And ruta=FalloEscritura : ProcedureReturn #False : EndIf
  CompilerEndIf
  If Enlace(ruta) Or Not SincronizarPadre(ruta) : ProcedureReturn #False : EndIf
  descriptor=open_(temporal,131265,384) ; O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW
  If descriptor<0 : ProcedureReturn #False : EndIf
  *buffer=UTF8(texto) : longitud=StringByteLength(texto,#PB_UTF8) : bien=#True
  If Not *buffer : CerrarNativo(descriptor) : DeleteFile(temporal) : ProcedureReturn #False : EndIf
  While escritos<longitud
    cantidad=EscribirNativo(descriptor,*buffer+escritos,longitud-escritos)
    If cantidad<=0 : bien=#False : Break : EndIf
    escritos+cantidad
  Wend
  If fchmod_(descriptor,permisos)<>0 : bien=#False : EndIf
  If SincronizarNativo(descriptor)<>0 : bien=#False : EndIf
  If CerrarNativo(descriptor)<>0 : bien=#False : EndIf
  FreeMemory(*buffer)
  If bien And RenombrarNativo(temporal,ruta)=0
    ; El nombre ya cambió: no se debe anunciar un fallo previo al commit.
    ; Si no se acredita su persistencia, bloquear operaciones irreversibles.
    If Not SincronizarPadre(ruta)
      PersistenciaIncierta=1 : Registrar("Escritura visible, persistencia no acreditada: "+ruta)
    EndIf
    ProcedureReturn #True
  EndIf
  DeleteFile(temporal) : ProcedureReturn #False
EndProcedure
Procedure.s Citar(texto.s)
  texto=ReplaceString(texto,Chr(92),Chr(92)+Chr(92))
  texto=ReplaceString(texto,Chr(34),Chr(92)+Chr(34))
  ProcedureReturn Chr(34)+texto+Chr(34)
EndProcedure
Procedure.s CitarDesktop(texto.s)
  texto=ReplaceString(texto,Chr(92),LSet("",4,Chr(92)))
  texto=ReplaceString(texto,Chr(34),LSet("",2,Chr(92))+Chr(34))
  texto=ReplaceString(texto,"$",LSet("",2,Chr(92))+"$")
  texto=ReplaceString(texto,"`",LSet("",2,Chr(92))+"`")
  texto=ReplaceString(texto,"%","%%")
  ProcedureReturn Chr(34)+texto+Chr(34)
EndProcedure
Procedure.s Normalizar(texto.s)
  Protected autoridad.s
  texto=Trim(texto)
  If Left(texto,1)=Chr(34) And Right(texto,1)=Chr(34) : texto=Mid(texto,2,Len(texto)-2) : EndIf
  If Left(texto,7)="file://"
    texto=Mid(texto,8)
    If Left(texto,1)<>"/"
      autoridad=StringField(texto,1,"/")
      If autoridad<>"localhost" : Fallar("La ubicación debe ser local.") : ProcedureReturn "" : EndIf
      texto=Mid(texto,Len(autoridad)+1)
    EndIf
    texto=URLDecoder(ReplaceString(texto,"+","%2B"),#PB_UTF8)
  ElseIf FindString(texto,"://")
    Fallar("Arrastra un archivo o una carpeta local.") : ProcedureReturn ""
  EndIf
  If Left(texto,2)="~/" : texto=Hogar+Mid(texto,2) : EndIf
  If texto="" Or Controles(texto) : Fallar("Ruta no válida o selección múltiple.") : ProcedureReturn "" : EndIf
  texto=Canonica(texto)
  If texto="" : Fallar("La ruta no existe o no puede leerse.") : EndIf
  ProcedureReturn texto
EndProcedure
