XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i,Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : End 2 : EndIf
Global Casos.s=ProgramParameter(1),nombre.s,salida.s,bien,listado,contador
listado=ExamineDirectory(#PB_Any,Casos,"*")
If listado
  While NextDirectoryEntry(listado)
    nombre=DirectoryEntryName(listado)
    If GetExtensionPart(nombre)<>"tar" And GetExtensionPart(nombre)<>"tgz" : Continue : EndIf
    salida=Hogar+"/caso-"+Str(contador) : CrearCarpetas(salida) : ErrorActual=""
    bien=ExtraerTar(Casos+"/"+nombre,salida)
    If nombre="valido.tar" Or nombre="gnu_largo.tar"
      Comprobar(bien,"acepta "+nombre)
    Else
      Comprobar(Bool(Not bien),"rechaza "+nombre)
    EndIf
    contador+1
  Wend
  FinishDirectory(listado)
EndIf
Comprobar(Bool(contador=15),"recorre todos los paquetes de seguridad")
Comprobar(Bool(Not CopiarArbol(Casos+"/carpeta-enlace",Hogar+"/enlace")),"rechaza enlaces al copiar")
Comprobar(Bool(Not CopiarArbol(Casos+"/carpeta-fifo",Hogar+"/fifo")),"rechaza archivos especiales sin bloquearse")
Guardar(Hogar+"/literal+%.txt","dato")
Comprobar(Bool(Normalizar("file://"+Hogar+"/literal+%25.txt")=Hogar+"/literal+%.txt"),"URI conserva más y porcentaje")
Comprobar(Bool(Normalizar("file://servidor/tmp")=""),"rechaza ubicaciones remotas")
Comprobar(Bool(Not ELFValido(Hogar+"/inexistente")),"rechaza ejecutables ausentes")
Comprobar(Bool(FileSize(Hogar+"/escape.txt")=-1),"ningún traversal escribe fuera de su destino")
Comprobar(Bool(Not RutaTarValida("/etc/passwd") And Not RutaTarValida("a/../escape")),"bloquea rutas no confinadas")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
