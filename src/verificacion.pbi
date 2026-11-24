Procedure.s DiagnosticarSalida(salida.s)
  Protected posicion, fin, requerida.s, instalada.s, resultado.ResultadoProcesoPB
  posicion=FindString(salida,"GLIBC_")
  If posicion And FindString(salida,"not found")
    fin=posicion+6
    While fin<=Len(salida) And FindString("0123456789.",Mid(salida,fin,1)) : fin+1 : Wend
    requerida=Mid(salida,posicion+6,fin-posicion-6)
    If EjecutarProceso("/usr/bin/getconf","GNU_LIBC_VERSION","/tmp",@resultado,5) : instalada=Trim(resultado\Salida) : EndIf
    ProcedureReturn "El paquete necesita GLIBC "+requerida+", no disponible en este equipo ("+instalada+"). Descarga la compilación oficial para una distribución compatible. No actualices GLIBC manualmente."
  EndIf
  If FindString(salida,"__wrap_memcpy") : ProcedureReturn "Error de enlazado __wrap_memcpy: posible orden incorrecto de bibliotecas estáticas de PureBasic. No se han modificado sus archivos." : EndIf
  If FindString(salida,"Error: Assembler") : ProcedureReturn "Fallo del ensamblador FASM; comprueba su compatibilidad y ejecución." : EndIf
  If FindString(salida,"cannot find -l") Or FindString(salida,"Package ") : ProcedureReturn "Posible dependencia de desarrollo ausente. Consulta el registro técnico." : EndIf
  If FindString(salida,"undefined reference") Or FindString(salida,"ld returned") : ProcedureReturn "Error de enlazado. Consulta el registro técnico." : EndIf
  ProcedureReturn "Fallo de compilación o ejecución. Consulta el registro técnico."
