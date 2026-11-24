Procedure.s TextoAccesoIndividual(*dato.VersionPB, repetidas.i)
  Protected icono.s=IconoOficial(*dato\Ruta), nombre.s="PureBasic "+Etiqueta(*dato)+" ("+*dato\Edicion+")"
  If repetidas>1 : nombre+" - "+GetFilePart(*dato\Ruta) : EndIf
  If *dato\Limitacion<>"" : nombre+" [limitada]" : EndIf
  If icono="" : icono="applications-development" : EndIf
  ProcedureReturn "[Desktop Entry]"+#LF$+"# "+#MARCA_GESTOR+#LF$+"Type=Application"+#LF$+"Name="+nombre+#LF$+"Exec="+CitarDesktop(EjecutableGestor)+" --perfil "+CitarDesktop(Hogar)+" --abrir "+CitarDesktop(*dato\Id)+" %F"+#LF$+"Icon="+EscaparValor(icono)+#LF$+"Path="+EscaparValor(*dato\Ruta+"/compilers")+#LF$+"Terminal=false"+#LF$+"Categories=Development;IDE;"+#LF$+"X-GestorPureBasic-Version="+*dato\Id+#LF$
EndProcedure

Procedure AccesoIndividualPropio(texto.s,id.s)
  Protected comando.s=CitarDesktop(EjecutableGestor)+" --perfil "+CitarDesktop(Hogar)+" --abrir "+CitarDesktop(id)+" %F"
  ProcedureReturn Bool(ValorDesktop(texto,"Type")="Application" And ValorDesktop(texto,"X-GestorPureBasic-Version")=id And ValorDesktop(texto,"Exec")=comando)
EndProcedure

Procedure PlanIndividual(*dato.VersionPB,List accesos.AccesoPB(), quitar.i=0,repetidas.i=1)
  Protected nombre.s="PureBasic-"+ReplaceString(Etiqueta(*dato)," ","-")+"-"+*dato\Edicion+"-"+*dato\Id+".desktop", ruta.s, texto.s, escritorio.s=EscritorioUsuario(), indice
  If Controles(nombre) Or FindString(nombre,"/") : ProcedureReturn Fallar("Nombre de acceso no válido.") : EndIf
  If Not quitar : texto=TextoAccesoIndividual(*dato,repetidas) : EndIf
  For indice=0 To 1
    If indice=0 : ruta=Datos+"/applications/"+nombre : Else : If escritorio="" : Continue : EndIf : ruta=escritorio+"/"+nombre : EndIf
    If TipoArchivo(ruta)<>0
      If TipoArchivo(ruta)<>32768 Or Not AccesoIndividualPropio(LeerTexto(ruta),*dato\Id) : ProcedureReturn Fallar("Se conserva un acceso ajeno: "+ruta) : EndIf
    ElseIf quitar : Continue
    EndIf
    AgregarAcceso(accesos(),ruta,texto,420+73*indice)
  Next
  ProcedureReturn #True
EndProcedure

Procedure AccesosIndividuales(idQuitar.s="")
  Protected NewList accesos.AccesoPB(), NewList rutas.s(), bien, dato.VersionPB, activa.VersionPB, clave.s
  Protected NewMap cantidades.i()
  If Not PrepararEjecutable() : ProcedureReturn #False : EndIf
  CargarVersiones()
  ForEach Versiones()
    If Versiones()\Estado="disponible" And Versiones()\Id<>idQuitar
      clave=Etiqueta(@Versiones())+"/"+Versiones()\Edicion
      cantidades(clave)+1
    EndIf
  Next
  ForEach Versiones()
    If Versiones()\Estado="disponible" And Versiones()\Id<>idQuitar And Versiones()\Comprobada And EstructuraValida(Versiones()\Ruta)
      clave=Etiqueta(@Versiones())+"/"+Versiones()\Edicion
      If Not PlanIndividual(@Versiones(),accesos(),0,cantidades(clave)) : ProcedureReturn #False : EndIf
    EndIf
  Next
  If idQuitar<>"" And LeerVersion(idQuitar,@dato)
    If Not PlanIndividual(@dato,accesos(),1) : ProcedureReturn #False : EndIf
  EndIf
  ; Conserva identificadores de menu heredados para las asociaciones, pero evita duplicados visibles.
  If LeerVersion(Activa(),@activa)
    BuscarAccesos(accesos(),Datos+"/applications",TextoAcceso(@activa)+"NoDisplay=true"+#LF$,1)
    BuscarAccesos(accesos(),EscritorioUsuario(),"",1)
  EndIf
  If ListSize(accesos())=0 : ProcedureReturn #True : EndIf
  If Not RespaldarAccesos(accesos()) : ProcedureReturn #False : EndIf
  ForEach accesos() : AddElement(rutas()) : rutas()=accesos()\Ruta : Next
  If Not IniciarTransaccion(rutas()) : ProcedureReturn #False : EndIf
  bien=PublicarAccesos(accesos())
  If bien : bien=ConfirmarTransaccion() : EndIf
  If Not bien : RecuperarTransaccion() : ProcedureReturn Fallar("No se pudieron actualizar todos los accesos individuales.") : EndIf
  MarcarAccesos(accesos()) : ProcedureReturn #True
EndProcedure

