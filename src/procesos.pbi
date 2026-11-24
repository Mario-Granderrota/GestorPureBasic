Structure ResultadoProcesoPB
  Salida.s
  Codigo.i
EndStructure
; Puerto de ejecucion: el resultado pertenece al llamante, no al estado global.
Prototype EjecutorPB(programa.s,argumentos.s,carpeta.s,*resultado.ResultadoProcesoPB,segundos.i)
Procedure EjecutarProceso(programa.s, argumentos.s, carpeta.s, *resultado.ResultadoProcesoPB, segundos.i=60)
  Protected limiteLecturas, proceso, inicio=ElapsedMilliseconds(), cantidad, *buffer=AllocateMemory(65537), mensaje.s, pid, terminado, quedan, *bruto=AllocateMemory(262145), usados, guardar, errores.s
  *resultado\Salida="" : *resultado\Codigo=-1
  If Not *buffer Or Not *bruto
    If *buffer : FreeMemory(*buffer) : EndIf
    If *bruto : FreeMemory(*bruto) : EndIf
    ProcedureReturn Fallar("Memoria insuficiente.")
  EndIf
  proceso=RunProgram("/usr/bin/setsid","--wait "+Citar(programa)+" "+argumentos,carpeta,#PB_Program_Open|#PB_Program_Read|#PB_Program_Error)
  If Not proceso : FreeMemory(*buffer) : FreeMemory(*bruto) : ProcedureReturn Fallar("No se pudo iniciar: "+programa) : EndIf
  pid=ProgramID(proceso)
  Repeat
    cantidad=AvailableProgramOutput(proceso)
    limiteLecturas=0
    While cantidad>0 And limiteLecturas<32
      limiteLecturas+1
      If cantidad>65536 : cantidad=65536 : EndIf
      cantidad=ReadProgramData(proceso,*buffer,cantidad)
      If cantidad>0 And usados<262144
        guardar=cantidad : If guardar>262144-usados : guardar=262144-usados : EndIf
        CopyMemory(*buffer,*bruto+usados,guardar) : usados+guardar
      EndIf
      cantidad=AvailableProgramOutput(proceso)
    Wend
    quedan=Bool(cantidad>0)
    mensaje=ReadProgramError(proceso)
    limiteLecturas=0
    While mensaje<>"" And limiteLecturas<32
      limiteLecturas+1
      If Len(errores)<262144 : errores+Left(mensaje,262144-Len(errores))+#LF$ : EndIf
      If limiteLecturas>=32 : Break : EndIf
      mensaje=ReadProgramError(proceso)
    Wend
    ; El hijo puede terminar entre la lectura y ProgramRunning. Drenar una vez más.
    If terminado And Not quedan And limiteLecturas<32 : Break : EndIf
    If Not terminado And Not ProgramRunning(proceso) : terminado=1 : Continue : EndIf
    If Cancelacion() Or (segundos>0 And ElapsedMilliseconds()-inicio>segundos*1000)
      kill_(-pid,15) : Delay(40) : kill_(-pid,9) : KillProgram(proceso) : WaitProgram(proceso,2000)
      *resultado\Salida=TextoSeguro::TextoSalidaUTF8(*bruto,usados)+errores
      CloseProgram(proceso) : FreeMemory(*buffer) : FreeMemory(*bruto)
      ProcedureReturn Fallar("Proceso cancelado o agotado su tiempo: "+GetFilePart(programa))
    EndIf
    Delay(10)
  ForEver
  *resultado\Codigo=ProgramExitCode(proceso) : *resultado\Salida=TextoSeguro::TextoSalidaUTF8(*bruto,usados)+errores
  CloseProgram(proceso) : FreeMemory(*buffer) : FreeMemory(*bruto)
  ProcedureReturn Bool(*resultado\Codigo=0)
EndProcedure