EndProcedure
Procedure Identificar(*version.VersionPB)
  Protected anterior.s=GetEnvironmentVariable("PUREBASIC_HOME"), resultado.ResultadoProcesoPB, c.VersionPB, asm.VersionPB, bienC, bienASM, salidaC.s, salidaASM.s
  If Not EstructuraValida(*version\Ruta) : ProcedureReturn #False : EndIf
  SetEnvironmentVariable("PUREBASIC_HOME",*version\Ruta)
  If ELFValido(*version\Ruta+"/compilers/pbcompiler")
    EjecutarProceso(*version\Ruta+"/compilers/pbcompiler","--version",*version\Ruta,@resultado,10)
    salidaASM=Trim(resultado\Salida)
    bienASM=Bool((resultado\Codigo=0 Or resultado\Codigo=1) And PonerIdentidad(@asm,salidaASM))
  EndIf
  If Not Cancelacion() And ELFValido(*version\Ruta+"/compilers/pbcompilerc")
    EjecutarProceso(*version\Ruta+"/compilers/pbcompilerc","--version",*version\Ruta,@resultado,10)
    salidaC=Trim(resultado\Salida)
    bienC=Bool((resultado\Codigo=0 Or resultado\Codigo=1) And PonerIdentidad(@c,salidaC))
  EndIf
  SetEnvironmentVariable("PUREBASIC_HOME",anterior)
  If Cancelacion() : ProcedureReturn Fallar("Identificación cancelada.") : EndIf
  If bienC And bienASM
    If Politica::Comparar(c\Numero,c\Identidad,asm\Numero,asm\Identidad)<>0 Or (c\Edicion<>"desconocida" And c\Edicion<>asm\Edicion)
      ProcedureReturn Fallar("Los compiladores C y ASM no pertenecen a la misma versión o edición. No se instalará el paquete.")
    EndIf
  EndIf
  If bienASM
    PonerIdentidad(*version,salidaASM)
  ElseIf bienC
    PonerIdentidad(*version,salidaC)
    ; Usar el banner estatico ASM si su version coincide; no eleva una licencia desconocida a completa.
    If PonerIdentidad(@asm,IdentidadEstaticaMotor(*version\Ruta,"pbcompiler")) And Politica::Comparar(c\Numero,c\Identidad,asm\Numero,asm\Identidad)=0
      *version\Edicion=asm\Edicion : *version\Identidad=asm\Identidad
    EndIf
  Else
    Registrar("Identidad ASM: "+salidaASM+#LF$+"Identidad C: "+salidaC)
    ProcedureReturn Fallar(DiagnosticarSalida(salidaASM+#LF$+salidaC)+#LF$+Right(salidaASM+#LF$+salidaC,1000))
  EndIf
  Registrar("Identificada: "+*version\Identidad) : ProcedureReturn #True
EndProcedure
Procedure.s PreferenciasIniciales()
  ProcedureReturn "[Global]"+#LF$+"RunOnce = 0"+#LF$+"AutoReload = 0"+#LF$+"CurrentLanguage = Spanish"+#LF$
EndProcedure
Procedure ConfigurarMotorInicial(*version.VersionPB)
  Protected ruta.s=RutaPerfil(*version), texto.s, resultado.ResultadoProcesoPB, banner.s, anterior.s
  If ruta="" Or *version\Motor<>"C" Or *version\NivelC<>Politica::#Correcto : ProcedureReturn #True : EndIf
  ruta+"/purebasic.prefs" : texto=LeerTexto(ruta)
  If texto<>PreferenciasIniciales() : ProcedureReturn #True : EndIf
  anterior=GetEnvironmentVariable("PUREBASIC_HOME") : SetEnvironmentVariable("PUREBASIC_HOME",*version\Ruta)
  EjecutarProceso(*version\Ruta+"/compilers/pbcompilerc","--version",*version\Ruta,@resultado,10)
  SetEnvironmentVariable("PUREBASIC_HOME",anterior)
  banner=Trim(StringField(resultado\Salida,1,#LF$))
  If (resultado\Codigo<>0 And resultado\Codigo<>1) Or Left(banner,10)<>"PureBasic " Or Controles(banner) : ProcedureReturn Fallar("No se puede identificar el backend C para las preferencias iniciales.") : EndIf
  ; El protocolo del IDE usa el banner sin el sufijo de copyright.
  If FindString(banner," - (c)") : banner=Left(banner,FindString(banner," - (c)")-1) : EndIf
  ProcedureReturn Guardar(ruta,texto+#LF$+"[CompilerDefaults]"+#LF$+"CustomCompiler = 1"+#LF$+"CompilerVersion = "+banner+#LF$)
EndProcedure
Procedure PrepararPerfil(*version.VersionPB)
  Protected ruta.s=RutaPerfil(*version)
  If ruta="" : ProcedureReturn #True : EndIf
  If Not CrearCarpetas(ruta) : ProcedureReturn Fallar("No se puede crear el perfil separado del IDE.") : EndIf
  If FileSize(ruta+"/purebasic.prefs")=-1
    If Not Guardar(ruta+"/purebasic.prefs",PreferenciasIniciales()) : ProcedureReturn Fallar("No se puede preparar la configuración.") : EndIf
  EndIf
  ProcedureReturn #True
EndProcedure
 ; Cada caso tiene un directorio exclusivo y no reutiliza ejecutables anteriores.
Procedure ProbarCasoCon(compilador.s, carpeta.s, nombre.s, fuente.s, opciones.s, esperado.s, *dato.VersionPB, ejecutar.EjecutorPB)
  Protected directorio.s=carpeta+"/"+nombre, programa.s=directorio+"/programa", detalle.s, ejecucion, marca, resultado.ResultadoProcesoPB
  If Cancelacion() : ProcedureReturn #False : EndIf
  If Not CreateDirectory(directorio) Or Not Guardar(directorio+"/prueba.pb",fuente)
    Registrar("No se pudo preparar el caso "+nombre) : ProcedureReturn #False
  EndIf
  If Not ejecutar(compilador,"prueba.pb "+opciones+" --output "+Citar(programa),directorio,@resultado,90) Or Not ELFValido(programa)
    detalle=resultado\Salida : Registrar(nombre+" [compilación]: "+detalle)
    *dato\Diagnostico+GetFilePart(compilador)+" / "+nombre+": "+DiagnosticarSalida(detalle)+#LF$
    ProcedureReturn #False
  EndIf
  ejecucion=ejecutar(programa,"",directorio,@resultado,15)
  If nombre="grafica"
    marca=Bool(RemoveString(RemoveString(LeerTexto(directorio+"/resultado.txt"),#CR$),#LF$)=esperado)
  Else
    marca=Bool(FindString(#LF$+ReplaceString(resultado\Salida,#CR$,"")+#LF$,#LF$+esperado+#LF$)>0)
  EndIf
  If Not ejecucion Or Not marca
    Registrar(nombre+" [ejecución, código "+Str(resultado\Codigo)+"]: "+resultado\Salida)
    *dato\Diagnostico+GetFilePart(compilador)+" / "+nombre+": el ejecutable no produjo el resultado esperado."+#LF$
    ProcedureReturn #False
  EndIf
  Registrar(GetFilePart(compilador)+" / "+nombre+": OK. Salida: "+resultado\Salida)
  ProcedureReturn #True
EndProcedure

Procedure ProbarCaso(compilador.s, carpeta.s, nombre.s, fuente.s, opciones.s, esperado.s, *dato.VersionPB)
  ProcedureReturn ProbarCasoCon(compilador,carpeta,nombre,fuente,opciones,esperado,*dato,@EjecutarProceso())
EndProcedure

; 0: no utilizable; 1: utilizable con limitaciones; 2: todas las pruebas superadas.
Procedure ProbarMotor(*version.VersionPB, motor.s, carpeta.s, pruebaGrafica.i=1)
  Protected compilador.s=*version\Ruta+"/compilers/"+motor, minimo.s, memoria.s, grafica.s, fuenteHilos.s, normal, depurador, avanzada, hilos, interfaz=1, invalido, directorio.s, resultado.ResultadoProcesoPB, sintaxis=1, admiteCheck
  If Not ELFValido(compilador)
    *version\Diagnostico+motor+": backend no disponible."+#LF$ : ProcedureReturn 0
  EndIf
  If Not CreateDirectory(carpeta) : ProcedureReturn 0 : EndIf
  minimo="OpenConsole()"+#LF$+"PrintN("+Chr(34)+"GESTOR_MINIMO_OK"+Chr(34)+")"+#LF$
  memoria="EnableExplicit"+#LF$+"Define *memoria=AllocateMemory(16), texto.s="+Chr(34)+"GESTOR_MEMORIA_OK"+Chr(34)+#LF$+"If Not *memoria : End 2 : EndIf"+#LF$+"PokeI(*memoria,42)"+#LF$+"If PeekI(*memoria)<>42 : End 3 : EndIf"+#LF$+"FreeMemory(*memoria)"+#LF$+"OpenConsole() : PrintN(texto)"+#LF$
  EjecutarProceso(compilador,"--help",carpeta,@resultado,10)
  admiteCheck=Bool(FindString(resultado\Salida,"--check")>0)
  If admiteCheck
    directorio=carpeta+"/sintaxis"
    sintaxis=0
    If CreateDirectory(directorio) And Guardar(directorio+"/prueba.pb",minimo)
      sintaxis=EjecutarProceso(compilador,"prueba.pb --check",directorio,@resultado,30)
      Registrar(motor+" / sintaxis sin enlazar: "+Str(sintaxis)+" "+resultado\Salida)
    EndIf
    If Not sintaxis : *version\Diagnostico+motor+": fallo en análisis sintáctico de fuente válida."+#LF$ : EndIf
  Else
    Registrar(motor+" / sintaxis independiente: opción --check no acreditada.")
  EndIf
  normal=ProbarCaso(compilador,carpeta,"normal",minimo,"","GESTOR_MINIMO_OK",*version)
  If Not normal And FindString(*version\Diagnostico,motor+" / normal: Error de enlazado __wrap_memcpy") And Not Cancelacion()
    If ProbarCaso(compilador,carpeta,"diagnostico-memcpy","ImportC "+Chr(34)+"-Wl,-u,__wrap_memcpy"+Chr(34)+#LF$+"EndImport"+#LF$+minimo,"","GESTOR_MINIMO_OK",*version)
      *version\Diagnostico+motor+": solución experimental -Wl,-u,__wrap_memcpy verificada; no se aplica a los archivos oficiales."+#LF$
    EndIf
  EndIf
  depurador=ProbarCaso(compilador,carpeta,"depurador",minimo,"--debugger","GESTOR_MINIMO_OK",*version)
  avanzada=ProbarCaso(compilador,carpeta,"memoria",memoria,"","GESTOR_MEMORIA_OK",*version)
  fuenteHilos="EnableExplicit"+#LF$+"Procedure Trabajo(*dato.Integer)"+#LF$+"  *dato\i=42"+#LF$+"EndProcedure"+#LF$+"Define dato.Integer, hilo=CreateThread(@Trabajo(),@dato)"+#LF$+"If Not hilo : End 2 : EndIf"+#LF$+"WaitThread(hilo)"+#LF$+"If dato\i<>42 : End 3 : EndIf"+#LF$+"OpenConsole() : PrintN("+Chr(34)+"GESTOR_HILO_OK"+Chr(34)+")"+#LF$
  hilos=ProbarCaso(compilador,carpeta,"multihilo",fuenteHilos,"--thread","GESTOR_HILO_OK",*version)
  If Not SinGUI And pruebaGrafica
    grafica="If Not OpenWindow(0,0,0,220,80,"+Chr(34)+"Comprobacion"+Chr(34)+",#PB_Window_Invisible) : End 9 : EndIf"+#LF$+"TextGadget(0,10,10,180,30,"+Chr(34)+"GUI"+Chr(34)+")"+#LF$+"WindowEvent() : CloseWindow(0)"+#LF$+"Define archivo=CreateFile(#PB_Any,"+Chr(34)+"resultado.txt"+Chr(34)+")"+#LF$+"If Not archivo : End 10 : EndIf"+#LF$+"WriteStringN(archivo,"+Chr(34)+"GESTOR_GUI_OK"+Chr(34)+") : CloseFile(archivo)"+#LF$
    interfaz=ProbarCaso(compilador,carpeta,"grafica",grafica,"","GESTOR_GUI_OK",*version)
  EndIf
  directorio=carpeta+"/invalido"
  If Not Cancelacion() And CreateDirectory(directorio) And Guardar(directorio+"/invalido.pb","ESTO_NO_ES_PUREBASIC_2()"+#LF$)
    EjecutarProceso(compilador,"invalido.pb --output "+Citar(directorio+"/programa"),directorio,@resultado,30)
    invalido=Bool(resultado\Codigo>0 And FileSize(directorio+"/programa")=-1 And FindString(resultado\Salida,"ESTO_NO_ES_PUREBASIC_2",1,#PB_String_NoCase))
    Registrar(motor+" / rechazo de fuente incorrecta: "+Str(invalido)+" "+resultado\Salida)
  EndIf
  *version\Diagnostico+motor+": normal="+Str(normal)+", depurador="+Str(depurador)+", memoria="+Str(avanzada)+", hilos="+Str(hilos)+", gráfica="+Str(interfaz)+", rechazo="+Str(invalido)+#LF$
  If Not invalido : *version\Diagnostico+motor+": no se verificó el rechazo de un fuente incorrecto."+#LF$ : EndIf
  If Cancelacion() Or Not invalido Or Not (normal Or avanzada Or hilos Or depurador) : ProcedureReturn 0 : EndIf
  If normal And depurador And avanzada And hilos And interfaz And sintaxis : ProcedureReturn 2 : EndIf
  ProcedureReturn 1
EndProcedure
Procedure.s EstadoMotor(nivel.i, incluido.i)
  If Not incluido : ProcedureReturn "no incluido" : EndIf
  Select nivel
    Case 2 : ProcedureReturn "correcto"
    Case 1 : ProcedureReturn "funciona con limitaciones"
    Default : ProcedureReturn "no utilizable"
  EndSelect
EndProcedure
Procedure VerificarVersion(*version.VersionPB, pruebaGrafica.i=1)
  Protected anterior.s=GetEnvironmentVariable("PUREBASIC_HOME"), rutaEntorno.s=GetEnvironmentVariable("PATH"), carpeta.s=Estado+"/prueba-"+IdNuevo(), causa.s, c, asm, pedido.s=*version\Motor, ide=1, elegido, resultado.ResultadoProcesoPB, seleccion.Politica::ResultadoMotor, incluyeC, incluyeASM
  ErrorActual="" : *version\Limitacion="" : *version\Diagnostico="" : *version\Comprobada=0 : *version\Validacion="" : *version\NivelC=0 : *version\NivelASM=0
  If Not Identificar(*version) Or Not PrepararPerfil(*version) : ProcedureReturn #False : EndIf
  If Not CrearCarpetas(carpeta) : ProcedureReturn Fallar("No se puede crear el área de comprobación.") : EndIf
  If Not EntornoCompatible(*version,1)
    DeleteDirectory(carpeta,"",#PB_FileSystem_Recursive) : ProcedureReturn #False
  EndIf
  If *version\Correccion<>"" : Registrar("Validación con adaptador local "+*version\Correccion) : EndIf
  SetFileAttributes(carpeta,448) : SetEnvironmentVariable("PUREBASIC_HOME",*version\Ruta)
  If Not SinGUI
    EjecutarProceso(*version\Ruta+"/compilers/purebasic","--help",carpeta,@resultado,15)
    If (resultado\Codigo<>0 And resultado\Codigo<>1) Or Not FindString(resultado\Salida,"--preferences") Or Not FindString(resultado\Salida,"--history")
      causa="El IDE no arranca o no admite la configuración separada. "+DiagnosticarSalida(resultado\Salida) : ide=0
    EndIf
  EndIf
  If ide And Not Cancelacion()
    If pedido="AUTO" Or pedido="C" : c=ProbarMotor(*version,"pbcompilerc",carpeta+"/C",pruebaGrafica) : EndIf
    If Not Cancelacion() And (pedido="AUTO" Or pedido="ASM") : asm=ProbarMotor(*version,"pbcompiler",carpeta+"/ASM",pruebaGrafica) : EndIf
    *version\NivelC=c : *version\NivelASM=asm
    Registrar("Resultados de backend: C="+Str(c)+" ASM="+Str(asm)+" (0 no utilizable, 1 limitado, 2 correcto)")
    ; Si existe un backend dañado, no se considera ausente.
    incluyeC=Bool(TipoArchivo(*version\Ruta+"/compilers/pbcompilerc")<>0)
    incluyeASM=Bool(TipoArchivo(*version\Ruta+"/compilers/pbcompiler")<>0)
    elegido=Politica::ElegirMotor(c,asm,incluyeC,incluyeASM,pedido,@seleccion)
    If elegido : *version\Motor=seleccion\Motor : EndIf
  EndIf
  SetEnvironmentVariable("PUREBASIC_HOME",anterior) : SetEnvironmentVariable("PATH",rutaEntorno) : DeleteDirectory(carpeta,"",#PB_FileSystem_Recursive)
  If Cancelacion() : ProcedureReturn Fallar("Comprobación cancelada.") : EndIf
  If Not elegido : ProcedureReturn Fallar(causa+#LF$+"No se ha validado ningún backend utilizable. La instalación anterior se conserva."+#LF$+Left(*version\Diagnostico,950)) : EndIf
  *version\Comprobada=1
  If seleccion\Limitado
    *version\Validacion="limitada"
  ElseIf elegido=2 And (SinGUI Or Not pruebaGrafica)
    *version\Validacion="consola"
  ElseIf elegido=2
    *version\Validacion="completa"
  Else
    *version\Validacion="limitada"
  EndIf
  If seleccion\Limitado
    *version\Limitacion="No todas las pruebas han sido superadas. Backend preferido: "+*version\Motor+". La sustitución está bloqueada."+#LF$+"C: "+EstadoMotor(c,incluyeC)+" / ASM: "+EstadoMotor(asm,incluyeASM)+"."
    If FindString(*version\Diagnostico,"__wrap_memcpy") : *version\Limitacion+#LF$+"Se detectó el fallo de enlazado __wrap_memcpy." : EndIf
    If *version\Correccion<>"" : *version\Limitacion+#LF$+"La corrección local está activa, pero quedan pruebas pendientes o fallidas." : ElseIf PuedeOfrecerCorreccion(*version) : *version\Limitacion+#LF$+"Existe una corrección local comprobable que no modifica el paquete." : EndIf
    If FindString(*version\Diagnostico,"FASM") : *version\Limitacion+#LF$+"El ensamblador FASM no superó alguna prueba." : EndIf
    *version\Limitacion+#LF$+"Registro: "+Estado+"/registro.log"
  EndIf
  Registrar("Validación: "+*version\Validacion+" / "+*version\Motor+#LF$+*version\Diagnostico)
  ProcedureReturn #True
EndProcedure
