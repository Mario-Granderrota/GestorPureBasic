XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i,Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : PrintN(ErrorActual) : End 2 : EndIf
Define dato.VersionPB, otro.VersionPB, resultado.Politica::ResultadoMotor, movimiento.MovimientoPB, ruta.s, id.s, otroId.s, anterior.s, destino.s, json, casos.s=ProgramParameter(1)
Comprobar(Bool(Politica::ElegirMotor(2,1,1,1,"ASM",@resultado)=1 And resultado\Motor="ASM" And resultado\Limitado),"respeta eleccion explicita ASM")
Comprobar(Bool(Politica::ElegirMotor(0,2,1,1,"C",@resultado)=0 And resultado\Motor=""),"no selecciona silenciosamente otro backend")
Comprobar(Bool(Politica::ElegirMotor(2,0,1,1,"C",@resultado)=2 And resultado\Limitado),"C correcto no acredita ASM sin comprobar")
Comprobar(Bool(Politica::ElegirMotor(2,2,1,1,"XYZ",@resultado)=0),"rechaza motor desconocido")
Comprobar(Bool(PonerIdentidad(@dato,"PureBasic 6.41 - C Backend (Linux - x64)") And dato\Edicion="desconocida"),"banner C sin Free no acredita licencia completa")
Comprobar(Bool(PonerIdentidad(@dato,"PureBasic 6.41 (Linux - x64) Free") And dato\Edicion="gratuita"),"banner ASM distingue edicion gratuita")
Comprobar(Bool(Not Politica::LicenciaCompatible("completa","desconocida") And Not Politica::LicenciaCompatible("desconocida","completa")),"edicion desconocida impide borrado")
Comprobar(Bool(Not PonerIdentidad(@dato,"PureBasic 6..41 (Linux - x64)") And Not PonerIdentidad(@dato,"PureBasic 6. (Linux - x64)")),"rechaza numero de version mal formado")
Comprobar(Bool(Not RutaTarValida("raiz//a") And Not RutaTarValida("raiz/./a") And RutaTarValida("raiz/área.txt")),"rechaza alias TAR y conserva Unicode")
ruta=Hogar+"/pax" : CrearCarpetas(ruta)
Comprobar(ExtraerTar(casos+"/unicode.tar",ruta),"extrae PAX con longitud UTF-8 y varias claves")
Comprobar(Bool(LeerTexto(ruta+"/raiz/"+LSet("",80,"á")+".txt")="contenido"),"nombre y contenido Unicode correctos")
ruta=Hogar+"/pax-mal" : CrearCarpetas(ruta)
Comprobar(Bool(Not ExtraerTar(casos+"/pax-mal.tar",ruta)),"rechaza PAX con longitud fuera de los bytes disponibles")
ruta=Hogar+"/alias" : CrearCarpetas(ruta)
Comprobar(Bool(Not ExtraerTar(casos+"/alias.tar",ruta)),"rechaza alias de ruta en archivo real")
; Manifiesto propio y solapamiento de registros.
ClearStructure(@dato,VersionPB) : id=IdNuevo() : dato\Id=id : dato\Ruta=Hogar+"/instalacion" : dato\Estado="disponible" : dato\Tipo="externa" : dato\Origen=dato\Ruta
CrearCarpetas(dato\Ruta+"/interior") : Guardar(dato\Ruta+"/datos.txt","dato")
dato\Manifiesto=Estado+"/versiones/"+id+".manifest" : CrearManifiesto(dato\Ruta,dato\Manifiesto) : dato\Huella=FileFingerprint(dato\Manifiesto,#PB_Cipher_SHA2,256)
Comprobar(Bool(GuardarVersion(@dato) And VerificarContenido(@dato)),"manifiesto propio canonico")
CopyStructure(@dato,@otro,VersionPB) : otro\Manifiesto=Hogar+"/ajeno.manifest" : CopyFile(dato\Manifiesto,otro\Manifiesto)
Comprobar(Bool(Not VerificarContenido(@otro)),"manifiesto identico fuera del repositorio no autoriza borrado")
Comprobar(Bool(Not RaizSinSolapamiento(dato\Ruta+"/interior") And Not RaizSinSolapamiento(dato\Ruta)),"bloquea raices anidadas y duplicadas")
Comprobar(RaizSinSolapamiento(dato\Ruta,id),"excluye solo el registro seleccionado")
otroId=IdNuevo() : Guardar(Estado+"/versiones/"+otroId+".json","INVALIDO")
Comprobar(Bool(Not RaizSinSolapamiento(dato\Ruta,id)),"catalogo ilegible bloquea operacion destructiva")
DeleteFile(Estado+"/versiones/"+otroId+".json")
; Diario de retirada incoherente: no se permite mover un directorio arbitrario.
movimiento\Id=id : movimiento\Origen=dato\Ruta : movimiento\Destino=Hogar+"/otro-destino" : movimiento\Accion="retirar"
movimiento\Anterior=LeerTexto(Estado+"/versiones/"+id+".json")
GuardarMovimiento(@movimiento)
Comprobar(Bool(Not RecuperarMovimiento() And FileSize(dato\Ruta)=-2 And FileSize(Estado+"/movimiento.json")>0),"diario con destino ajeno se conserva sin mover")
DeleteFile(Estado+"/movimiento.json")
movimiento\Destino=Almacen+"/retiradas/"+id : GuardarMovimiento(@movimiento)
Comprobar(Bool(RenombrarSinReemplazo(-100,movimiento\Origen,-100,movimiento\Destino,1)=0),"simula retirada interrumpida")
Comprobar(Bool(RecuperarMovimiento() And LeerTexto(dato\Ruta+"/datos.txt")="dato" And FileSize(movimiento\Destino)=-1),"recupera retirada legitima")
; No se heredan campos ausentes al leer registros antiguos.
json=ParseJSON(#PB_Any,"{"+Chr(34)+"Id"+Chr(34)+":"+Chr(34)+otroId+Chr(34)+","+Chr(34)+"Ruta"+Chr(34)+":"+Chr(34)+Hogar+"/otra"+Chr(34)+","+Chr(34)+"Estado"+Chr(34)+":"+Chr(34)+"disponible"+Chr(34)+"}")
If json : Guardar(Estado+"/versiones/"+otroId+".json",ComposeJSON(json)) : FreeJSON(json) : EndIf
otro\Correccion="valor-previo" : otro\NivelC=2
Comprobar(Bool(LeerVersion(otroId,@otro) And otro\Correccion="" And otro\NivelC=0),"registro anterior no hereda campos de otra version")
Comprobar(Bool(Not RutaIntegracionValida(Estado+"/../privado.txt") And Not RutaIntegracionValida(Estado+"/movimiento.json")),"diario no puede escribir fuera de sus destinos autorizados")
Define NewList rutas.s()
Guardar(Estado+"/activa.txt","ANTERIOR") : Guardar(Estado+"/anterior.txt","HISTORIAL")
AddElement(rutas()) : rutas()=Estado+"/activa.txt" : AddElement(rutas()) : rutas()=Estado+"/anterior.txt"
Comprobar(IniciarTransaccion(rutas()),"prepara diario de dos archivos")
Guardar(Estado+"/activa.txt","NUEVA") : Guardar(Estado+"/anterior.txt","OTRA")
Guardar(Estado+"/transaccion/1.copia","ALTERADO")
Comprobar(Bool(Not RecuperarTransaccion() And LeerTexto(Estado+"/activa.txt")="NUEVA" And LeerTexto(Estado+"/anterior.txt")="OTRA"),"copia corrupta impide restaurar parcialmente el diario")
Guardar(Estado+"/transaccion/1.copia","HISTORIAL")
Comprobar(Bool(RecuperarTransaccion() And LeerTexto(Estado+"/activa.txt")="ANTERIOR" And LeerTexto(Estado+"/anterior.txt")="HISTORIAL"),"recupera los dos archivos una vez restaurada la copia")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
