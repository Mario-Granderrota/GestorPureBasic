XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i,Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : PrintN(ErrorActual) : End 2 : EndIf
Define paquete.PaquetePB, nueva.VersionPB, origen.s=ProgramParameter(1), id.s, ruta.s, entorno.s=GetEnvironmentVariable("PATH"), hogarPB.s=GetEnvironmentVariable("PUREBASIC_HOME")
Comprobar(PrepararPaquete(origen,@paquete),"prepara paquete oficial")
Comprobar(Bool(ConfirmarPaquete(@paquete,"",0,0,1)=Politica::#SustitucionBloqueada),"ofrece correccion sin publicar")
Comprobar(PuedeOfrecerCorreccion(@paquete\Dato),"diagnostico experimental positivo")
Comprobar(Bool(paquete\Dato\Correccion="" And Activa()=""),"sin autorizacion no altera entorno ni publica")
Comprobar(Bool(GetEnvironmentVariable("PATH")=entorno And GetEnvironmentVariable("PUREBASIC_HOME")=hogarPB),"restaura entorno tras validacion original")
paquete\Dato\Correccion=#CORRECCION_MEMCPY : paquete\Dato\Comprobada=0 : paquete\Dato\Motor="AUTO"
Comprobar(VerificarVersion(@paquete\Dato,1),"valida con correccion explicita")
PrintN("DIAGNOSTICO REPARADO: "+paquete\Dato\Diagnostico)
Comprobar(Bool(FindString(paquete\Dato\Diagnostico,"pbcompilerc: normal=1, depurador=1, memoria=1, hilos=1, gráfica=1, rechazo=1")>0),"C supera toda la bateria")
Comprobar(Bool(GetEnvironmentVariable("PATH")=entorno And GetEnvironmentVariable("PUREBASIC_HOME")=hogarPB),"restaura entorno tras correccion")
ruta=CarpetaAdaptador(@paquete\Dato)+"/gcc"
Comprobar(Bool(LeerTexto(ruta)=TextoAdaptadorGCC()),"adaptador privado exacto")
Comprobar(Bool(Not PuedeOfrecerCorreccion(@paquete\Dato)),"no propone aplicar dos veces")
Comprobar(Bool(EntornoCompatible(@paquete\Dato) And Left(GetEnvironmentVariable("PATH"),Len(GetPathPart(ruta))-1)=RTrim(GetPathPart(ruta),"/")),"lanzador prepara PATH")
SetEnvironmentVariable("PATH",entorno)
Comprobar(Guardar(ruta,"#!/bin/sh"+#LF$+"exit 0"+#LF$,448),"simula adaptador modificado")
Comprobar(Bool(Not EntornoCompatible(@paquete\Dato) And GetEnvironmentVariable("PATH")=entorno),"rechaza adaptador manipulado")
Comprobar(Guardar(ruta,TextoAdaptadorGCC(),448),"restaura adaptador para pruebas")
Define estadoPublicacion=ConfirmarPaquete(@paquete,"",0)
If paquete\Dato\Limitacion<>""
  Comprobar(Bool(estadoPublicacion=Politica::#SustitucionBloqueada And Activa()=""),"corregir no autoriza una limitacion residual")
  estadoPublicacion=ConfirmarPaquete(@paquete,"",0,1)
EndIf
Comprobar(Bool(estadoPublicacion=Politica::#Instalada Or estadoPublicacion=Politica::#InstaladaLimitada),"publica y valida de nuevo en ruta definitiva")
id=LeerTexto(Estado+"/ultima.txt")
Comprobar(Bool(LeerVersion(id,@nueva) And nueva\Correccion=#CORRECCION_MEMCPY And VerificarContenido(@nueva)),"persiste correccion y manifiesto original intacto")
Comprobar(Bool(FileSize(CarpetaAdaptador(@nueva)+"/gcc")>0 And FileSize(nueva\Ruta+"/compilers/gcc")=-1),"no instala cambios en archivos oficiales")
Comprobar(Bool(FindString(nueva\Diagnostico,"pbcompilerc: normal=1, depurador=1, memoria=1, hilos=1, gráfica=1, rechazo=1")>0),"backend C correcto tras traslado")
Comprobar(Bool(nueva\Edicion="gratuita" And nueva\NivelC=2),"edicion gratuita y nivel C persisten correctamente")
Comprobar(Bool(FindString(LeerTexto(RutaPerfil(@nueva)+"/purebasic.prefs"),"[CompilerDefaults]"+#LF$+"CustomCompiler = 1"+#LF$+"CompilerVersion = PureBasic 6.41 - C Backend")>0),"perfil inicial elige backend C validado")
Define preferenciasGuardadas.s=LeerTexto(RutaPerfil(@nueva)+"/purebasic.prefs")
Guardar(RutaPerfil(@nueva)+"/purebasic.prefs","[Global]"+#LF$+"AutoReload = 1"+#LF$)
Comprobar(Bool(ConfigurarMotorInicial(@nueva) And LeerTexto(RutaPerfil(@nueva)+"/purebasic.prefs")="[Global]"+#LF$+"AutoReload = 1"+#LF$),"respeta preferencias ya modificadas")
Guardar(RutaPerfil(@nueva)+"/purebasic.prefs",preferenciasGuardadas)
If nueva\Limitacion<>""
  Comprobar(Bool(nueva\Validacion="limitada"),"registro no declara validacion completa si falla un backend")
  Comprobar(Bool(Not Politica::PuedeSustituir(nueva\Comprobada,nueva\Limitacion,nueva\Validacion,#MODO_PRUEBAS)),"fallo residual de ASM mantiene bloqueo")
EndIf
PrintN("ID="+id)
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
