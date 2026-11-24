Procedure Inicializar(perfil.s="")
  Hogar=Canonica(GetHomeDirectory())
  If perfil<>"" : Hogar=Canonica(perfil) : EndIf
  If Hogar="" Or Hogar="/" : ProcedureReturn Fallar("Perfil de usuario no válido.") : EndIf
  Datos=Hogar+"/.local/share"
  Estado=Hogar+"/.local/state/gestor-purebasic-2"
  Almacen=Hogar+"/Apps/PureBasic-Gestor2"
  EjecutableGestor=Hogar+"/.local/lib/gestor-purebasic-2/gestor-purebasic"
  If Not CrearCarpetas(Estado+"/versiones") Or Not CrearCarpetas(Estado+"/perfiles") Or Not CrearCarpetas(Estado+"/copias") Or Not CrearCarpetas(Almacen+"/versiones") Or Not CrearCarpetas(Almacen+"/retiradas")
    ProcedureReturn Fallar("No se pueden preparar las carpetas del usuario.")
  EndIf
  SetFileAttributes(Estado,448) : SetFileAttributes(Almacen,448)
  If FileSize(Almacen+"/.gestor2")=-1
    ; No se borra ni adopta ningún contenido previo por crear esta marca.
    If Not Guardar(Almacen+"/.gestor2",#MARCA_GESTOR) : ProcedureReturn Fallar("No se puede marcar el almacén.") : EndIf
  ElseIf LeerTexto(Almacen+"/.gestor2")<>#MARCA_GESTOR
    ProcedureReturn Fallar("El almacén pertenece a otro programa.")
  EndIf
  ProcedureReturn #True
EndProcedure
; No iniciar una operacion nueva si hay un commit pendiente o incierto.
Procedure OperacionDisponible()
  If PersistenciaIncierta Or TipoArchivo(Estado+"/movimiento.json")<>0 Or TipoArchivo(Estado+"/transaccion/diario.json")<>0 Or TipoArchivo(Estado+"/ejecutable.pendiente")<>0
    ProcedureReturn Fallar("Hay una operación pendiente de recuperación. Reinicia el gestor antes de continuar.")
  EndIf
  ProcedureReturn #True
EndProcedure
Procedure GuardarVersion(*version.VersionPB)
  Protected json, texto.s, bien
  If Not IdValido(*version\Id) : ProcedureReturn #False : EndIf
  json=CreateJSON(#PB_Any) : If Not json : ProcedureReturn #False : EndIf
  InsertJSONStructure(JSONValue(json),*version,VersionPB) : texto=ComposeJSON(json,#PB_JSON_PrettyPrint)
  bien=Guardar(Estado+"/versiones/"+*version\Id+".json",texto) : FreeJSON(json) : ProcedureReturn bien
EndProcedure
; Los campos opcionales antiguos pueden faltar, pero no tener tipos incorrectos.
Procedure CamposJSON(valor.i, textos.s, numeros.s, obligatorios.s="")
  Protected indice, clave.s, campo
  If JSONType(valor)<>#PB_JSON_Object : ProcedureReturn #False : EndIf
  For indice=1 To CountString(obligatorios,"|")+1
    clave=StringField(obligatorios,indice,"|")
    If clave<>"" And Not GetJSONMember(valor,clave) : ProcedureReturn #False : EndIf
  Next
  For indice=1 To CountString(textos,"|")+1
    clave=StringField(textos,indice,"|") : If clave="" : Continue : EndIf
    campo=GetJSONMember(valor,clave)
    If campo And JSONType(campo)<>#PB_JSON_String : ProcedureReturn #False : EndIf
  Next
  For indice=1 To CountString(numeros,"|")+1
    clave=StringField(numeros,indice,"|") : If clave="" : Continue : EndIf
    campo=GetJSONMember(valor,clave)
    If campo
      If JSONType(campo)<>#PB_JSON_Number : ProcedureReturn #False : EndIf
      If GetJSONDouble(campo)<>GetJSONInteger(campo) : ProcedureReturn #False : EndIf
    EndIf
  Next
  ProcedureReturn #True
EndProcedure
Procedure DecodificarVersion(valor.i,id.s,*version.VersionPB)
  Protected dato.VersionPB
  If Not CamposJSON(valor,"Id|Ruta|Identidad|Numero|Edicion|Motor|Tipo|Estado|Perfil|Huella|Manifiesto|Origen|Fecha|Limitacion|Diagnostico|Validacion|RutaRetirada|Correccion","Comprobada|NivelC|NivelASM","Id|Ruta|Estado") : ProcedureReturn #False : EndIf
  ExtractJSONStructure(valor,@dato,VersionPB)
  If dato\Id<>id Or Left(dato\Ruta,1)<>"/" Or Controles(dato\Ruta) : ProcedureReturn #False : EndIf
  If dato\Estado<>"disponible" And dato\Estado<>"retirada" And dato\Estado<>"borrando" : ProcedureReturn #False : EndIf
  If dato\Comprobada<0 Or dato\Comprobada>1 Or dato\NivelC<0 Or dato\NivelC>2 Or dato\NivelASM<0 Or dato\NivelASM>2 : ProcedureReturn #False : EndIf
  CopyStructure(@dato,*version,VersionPB) : ProcedureReturn #True
EndProcedure
Procedure LeerVersion(id.s,*version.VersionPB)
  Protected json,bien
  If Not IdValido(id) : ProcedureReturn #False : EndIf
  json=ParseJSON(#PB_Any,LeerTexto(Estado+"/versiones/"+id+".json"))
  If Not json : ProcedureReturn #False : EndIf
  bien=DecodificarVersion(JSONValue(json),id,*version) : FreeJSON(json)
  ProcedureReturn bien
EndProcedure
Procedure CargarVersiones()
  Protected listado=ExamineDirectory(#PB_Any,Estado+"/versiones","*.json"), nombre.s, dato.VersionPB
  ClearList(Versiones())
  If listado
    While NextDirectoryEntry(listado)
      nombre=GetFilePart(DirectoryEntryName(listado),#PB_FileSystem_NoExtension)
      If LeerVersion(nombre,@dato)
        AddElement(Versiones()) : CopyStructure(@dato,@Versiones(),VersionPB)
      EndIf
    Wend
    FinishDirectory(listado)
  EndIf
EndProcedure
Procedure.s Activa()
  Protected id.s=LeerTexto(Estado+"/activa.txt"), dato.VersionPB
  If LeerVersion(id,@dato) And dato\Estado="disponible" : ProcedureReturn id : EndIf
EndProcedure
Procedure.s RutaPerfil(*version.VersionPB)
  If *version\Perfil="original" : ProcedureReturn "" : EndIf
  ProcedureReturn Estado+"/perfiles/"+*version\Id
EndProcedure
Procedure.s ArgumentosIDE(*version.VersionPB)
  Protected perfil.s=RutaPerfil(*version)
  If perfil="" : ProcedureReturn "" : EndIf
  ProcedureReturn "--preferences "+Citar(perfil+"/purebasic.prefs")+" --templates "+Citar(perfil+"/templates.prefs")+" --tools "+Citar(perfil+"/tools.prefs")+" --history "+Citar(perfil+"/history.db")
EndProcedure

; Bloqueo cooperativo por version. El descriptor permanece abierto durante el lanzamiento.
Procedure BloqueoVersion(id.s, exclusivo.i=0)
  Protected fd, carpeta.s=Estado+"/bloqueos", modo=5 ; LOCK_SH | LOCK_NB
  If Not IdValido(id) Or Not CrearCarpetas(carpeta) : Fallar("No se puede preparar el bloqueo de la versión.") : ProcedureReturn -1 : EndIf
  fd=open_(carpeta+"/"+id+".lock",655426,384) ; O_RDWR|O_CREAT|O_NOFOLLOW|O_CLOEXEC
  If fd<0 : Fallar("No se puede abrir el bloqueo de la versión.") : ProcedureReturn -1 : EndIf
  If exclusivo : modo=6 : EndIf
  If BloquearNativo(fd,modo)<>0 : CerrarNativo(fd) : Fallar("La versión está en uso por otra operación del gestor.") : ProcedureReturn -1 : EndIf
  ProcedureReturn fd
EndProcedure
