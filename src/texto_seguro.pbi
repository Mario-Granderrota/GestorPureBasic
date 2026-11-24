DeclareModule TextoSeguro
  Declare UTF8Valido(*datos,cantidad.i)
  Declare.s TextoSalidaUTF8(*datos,cantidad.i)
EndDeclareModule
Module TextoSeguro
; Validación estricta de UTF-8 de texto sin NUL. No se lee fuera del intervalo.
Procedure UTF8Valido(*datos,cantidad.i)
  Protected posicion.i, primero.i, segundo.i, restantes.i, indice.i
  While posicion<cantidad
    primero=PeekA(*datos+posicion) : restantes=0
    If primero=0 : ProcedureReturn #False
    ElseIf primero<$80 : posicion+1 : Continue
    ElseIf primero>=$C2 And primero<=$DF : restantes=1
    ElseIf primero>=$E0 And primero<=$EF : restantes=2
    ElseIf primero>=$F0 And primero<=$F4 : restantes=3
    Else : ProcedureReturn #False : EndIf
    If cantidad-posicion<=restantes : ProcedureReturn #False : EndIf
    segundo=PeekA(*datos+posicion+1)
    If (primero=$E0 And segundo<$A0) Or (primero=$ED And segundo>=$A0) Or (primero=$F0 And segundo<$90) Or (primero=$F4 And segundo>=$90) : ProcedureReturn #False : EndIf
    For indice=1 To restantes
      If (PeekA(*datos+posicion+indice)&$C0)<>$80 : ProcedureReturn #False : EndIf
    Next
    posicion+restantes+1
  Wend
  ProcedureReturn #True
EndProcedure
; La salida se acumula por bytes: una lectura puede dividir un carácter UTF-8.
Procedure.s TextoSalidaUTF8(*datos,cantidad.i)
  Protected inicio.i, primero.i, necesarios.i
  If cantidad<=0 : ProcedureReturn "" : EndIf
  inicio=cantidad-1
  While inicio>0 And (PeekA(*datos+inicio)&$C0)=$80 : inicio-1 : Wend
  primero=PeekA(*datos+inicio)
  If primero>=$C2 And primero<=$DF : necesarios=2
  ElseIf primero>=$E0 And primero<=$EF : necesarios=3
  ElseIf primero>=$F0 And primero<=$F4 : necesarios=4
  EndIf
  If necesarios>cantidad-inicio : cantidad=inicio : EndIf
  If cantidad=0 : ProcedureReturn "" : EndIf
  ProcedureReturn PeekS(*datos,cantidad,#PB_UTF8|#PB_ByteLength)
EndProcedure
EndModule
