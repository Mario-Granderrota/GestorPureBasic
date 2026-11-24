; Gestor PureBasic 2.4 para Linux x86-64. Sin motor de scripts.
EnableExplicit
CompilerIf #PB_Compiler_OS <> #PB_OS_Linux Or #PB_Compiler_Processor <> #PB_Processor_x64
  CompilerError "Se requiere Linux x86-64."
CompilerEndIf
CompilerIf Not Defined(MODO_PRUEBAS, #PB_Constant)
  #MODO_PRUEBAS = 0
CompilerEndIf
UseSHA2Fingerprint()
ImportC ""
  BloquearNativo.l(archivo.l, operacion.l) As "flock"
  EstadoNativo.l(ruta.p-utf8, *estado) As "lstat"
  RenombrarNativo.l(origen.p-utf8, destino.p-utf8) As "rename"
  RenombrarSinReemplazo.l(fdOrigen.l,origen.p-utf8,fdDestino.l,destino.p-utf8,opcion.l) As "renameat2"
  SincronizarNativo.l(archivo.l) As "fsync"
  LeerNativo.i(archivo.l, *buffer, cantidad.i) As "read"
  EscribirNativo.i(archivo.l, *buffer, cantidad.i) As "write"
  CerrarNativo.l(archivo.l) As "close"
EndImport
ImportC "-lz"
  GzipAbrir.i(ruta.p-utf8, modo.p-utf8) As "gzopen"
  GzipLeer.l(*archivo, *buffer, cantidad.l) As "gzread"
  GzipCerrar.l(*archivo) As "gzclose"
EndImport
#VERSION_GESTOR = "0"
#MARCA_GESTOR = "GESTOR_PB_NATIVO_2"
#MAXIMO_TOTAL = 4294967296
Structure VersionPB
  Id.s
  Ruta.s
  Identidad.s
  Numero.s
  Edicion.s
  Motor.s
  Tipo.s
  Estado.s
  Perfil.s
  Huella.s
  Manifiesto.s
  Origen.s
  Fecha.s
  Limitacion.s
  Comprobada.i
  Diagnostico.s
  Validacion.s
  NivelC.i
  NivelASM.i
  RutaRetirada.s ; ubicacion exacta anterior al traslado
  Correccion.s ; adaptacion local explicita, vacia para versiones anteriores
EndStructure
Global Hogar.s, Estado.s, Almacen.s, Datos.s, ErrorActual.s
Global EjecutableGestor.s, Cancelar.i, Mutex = CreateMutex()
Global NewList Mensajes.s(), NewList Versiones.VersionPB()
Global FalloEscritura.s, PersistenciaIncierta.i
Global SinGUI.i = #MODO_PRUEBAS, PermitirGratuita.i = #MODO_PRUEBAS
Procedure Registrar(texto.s)
  LockMutex(Mutex) : AddElement(Mensajes()) : Mensajes() = texto : UnlockMutex(Mutex)
EndProcedure
Procedure Fallar(texto.s)
  ErrorActual = texto : Registrar("ERROR: " + texto) : ProcedureReturn #False
EndProcedure
Procedure CambiarCancelacion(valor.i)
  LockMutex(Mutex) : Cancelar = valor : UnlockMutex(Mutex)
EndProcedure
Procedure Cancelacion()
  Protected valor
  LockMutex(Mutex) : valor = Cancelar : UnlockMutex(Mutex) : ProcedureReturn valor
EndProcedure
XIncludeFile "texto_seguro.pbi"
XIncludeFile "rutas.pbi"
XIncludeFile "procesos.pbi"
XIncludeFile "repositorio.pbi"
