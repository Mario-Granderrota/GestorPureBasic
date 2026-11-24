XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i, Fallos.i, RespuestaSimulada.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
; Puerto simulado exclusivamente en pruebas unitarias: nunca autoriza una instalacion.
Procedure EjecutorSimulado(programa.s, argumentos.s, carpeta.s,*resultado.ResultadoProcesoPB,segundos.i)
  *resultado\Codigo=0 : *resultado\Salida=""
  If argumentos<>""
    If RespuestaSimulada=0 : *resultado\Codigo=1 : *resultado\Salida="undefined reference to __wrap_memcpy" : ProcedureReturn 0 : EndIf
    If Not CopyFile(ProgramFilename(),carpeta+"/programa") : ProcedureReturn 0 : EndIf
    SetFileAttributes(carpeta+"/programa",493)
  ElseIf RespuestaSimulada=1
    *resultado\Salida="TESTIGO"+#LF$
  ElseIf RespuestaSimulada=2
    *resultado\Salida="NO_TESTIGO"+#LF$
  Else
    *resultado\Salida="TESTIGO"+#LF$ : *resultado\Codigo=4 : ProcedureReturn 0
  EndIf
  ProcedureReturn 1
EndProcedure
If Not Inicializar(ProgramParameter(0)) : PrintN(ErrorActual) : End 2 : EndIf
Define resultado.Politica::ResultadoMotor, a.ResultadoProcesoPB,b.ResultadoProcesoPB, dato.VersionPB, movimiento.MovimientoPB, carpeta.s, destino.s, otro.s, id.s, original.s, inicio.i
Comprobar(Bool(Politica::Comparar("6.9","","6.10","")=-1),"compara componentes numericos, no cadenas")
Comprobar(Bool(Politica::Comparar("6.41","PureBasic 6.41 alpha 9","6.41","PureBasic 6.41 beta 1")=-1),"alpha anterior a beta")
Comprobar(Bool(Politica::Comparar("6.41","PureBasic 6.41 RC 2","6.41","PureBasic 6.41")=-1),"RC anterior a estable")
Comprobar(Bool(Politica::Comparar("6.41","PureBasic 6.41 LTS","6.41.0","PureBasic 6.41.0")=0),"LTS y componente cero no falsean precedencia")
Comprobar(Bool(Politica::Comparar("6.41","PureBasic 6.41 beta 12","6.41","PureBasic 6.41 beta 2")=1),"ordena numeros de beta")
Comprobar(Bool(Politica::ElegirMotor(2,2,1,1,"AUTO",@resultado)=2 And resultado\Motor="C" And Not resultado\Limitado),"ambos correctos")
Comprobar(Bool(Politica::ElegirMotor(1,2,1,1,"AUTO",@resultado)=2 And resultado\Motor="ASM" And resultado\Limitado),"prefiere ASM pero detecta limitacion en C")
Comprobar(Bool(Politica::ElegirMotor(2,0,1,1,"AUTO",@resultado)=2 And resultado\Limitado),"backend presente danado bloquea sustitucion")
Comprobar(Bool(Politica::ElegirMotor(0,2,0,1,"AUTO",@resultado)=2 And Not resultado\Limitado),"backend no incluido no causa falso fallo")
Comprobar(Bool(Politica::ElegirMotor(0,0,1,1,"AUTO",@resultado)=0 And resultado\Motor=""),"ningun backend utilizable")
Comprobar(Bool(Politica::PuedeSustituir(1,"","completa")),"politica acepta verificacion completa")
Comprobar(Bool(Not Politica::PuedeSustituir(0,"","completa")),"rechaza validacion no acreditada")
Comprobar(Bool(Not Politica::PuedeSustituir(1,"fallo","completa")),"rechaza limitacion aunque figure completa")
Comprobar(Bool(Not Politica::PuedeSustituir(1,"","consola")),"consola sola no autoriza produccion")
Comprobar(Bool(Politica::PuedeSustituir(1,"","consola",1) And Not Politica::PuedeSustituir(1,"","",1)),"modo de prueba no acepta validacion vacia")
Comprobar(Bool(Not Politica::LicenciaCompatible("completa","gratuita") And Politica::LicenciaCompatible("gratuita","completa")),"proteccion de licencia")
Comprobar(EjecutarProceso("/usr/bin/printf",Citar("UNO"),Hogar,@a,5),"ejecutor real salida uno")
Comprobar(EjecutarProceso("/usr/bin/printf",Citar("DOS"),Hogar,@b,5),"ejecutor real salida dos")
Comprobar(Bool(a\Salida="UNO" And b\Salida="DOS" And a\Codigo=0 And b\Codigo=0),"resultados no se sobreescriben")
Comprobar(Bool(Not EjecutarProceso("/usr/bin/false","",Hogar,@b,5) And b\Codigo<>0 And a\Salida="UNO"),"codigo de salida aislado")
inicio=ElapsedMilliseconds()
Comprobar(Bool(Not EjecutarProceso("/usr/bin/sleep","5",Hogar,@b,1) And b\Codigo=-1 And ElapsedMilliseconds()-inicio<4000),"tiempo limite de proceso")
ErrorActual="" : carpeta=Hogar+"/casos" : CrearCarpetas(carpeta)
RespuestaSimulada=0
Comprobar(Bool(Not ProbarCasoCon("simulado",carpeta,"fallo-compilacion","fuente","","TESTIGO",@dato,@EjecutorSimulado()) And FindString(dato\Diagnostico,"__wrap_memcpy")),"puerto simulado diagnostica fallo de enlace")
RespuestaSimulada=1
Comprobar(ProbarCasoCon("simulado",carpeta,"correcto","fuente","","TESTIGO",@dato,@EjecutorSimulado()),"testigo exacto con salida cero")
RespuestaSimulada=2
Comprobar(Bool(Not ProbarCasoCon("simulado",carpeta,"marca-incorrecta","fuente","","TESTIGO",@dato,@EjecutorSimulado())),"rechaza testigo que solo contiene subcadena")
RespuestaSimulada=3
Comprobar(Bool(Not ProbarCasoCon("simulado",carpeta,"salida-incorrecta","fuente","","TESTIGO",@dato,@EjecutorSimulado())),"rechaza testigo correcto con salida no cero")
Comprobar(Bool(Not ProbarCasoCon("simulado",carpeta,"correcto","fuente","","TESTIGO",@dato,@EjecutorSimulado())),"no reutiliza area de prueba anterior")
; Simula una publicacion sin registro despues de rename.
id=IdNuevo() : original=Almacen+"/.trabajo-"+id+"/contenido" : destino=Almacen+"/versiones/"+id
CrearCarpetas(original) : Guardar(original+"/datos.txt","contenido")
movimiento\Id=id : movimiento\Origen=original : movimiento\Destino=destino : movimiento\Accion="publicar"
Guardar(Estado+"/versiones/"+id+".manifest","pendiente")
Comprobar(GuardarMovimiento(@movimiento),"diario previo a publicacion")
Comprobar(Bool(RenombrarSinReemplazo(-100,original,-100,destino,1)=0),"simula interrupcion despues del traslado")
Comprobar(RecuperarMovimiento(),"recupera publicacion interrumpida")
Comprobar(Bool(LeerTexto(original+"/datos.txt")="contenido" And FileSize(destino)=-1 And FileSize(Estado+"/versiones/"+id+".manifest")=-1 And FileSize(Estado+"/movimiento.json")=-1),"recuperacion no pierde contenido ni crea registro fantasma")
ClearStructure(@dato,VersionPB) : dato\Id=IdNuevo() : dato\Ruta=original : dato\Estado="disponible"
destino=Almacen+"/versiones/"+dato\Id
FalloEscritura=Estado+"/versiones/"+dato\Id+".json"
Comprobar(Bool(Not PublicarVersion(@dato,destino)),"simula error al escribir registro de publicacion")
FalloEscritura=""
Comprobar(Bool(LeerTexto(original+"/datos.txt")="contenido" And FileSize(destino)=-1 And FileSize(Estado+"/movimiento.json")=-1 And FileSize(dato\Manifiesto)=-1),"revierte publicacion fallida y retira manifiesto")
Comprobar(PublicarVersion(@dato,destino),"publicacion central correcta")
Comprobar(Bool(LeerVersion(dato\Id,@dato) And dato\Ruta=destino And VerificarContenido(@dato)),"publicacion deja registro y manifiesto coherentes")
Comprobar(Bool(FileSize(Estado+"/movimiento.json")=-1),"commit elimina diario")
; Un nombre ocupado no se reemplaza incluso si el directorio esta vacio.
otro=Almacen+"/.trabajo-"+IdNuevo()+"/contenido" : CrearCarpetas(otro)
Comprobar(Bool(RenombrarSinReemplazo(-100,otro,-100,destino,1)<>0 And FileSize(otro)=-2 And LeerTexto(destino+"/datos.txt")="contenido"),"rename sin reemplazo conserva destino existente")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
