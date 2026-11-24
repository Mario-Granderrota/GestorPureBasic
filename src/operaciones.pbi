Procedure VersionEnUso(carpeta.s)
  Protected listado=ExamineDirectory(#PB_Any,"/proc","*"), nombre.s, ejecutable.s
  If listado
    While NextDirectoryEntry(listado)
      nombre=DirectoryEntryName(listado)
      If Val(nombre)>0
        ejecutable=Canonica("/proc/"+nombre+"/exe")
        If Dentro(ejecutable,carpeta)
          FinishDirectory(listado) : ProcedureReturn #True
        EndIf
      EndIf
    Wend
    FinishDirectory(listado)
  EndIf
EndProcedure
Procedure MontajesSinCruce(texto.s,raiz.s)
  Protected indice,linea.s,ruta.s,barra.s=Chr(92)
  If texto="" Or Right(texto,1)<>#LF$ : ProcedureReturn Fallar("No se puede acreditar la tabla de montajes.") : EndIf
  For indice=1 To CountString(texto,#LF$)
    linea=StringField(texto,indice,#LF$) : ruta=StringField(linea,5," ")
    If Left(ruta,1)<>"/" : ProcedureReturn Fallar("Tabla de montajes no reconocida.") : EndIf
    ruta=ReplaceString(ruta,barra+"040"," ") : ruta=ReplaceString(ruta,barra+"011",Chr(9)) : ruta=ReplaceString(ruta,barra+"012",#LF$) : ruta=ReplaceString(ruta,barra+"134",barra)
    If ruta=raiz Or Dentro(ruta,raiz) : ProcedureReturn Fallar("Existe un punto de montaje dentro de la instalación: "+ruta+". No se moverá ni borrará.") : EndIf
  Next
  ProcedureReturn #True
EndProcedure
Procedure SinMontajes(raiz.s)
  Protected fd=open_("/proc/self/mountinfo",0,0), *datos, leidos.i, total.i, texto.s, limite.i=1048576
  If fd<0 : ProcedureReturn Fallar("No se puede consultar la tabla de montajes.") : EndIf
  *datos=AllocateMemory(limite+1)
  If Not *datos : CerrarNativo(fd) : ProcedureReturn Fallar("Memoria insuficiente para consultar montajes.") : EndIf
  Repeat
    leidos=LeerNativo(fd,*datos+total,limite-total)
    If leidos<=0 : Break : EndIf
    total+leidos
  Until total>=limite
  CerrarNativo(fd)
  If leidos=0 And total<limite : texto=PeekS(*datos,total,#PB_UTF8|#PB_ByteLength) : EndIf
  FreeMemory(*datos)
  ProcedureReturn MontajesSinCruce(texto,raiz)
EndProcedure
Procedure RaizSinSolapamiento(ruta.s,id.s="")
  Protected listado=ExamineDirectory(#PB_Any,Estado+"/versiones","*.json"), otro.VersionPB, nombre.s, raiz.s, bien=#True
  If Not listado : ProcedureReturn Fallar("No se puede comprobar el catálogo de instalaciones.") : EndIf
  While NextDirectoryEntry(listado)
    nombre=GetFilePart(DirectoryEntryName(listado),#PB_FileSystem_NoExtension)
    If nombre=id : Continue : EndIf
    If Not LeerVersion(nombre,@otro) : bien=#False : Break : EndIf
    raiz=Canonica(otro\Ruta)
    If raiz="" : raiz=otro\Ruta : EndIf
    If ruta=raiz Or Dentro(ruta,raiz) Or Dentro(raiz,ruta) : bien=#False : Break : EndIf
  Wend
  FinishDirectory(listado)
  If Not bien : ProcedureReturn Fallar("Hay otra instalación solapada o un registro ilegible. No se moverá ni borrará la carpeta.") : EndIf
  ProcedureReturn #True
EndProcedure
Procedure RegistrarExistente(ruta.s)
  Protected dato.VersionPB, identidad.s
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  ruta=Canonica(ruta)
  If ruta="" Or Not Dentro(ruta,Hogar) Or ruta=Almacen Or Dentro(Estado,ruta) Or Dentro(Almacen,ruta)
    ProcedureReturn Fallar("Selecciona la carpeta concreta de PureBasic dentro de tu carpeta personal.")
  EndIf
  CargarVersiones()
  ForEach Versiones()
    If Versiones()\Ruta=ruta And Versiones()\Estado="disponible" : Registrar("La instalación ya está registrada.") : ProcedureReturn #True : EndIf
  Next
  If Dentro(ruta,Estado) Or Dentro(ruta,Almacen) Or Not RaizSinSolapamiento(ruta) Or Not EstructuraValida(ruta) : ProcedureReturn Fallar("Selecciona una instalación independiente fuera de las carpetas internas del gestor.") : EndIf
  dato\Id=IdNuevo() : dato\Ruta=ruta : dato\Tipo="externa" : dato\Estado="disponible" : dato\Motor="AUTO" : dato\Perfil="original"
  dato\Fecha=FormatDate("%yyyy-%mm-%dd %hh:%ii",Date()) : dato\Origen=ruta
  identidad=IdentidadEstatica(ruta)
  If Not PonerIdentidad(@dato,identidad) : ProcedureReturn Fallar("No se reconoce la identidad estática del compilador.") : EndIf
  dato\Manifiesto=Estado+"/versiones/"+dato\Id+".manifest"
  If Not CrearManifiesto(ruta,dato\Manifiesto) : ProcedureReturn #False : EndIf
  dato\Huella=FileFingerprint(dato\Manifiesto,#PB_Cipher_SHA2,256)
  If Not GuardarVersion(@dato) : DeleteFile(dato\Manifiesto) : ProcedureReturn Fallar("No se pudo registrar la instalación existente.") : EndIf
  Registrar("Registrada sin modificar: "+dato\Identidad+" · "+ruta) : ProcedureReturn #True
EndProcedure
Procedure RespaldarAjustes()
  Protected indice, origen.s, destino.s=Estado+"/copias/ajustes-"+IdNuevo()
  Protected Dim carpetas.s(2)
  carpetas(0)=Hogar+"/.purebasic" : carpetas(1)=Hogar+"/.config/purebasic" : carpetas(2)=Hogar+"/.config/PureBasic"
  If Not CrearCarpetas(destino) : ProcedureReturn Fallar("No se puede preparar la copia de configuración.") : EndIf
  For indice=0 To 2
    origen=carpetas(indice)
    If Enlace(origen)
      ProcedureReturn Fallar("La configuración contiene un enlace que debe revisarse antes de respaldarla: "+origen)
    ElseIf FileSize(origen)=-2
      If Not CopiarArbol(origen,destino+"/"+Str(indice)) : ProcedureReturn Fallar("No se pudo respaldar la configuración. Se conserva la instalación anterior.") : EndIf
      Registrar("Ajustes respaldados: "+origen)
    ElseIf Enlace(origen)
      ProcedureReturn Fallar("La configuración contiene un enlace que debe revisarse antes de respaldarla: "+origen)
    EndIf
  Next
  ProcedureReturn Guardar(destino+"/LEEME.txt","Copia de ajustes anterior a la activación. 0=.purebasic, 1=.config/purebasic, 2=.config/PureBasic. No se modificaron los originales.")
EndProcedure
Procedure Instalar(origen.s,motor.s="AUTO")
  Protected trabajo.s=Almacen+"/.trabajo-"+IdNuevo(), carpeta.s, bien, dato.VersionPB
  ErrorActual="" : origen=Canonica(origen)
  If origen="" Or (TipoArchivo(origen)<>32768 And TipoArchivo(origen)<>16384) : ProcedureReturn Fallar("El origen no es un paquete o carpeta legible.") : EndIf
  If TipoArchivo(origen)=32768 And (LCase(GetExtensionPart(origen))="xz" Or LCase(GetExtensionPart(origen))="bz2" Or LCase(GetExtensionPart(origen))="zip")
    ProcedureReturn Fallar("Utiliza el paquete oficial TGZ/TAR.GZ o TAR. También puedes extraer otro formato con tu gestor de archivos e instalar desde la carpeta resultante.")
  EndIf
  If Not CreateDirectory(trabajo) : ProcedureReturn Fallar("No se puede crear el área temporal.") : EndIf
  SetFileAttributes(trabajo,448) : Registrar("Preparando una instalación nueva, separada de la anterior.")
  carpeta=PrepararContenido(origen,trabajo) : bien=Bool(carpeta<>"")
  If bien
    dato\Id=IdNuevo() : dato\Ruta=carpeta : dato\Estado="disponible" : dato\Tipo="gestionada" : dato\Motor=motor : dato\Perfil="separado" : dato\Origen=origen
    dato\Fecha=FormatDate("%yyyy-%mm-%dd %hh:%ii",Date())
    bien=Identificar(@dato)
    If bien And dato\Edicion="gratuita" And Not PermitirGratuita
      bien=Fallar("El paquete es de la edición gratuita. Para actualizar tu licencia completa usa su descarga oficial. Si deseas instalar también una gratuita separada, marca esa opción expresamente.")
    EndIf
    If bien : bien=VerificarVersion(@dato) : EndIf
  EndIf
  If bien And Not Cancelacion()
    bien=PublicarVersion(@dato,Almacen+"/versiones/"+dato\Id)
  Else
    bien=#False
  EndIf
  If TipoArchivo(Estado+"/movimiento.json")=0 : DeleteDirectory(trabajo,"",#PB_FileSystem_Recursive) : EndIf
  If bien
    Registrar("Instalada y comprobada: "+dato\Identidad+". Selecciónala y pulsa Activar.")
    Guardar(Estado+"/ultima.txt",dato\Id)
  ElseIf ErrorActual=""
    Fallar("La instalación no se completó. La versión anterior sigue seleccionada.")
  EndIf
  ProcedureReturn bien
EndProcedure
Procedure PublicarAccesos(List accesos.AccesoPB())
  ForEach accesos()
    If accesos()\Texto=""
      If TipoArchivo(accesos()\Ruta)<>0
        If TipoArchivo(accesos()\Ruta)<>32768 Or Not BorrarPersistente(accesos()\Ruta) : ProcedureReturn Fallar("No se pudo retirar el acceso anterior: "+accesos()\Ruta) : EndIf
      EndIf
    ElseIf Not Guardar(accesos()\Ruta,accesos()\Texto,accesos()\Permisos)
      ProcedureReturn Fallar("No se pudo actualizar el acceso: "+accesos()\Ruta)
    EndIf
  Next
  ProcedureReturn #True
EndProcedure
Procedure SincronizarAccesos()
  Protected dato.VersionPB, bien
  Protected NewList accesos.AccesoPB(), NewList rutas.s()
  If Not LeerVersion(Activa(),@dato) Or Not EstructuraValida(dato\Ruta) : ProcedureReturn Fallar("Registra y selecciona primero una instalación disponible.") : EndIf
  If Not PrepararEjecutable() Or Not PlanificarAccesos(@dato,accesos()) Or Not RespaldarAccesos(accesos()) : ProcedureReturn #False : EndIf
  ForEach accesos() : AddElement(rutas()) : rutas()=accesos()\Ruta : Next
  If Not IniciarTransaccion(rutas()) : ProcedureReturn #False : EndIf
  bien=PublicarAccesos(accesos())
  If bien : bien=ConfirmarTransaccion() : EndIf
  If Not bien : RecuperarTransaccion() : ProcedureReturn Fallar("No se completó la actualización de accesos. Se intentó recuperar su estado anterior.") : EndIf
  MarcarAccesos(accesos()) : Registrar("Accesos e icono sincronizados. No se ha ejecutado ni cambiado el compilador.") : ProcedureReturn #True
EndProcedure
Procedure Activar(id.s,permitirLimitacion.i=0,verificar.i=1,soloPropios.i=0)
  Protected dato.VersionPB, actual.VersionPB, previa.s=Activa(), menu.s=Datos+"/applications/purebasic-nativo-2.desktop", texto.s, bien, mensaje.s
  Protected NewList rutas.s(), NewList accesos.AccesoPB()
  ErrorActual=""
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  If Not LeerVersion(id,@dato) Or dato\Estado<>"disponible" : ProcedureReturn Fallar("Selecciona una versión disponible.") : EndIf
  If Not VerificarContenido(@dato) : ProcedureReturn #False : EndIf
  If verificar And Not VerificarVersion(@dato) : ProcedureReturn #False : EndIf
  If Not verificar And Not dato\Comprobada : ProcedureReturn Fallar("La instalación todavía no está comprobada.") : EndIf
  If dato\Limitacion<>"" And Not permitirLimitacion
    GuardarVersion(@dato)
    ProcedureReturn Fallar("No se ha cambiado la selección anterior. Esta versión tiene una limitación comprobada: "+dato\Limitacion+" Puedes elegir otro backend o aceptar expresamente esa limitación al activar.")
  EndIf
  If Not RespaldarAjustes() Or Not PrepararEjecutable() : ProcedureReturn #False : EndIf
  If Not PlanificarAccesos(@dato,accesos(),soloPropios) Or Not RespaldarAccesos(accesos()) : ProcedureReturn #False : EndIf
  ForEach accesos() : AddElement(rutas()) : rutas()=accesos()\Ruta : Next
  AddElement(rutas()) : rutas()=Estado+"/activa.txt"
  AddElement(rutas()) : rutas()=Estado+"/anterior.txt" : AddElement(rutas()) : rutas()=Estado+"/versiones/"+id+".json"
  If Not IniciarTransaccion(rutas()) : ProcedureReturn #False : EndIf
  bien=PublicarAccesos(accesos())
  If bien : bien=Guardar(Estado+"/anterior.txt",previa) : EndIf
  If bien : bien=GuardarVersion(@dato) : EndIf
  If bien : bien=Guardar(Estado+"/activa.txt",id) : EndIf
  If bien : bien=Bool(LeerTexto(Estado+"/activa.txt")=id And LeerTexto(menu)=TextoAcceso(@dato)) : EndIf
  If bien : bien=ConfirmarTransaccion() : EndIf
  If Not bien
    mensaje=ErrorActual
    If RecuperarTransaccion()
      Fallar("No se pudo activar. Se ha recuperado la selección anterior. "+mensaje)
    Else
      Fallar("Activación incompleta; se conserva el diario para recuperar el estado. Revisa permisos y espacio.")
    EndIf
    ProcedureReturn #False
  EndIf
  MarcarAccesos(accesos())
  Registrar("Activa: "+dato\Identidad+" · backend "+dato\Motor) : ProcedureReturn #True
EndProcedure
Procedure Retirar(id.s, permitirActiva.i=0)
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  Protected dato.VersionPB, movimiento.MovimientoPB, anterior.s
  If Not LeerVersion(id,@dato) Or dato\Estado<>"disponible" : ProcedureReturn Fallar("Selecciona una versión disponible.") : EndIf
  If id=Activa() And Not permitirActiva : ProcedureReturn Fallar("Activa primero otra versión. No se retira la versión seleccionada como activa.") : EndIf
  If VersionEnUso(dato\Ruta) : ProcedureReturn Fallar("Cierra el IDE y los compiladores de esa versión antes de retirarla.") : EndIf
  If Not RutaDisponibleValida(@dato,dato\Ruta) : ProcedureReturn Fallar("La ruta no corresponde al tipo de instalación registrado.") : EndIf
  If Canonica(dato\Ruta)<>dato\Ruta Or Not Dentro(dato\Ruta,Hogar) Or dato\Ruta=Estado Or dato\Ruta=Almacen Or Dentro(Estado,dato\Ruta) Or Dentro(dato\Ruta,Estado) Or Dentro(Almacen,dato\Ruta) Or Not RaizSinSolapamiento(dato\Ruta,id) Or Not EstructuraValida(dato\Ruta) Or Not VerificarContenido(@dato) : ProcedureReturn #False : EndIf
  movimiento\Id=id : movimiento\Origen=dato\Ruta : movimiento\Destino=Almacen+"/retiradas/"+id : movimiento\Accion="retirar"
  movimiento\Anterior=LeerTexto(Estado+"/versiones/"+id+".json")
  If Canonica(Almacen+"/retiradas")<>Almacen+"/retiradas" Or TipoArchivo(movimiento\Destino)<>0 : ProcedureReturn Fallar("La carpeta de retirada no es segura o ya existe.") : EndIf
  If Not SinMontajes(dato\Ruta) : ProcedureReturn #False : EndIf
  If Not GuardarMovimiento(@movimiento) Or PersistenciaIncierta : ProcedureReturn Fallar("No se puede acreditar el diario de retirada.") : EndIf
  If RenombrarSinReemplazo(-100,movimiento\Origen,-100,movimiento\Destino,1)<>0
    DeleteFile(Estado+"/movimiento.json") : ProcedureReturn Fallar("No se pudo mover la carpeta. No se borró nada; puede estar en otro sistema de archivos.")
  EndIf
  If Not SincronizarMovimiento(movimiento\Origen,movimiento\Destino) : ProcedureReturn #False : EndIf
  dato\RutaRetirada=dato\Ruta : dato\Ruta=movimiento\Destino : dato\Estado="retirada"
  If Not GuardarVersion(@dato) : RecuperarMovimiento() : ProcedureReturn Fallar("No se pudo registrar la retirada. Se intentó recuperar la carpeta anterior.") : EndIf
  If PersistenciaIncierta Or Not BorrarPersistente(Estado+"/movimiento.json") : ProcedureReturn Fallar("Retirada registrada; recuperación del diario pendiente.") : EndIf
  Registrar("Versión retirada y recuperable: "+dato\Identidad) : ProcedureReturn #True
EndProcedure
Procedure Restaurar(id.s)
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  Protected dato.VersionPB, movimiento.MovimientoPB
  If Not LeerVersion(id,@dato) Or dato\Estado<>"retirada" : ProcedureReturn Fallar("Selecciona una versión retirada.") : EndIf
  If dato\Ruta<>Almacen+"/retiradas/"+id Or Canonica(dato\Ruta)<>dato\Ruta Or VersionEnUso(dato\Ruta) : ProcedureReturn Fallar("La carpeta retirada no corresponde a la versión o está en uso.") : EndIf
  movimiento\Id=id : movimiento\Origen=dato\Ruta : movimiento\Destino=Almacen+"/versiones/"+id : movimiento\Accion="restaurar"
  If dato\RutaRetirada<>"" : movimiento\Destino=dato\RutaRetirada : ElseIf dato\Tipo="externa" : movimiento\Destino=dato\Origen : EndIf
  If Not RutaDisponibleValida(@dato,movimiento\Destino) Or Canonica(RTrim(GetPathPart(movimiento\Destino),"/"))<>RTrim(GetPathPart(movimiento\Destino),"/") Or Not RaizSinSolapamiento(movimiento\Destino,id) : ProcedureReturn Fallar("La ruta original no es segura o se solapa con otra instalación.") : EndIf
  movimiento\Anterior=LeerTexto(Estado+"/versiones/"+id+".json")
  If TipoArchivo(movimiento\Destino)<>0 : ProcedureReturn Fallar("La ubicación original ya está ocupada.") : EndIf
  If Not SinMontajes(dato\Ruta) Or Not VerificarContenido(@dato) Or Not GuardarMovimiento(@movimiento) Or PersistenciaIncierta : ProcedureReturn #False : EndIf
  If RenombrarSinReemplazo(-100,movimiento\Origen,-100,movimiento\Destino,1)<>0 : DeleteFile(Estado+"/movimiento.json") : ProcedureReturn Fallar("No se pudo restaurar la carpeta.") : EndIf
  If Not SincronizarMovimiento(movimiento\Origen,movimiento\Destino) : ProcedureReturn #False : EndIf
  dato\Ruta=movimiento\Destino : dato\Estado="disponible" : dato\RutaRetirada=""
  If Not GuardarVersion(@dato) : RecuperarMovimiento() : ProcedureReturn Fallar("No se pudo registrar la restauración.") : EndIf
  If PersistenciaIncierta Or Not BorrarPersistente(Estado+"/movimiento.json") : ProcedureReturn Fallar("Restaurada; queda pendiente confirmar el diario.") : EndIf
  Registrar("Restaurada: "+dato\Identidad) : ProcedureReturn #True
EndProcedure
Procedure BorrarDefinitivamente(id.s, autorizarExterna.i=0)
  Protected dato.VersionPB, esperada.s=Almacen+"/retiradas/"+id
  If Not LeerVersion(id,@dato) Or (dato\Estado<>"retirada" And dato\Estado<>"borrando") : ProcedureReturn Fallar("Retira primero la versión y comprueba su contenido.") : EndIf
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  If dato\Tipo<>"gestionada" And (dato\Tipo<>"externa" Or Not autorizarExterna) : ProcedureReturn Fallar("El origen de los archivos personales no está acreditado. Se requiere autorización específica para purgar una instalación importada.") : EndIf
  If dato\Ruta<>esperada Or Canonica(dato\Ruta)<>esperada Or id=Activa() Or VersionEnUso(dato\Ruta)
    ProcedureReturn Fallar("La carpeta no cumple las condiciones de borrado.")
  EndIf
  If dato\Estado="borrando" : ProcedureReturn Fallar("Hubo un borrado incompleto. Revisa manualmente la carpeta antes de continuar.") : EndIf
  If Not RaizSinSolapamiento(dato\Ruta,id) Or Not SinMontajes(dato\Ruta) Or Not VerificarContenido(@dato) : ProcedureReturn #False : EndIf
  dato\Estado="borrando"
  If PersistenciaIncierta Or Not GuardarVersion(@dato) Or PersistenciaIncierta : ProcedureReturn Fallar("No se pudo acreditar la intención de borrado. No se elimina la carpeta.") : EndIf
  If Not DeleteDirectory(esperada,"",#PB_FileSystem_Recursive) Or FileSize(esperada)<>-1
    ProcedureReturn Fallar("Borrado incompleto. No se anuncia éxito; conserva el registro para revisar los archivos restantes.")
  EndIf
  If Not SincronizarPadre(esperada) : PersistenciaIncierta=1 : ProcedureReturn Fallar("La carpeta se eliminó, pero no se acreditó la persistencia del borrado. Se conserva el registro.") : EndIf
  If TipoArchivo(dato\Manifiesto)<>0 And Not BorrarPersistente(dato\Manifiesto) : ProcedureReturn Fallar("Se eliminó la instalación, pero no se pudo retirar el manifiesto. Se conserva el registro.") : EndIf
  If Not BorrarPersistente(Estado+"/versiones/"+id+".json") : ProcedureReturn Fallar("La carpeta se borró, pero no se pudo retirar su registro.") : EndIf
  Registrar("Eliminada definitivamente: "+dato\Identidad) : ProcedureReturn #True
EndProcedure
Procedure DetectarExistentes()
  Protected indice, candidata.s, dato.VersionPB, cantidad, id.s
  Protected NewList raices.s()
  BuscarRaicesAccesos(raices(),EscritorioUsuario())
  BuscarRaicesAccesos(raices(),Datos+"/applications")
  ForEach raices()
    If Not RegistrarExistente(raices()) : Registrar("No se registró el destino de un acceso: "+raices()) : EndIf
  Next
  Protected Dim candidatas.s(4)
  candidatas(0)=Hogar+"/purebasic_v7" : candidatas(1)=Hogar+"/purebasic"
  candidatas(2)=Hogar+"/Apps/PureBasic/actual" : candidatas(3)=Hogar+"/Apps/purebasic" : candidatas(4)=Hogar+"/PureBasic"
  For indice=0 To 4
    candidata=Canonica(candidatas(indice))
    If candidata<>"" And FileSize(candidata+"/compilers/pbcompiler")>0
      If Not RegistrarExistente(candidata) : Registrar("No se registró automáticamente: "+candidatas(indice)) : EndIf
    EndIf
  Next
  CargarVersiones()
  ForEach Versiones()
    If Versiones()\Estado="disponible" : cantidad+1 : id=Versiones()\Id : EndIf
  Next
  If Activa()="" And cantidad=1
    Guardar(Estado+"/activa.txt",id)
    Registrar("Instalación anterior detectada. Sus accesos y configuración originales se conservan.")
  EndIf
  ProcedureReturn #True
EndProcedure
Procedure ComprobarRegistrada(id.s,motor.s="AUTO")
  Protected dato.VersionPB
  If Not LeerVersion(id,@dato) Or dato\Estado<>"disponible" : ProcedureReturn Fallar("Selecciona una versión disponible.") : EndIf
  If Not VerificarContenido(@dato) : ProcedureReturn #False : EndIf
  dato\Motor=motor
  If Not VerificarVersion(@dato) : ProcedureReturn #False : EndIf
  If Not GuardarVersion(@dato) : ProcedureReturn Fallar("No se pudo registrar la comprobación.") : EndIf
  ProcedureReturn #True
EndProcedure
Procedure Desactivar()
  Protected anterior.s=Activa(), menu.s=Datos+"/applications/purebasic-nativo-2.desktop", bien
  Protected NewList rutas.s(), NewList accesos.AccesoPB()
  If FileSize(menu)>=0 And (Enlace(menu) Or Not FindString(LeerTexto(menu),#MARCA_GESTOR)) : ProcedureReturn Fallar("Se conserva un menú ajeno.") : EndIf
  CargarVersiones()
  BuscarAccesos(accesos(),Datos+"/applications","",1)
  BuscarAccesos(accesos(),EscritorioUsuario(),"",1)
  If FileSize(menu)>=0 : AgregarAcceso(accesos(),menu,"",420) : EndIf
  If Not RespaldarAccesos(accesos()) : ProcedureReturn #False : EndIf
  AddElement(rutas()) : rutas()=Estado+"/activa.txt" : AddElement(rutas()) : rutas()=Estado+"/anterior.txt"
  ForEach accesos() : AddElement(rutas()) : rutas()=accesos()\Ruta : Next
  If Not IniciarTransaccion(rutas()) : ProcedureReturn #False : EndIf
  bien=Guardar(Estado+"/anterior.txt",anterior)
  If bien : bien=Guardar(Estado+"/activa.txt","") : EndIf
  If bien : bien=PublicarAccesos(accesos()) : EndIf
  If bien : bien=ConfirmarTransaccion() : EndIf
  If Not bien : RecuperarTransaccion() : ProcedureReturn Fallar("No se pudo desactivar; se intentó recuperar la selección anterior.") : EndIf
  Registrar("Accesos propios del menú y escritorio desactivados. Las versiones y las copias de los accesos anteriores se conservan.") : ProcedureReturn #True
EndProcedure
Procedure.s SimularPreparacion()
  Protected resultado.ResultadoProcesoPB
  If TipoArchivo("/usr/bin/apt-get")<>32768 Or TipoArchivo("/usr/bin/pkexec")<>32768
    Fallar("No se encuentra APT o la autorización gráfica de Mint. Utiliza el Gestor de paquetes para instalar build-essential y libgtk-3-dev.") : ProcedureReturn ""
  EndIf
  If Not EjecutarProceso("/usr/bin/apt-get","--simulate install --no-install-recommends build-essential libgtk-3-dev",Hogar,@resultado,90)
    Fallar("No se pudo obtener un plan de APT. Revisa el Gestor de actualizaciones de Mint. "+Right(resultado\Salida,1200)) : ProcedureReturn ""
  EndIf
  ProcedureReturn resultado\Salida
EndProcedure
Procedure PrepararCompilacion()
  Protected resultado.ResultadoProcesoPB
  ; Unica elevacion del gestor: APT del sistema con argumentos fijos y entorno vaciado.
  Registrar("Preparando las herramientas de desarrollo de PureBasic mediante APT. El sistema solicitará autorización.")
  If Not EjecutarProceso("/usr/bin/pkexec","/usr/bin/env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin LANG=C DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install --yes --no-install-recommends build-essential libgtk-3-dev",Hogar,@resultado,0)
    Registrar(resultado\Salida) : ProcedureReturn Fallar("APT no terminó correctamente o se canceló la autorización. No se ha cambiado la versión activa de PureBasic. "+Right(resultado\Salida,1000))
  EndIf
  Registrar(resultado\Salida) : Registrar("Herramientas de desarrollo preparadas. Ya puedes repetir la comprobación de PureBasic.") : ProcedureReturn #True
EndProcedure
Procedure ActualizarRegistro(id.s)
  Protected dato.VersionPB, temporal.s=Estado+"/revision-"+IdNuevo()+".manifest", copia.s, bien
  Protected NewList rutas.s()
  If Not LeerVersion(id,@dato) Or (dato\Estado<>"disponible" And dato\Estado<>"retirada") : ProcedureReturn Fallar("Selecciona una versión disponible o retirada.") : EndIf
  If VersionEnUso(dato\Ruta) : ProcedureReturn Fallar("Cierra el IDE y sus compiladores antes de revisar el contenido.") : EndIf
  If Not EstructuraValida(dato\Ruta) Or FileFingerprint(dato\Manifiesto,#PB_Cipher_SHA2,256)<>dato\Huella : ProcedureReturn Fallar("La estructura o el registro anterior no son válidos. Se conservan para revisión.") : EndIf
  If Not CrearManifiesto(dato\Ruta,temporal) : ProcedureReturn #False : EndIf
  copia=Estado+"/copias/manifiesto-"+id+"-"+IdNuevo()+".txt"
  If Not CopyFile(dato\Manifiesto,copia) : DeleteFile(temporal) : ProcedureReturn Fallar("No se pudo conservar el registro anterior.") : EndIf
  AddElement(rutas()) : rutas()=dato\Manifiesto : AddElement(rutas()) : rutas()=Estado+"/versiones/"+id+".json"
  If Not IniciarTransaccion(rutas()) : DeleteFile(temporal) : ProcedureReturn #False : EndIf
  bien=Guardar(dato\Manifiesto,LeerTexto(temporal))
  If bien
    dato\Huella=FileFingerprint(dato\Manifiesto,#PB_Cipher_SHA2,256) : dato\Comprobada=0
    bien=GuardarVersion(@dato)
  EndIf
  If bien : bien=ConfirmarTransaccion() : EndIf
  DeleteFile(temporal)
  If Not bien : RecuperarTransaccion() : ProcedureReturn Fallar("No se pudo actualizar el registro. Se intentó recuperar el anterior.") : EndIf
  Registrar("Registro de contenido actualizado tras revisión expresa. No se borró ningún archivo de la versión. Copia del registro anterior: "+copia)
  ProcedureReturn #True
EndProcedure
