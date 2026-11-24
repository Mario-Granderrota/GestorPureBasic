; Medicion aislada de generacion de manifiesto. No modifica el arbol fuente.
XIncludeFile "../src/nucleo.pbi"
OpenConsole()
If CountProgramParameters()<>2 : PrintN("Uso: rendimiento CARPETA MANIFIESTO") : End 2 : EndIf
Define origen.s=Canonica(ProgramParameter(0)), destino.s=ProgramParameter(1), indice, inicio, huella.s
If origen="" Or FileSize(origen)<>-2 Or FileSize(destino)<>-1 : End 2 : EndIf
For indice=1 To 3
  inicio=ElapsedMilliseconds()
  If Not CrearManifiesto(origen,destino) : PrintN(ErrorActual) : End 1 : EndIf
  PrintN("MS="+Str(ElapsedMilliseconds()-inicio)+" SHA256="+FileFingerprint(destino,#PB_Cipher_SHA2,256))
Next
End 0
