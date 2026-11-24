; Reglas de dominio: sin estado global, E/S ni interfaz grafica.
DeclareModule Politica
  Enumeration
    #NoInstalada
    #Instalada
    #ConIncidencias
    #SustitucionBloqueada
    #InstaladaLimitada
  EndEnumeration
  Enumeration
    #NoUtilizable
    #Limitado
    #Correcto
  EndEnumeration
  Structure ResultadoMotor
    Motor.s
    Nivel.i
    Limitado.i
  EndStructure
  Declare.s Etiqueta(numero.s, identidad.s)
  Declare Comparar(numeroA.s, identidadA.s, numeroB.s, identidadB.s)
  Declare ElegirMotor(c.i, asm.i, incluyeC.i, incluyeASM.i, pedido.s, *salida.ResultadoMotor)
  Declare PuedeSustituir(comprobada.i, limitacion.s, validacion.s, modoPruebas.i=0)
  Declare LicenciaCompatible(anterior.s, nueva.s)
EndDeclareModule
Module Politica
  Procedure.s Etiqueta(numero.s, identidad.s)
    Protected etiqueta.s=numero, resto.s=LCase(identidad), expresion
    expresion=CreateRegularExpression(#PB_Any,"(?i)(beta|alpha|rc)[ ]*[0-9]*")
    If expresion
      Protected Dim coincidencias.s(0)
      If ExtractRegularExpression(expresion,resto,coincidencias()) : etiqueta+" "+coincidencias(0) : EndIf
      FreeRegularExpression(expresion)
    EndIf
    If FindString(resto," lts") : etiqueta+" LTS" : EndIf
    ProcedureReturn etiqueta
  EndProcedure
  Procedure Fase(texto.s)
    If FindString(texto," alpha") : ProcedureReturn 0 : EndIf
    If FindString(texto," beta") : ProcedureReturn 1 : EndIf
    If FindString(texto," rc") : ProcedureReturn 2 : EndIf
    ProcedureReturn 3
  EndProcedure
  Procedure NumeroFase(texto.s, numero.s)
    Protected indice
    For indice=Len(numero)+1 To Len(texto)
      If FindString("0123456789",Mid(texto,indice,1)) : ProcedureReturn Val(Mid(texto,indice)) : EndIf
    Next
    ProcedureReturn 0
  EndProcedure
  Procedure Comparar(numeroA.s, identidadA.s, numeroB.s, identidadB.s)
    Protected indice,a.q,b.q,limite=CountString(numeroA,".")+1, textoA.s, textoB.s
    If CountString(numeroB,".")+1>limite : limite=CountString(numeroB,".")+1 : EndIf
    For indice=1 To limite
      a=Val(StringField(numeroA,indice,".")) : b=Val(StringField(numeroB,indice,"."))
      If a>b : ProcedureReturn 1 : ElseIf a<b : ProcedureReturn -1 : EndIf
    Next
    textoA=LCase(Etiqueta(numeroA,identidadA)) : textoB=LCase(Etiqueta(numeroB,identidadB))
    a=Fase(textoA) : b=Fase(textoB)
    If a>b : ProcedureReturn 1 : ElseIf a<b : ProcedureReturn -1 : EndIf
    a=NumeroFase(textoA,numeroA) : b=NumeroFase(textoB,numeroB)
    If a>b : ProcedureReturn 1 : ElseIf a<b : ProcedureReturn -1 : EndIf
    ProcedureReturn 0
  EndProcedure
  Procedure ElegirMotor(c.i, asm.i, incluyeC.i, incluyeASM.i, pedido.s, *salida.ResultadoMotor)
    ClearStructure(*salida,ResultadoMotor)
    If pedido="C"
      If c>0 : *salida\Motor="C" : *salida\Nivel=c : EndIf
    ElseIf pedido="ASM"
      If asm>0 : *salida\Motor="ASM" : *salida\Nivel=asm : EndIf
    ElseIf pedido<>"AUTO"
      ProcedureReturn 0
    ElseIf c>=asm And c>0 : *salida\Motor="C" : *salida\Nivel=c : ElseIf asm>0 : *salida\Motor="ASM" : *salida\Nivel=asm : EndIf
    *salida\Limitado=Bool(*salida\Nivel=#Limitado Or ((incluyeC And c<#Correcto) Or (incluyeASM And asm<#Correcto)))
    ProcedureReturn *salida\Nivel
  EndProcedure
  Procedure PuedeSustituir(comprobada.i, limitacion.s, validacion.s, modoPruebas.i=0)
    ProcedureReturn Bool(comprobada And limitacion="" And (validacion="completa" Or (modoPruebas And validacion="consola")))
  EndProcedure
  Procedure LicenciaCompatible(anterior.s, nueva.s)
    ProcedureReturn Bool((nueva="completa" Or nueva="gratuita") And (anterior="completa" Or anterior="gratuita") And Not (anterior="completa" And nueva="gratuita"))
  EndProcedure
EndModule
