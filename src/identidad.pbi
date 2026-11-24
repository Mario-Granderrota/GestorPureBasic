Procedure ELFValido(ruta.s)
  Protected archivo, tamano.q, desplazamiento.q, longitud, numero, indice, tipo, offset.q, bytes.q, memoria.q, carga, bien=#True
  Protected Dim cabecera.a(63), Dim segmento.a(55)
  If TipoArchivo(ruta)<>32768 Or Not (GetFileAttributes(ruta)&64) : ProcedureReturn #False : EndIf
  tamano=FileSize(ruta)
  If tamano<64 Or tamano>536870912 : ProcedureReturn #False : EndIf
  archivo=ReadFile(#PB_Any,ruta) : If Not archivo : ProcedureReturn #False : EndIf
  If ReadData(archivo,@cabecera(),64)<>64 : CloseFile(archivo) : ProcedureReturn #False : EndIf
  If cabecera(0)<>127 Or cabecera(1)<>69 Or cabecera(2)<>76 Or cabecera(3)<>70 Or cabecera(4)<>2 Or cabecera(5)<>1 Or cabecera(6)<>1 Or PeekW(@cabecera()+18)<>62
    CloseFile(archivo) : ProcedureReturn #False
  EndIf
  tipo=PeekW(@cabecera()+16)
  desplazamiento=PeekQ(@cabecera()+32) : longitud=PeekW(@cabecera()+54)&65535 : numero=PeekW(@cabecera()+56)&65535
  If (tipo<>2 And tipo<>3) Or desplazamiento<64 Or longitud<>56 Or numero<1 Or numero>4096 Or desplazamiento>tamano-numero*56
    CloseFile(archivo) : ProcedureReturn #False
  EndIf
  For indice=0 To numero-1
    FileSeek(archivo,desplazamiento+indice*56)
    If ReadData(archivo,@segmento(),56)<>56 : bien=#False : Break : EndIf
    tipo=PeekL(@segmento()) : offset=PeekQ(@segmento()+8) : bytes=PeekQ(@segmento()+32) : memoria=PeekQ(@segmento()+40)
    If offset<0 Or bytes<0 Or offset>tamano Or bytes>tamano-offset : bien=#False : Break : EndIf
    If tipo=1
      If memoria<bytes : bien=#False : Break : EndIf
      carga+1
    EndIf
  Next
  CloseFile(archivo) : ProcedureReturn Bool(bien And carga>0)
EndProcedure
Procedure EstructuraValida(carpeta.s)
  If Enlace(carpeta) Or Enlace(carpeta+"/compilers") Or Not ELFValido(carpeta+"/compilers/purebasic") Or (Not ELFValido(carpeta+"/compilers/pbcompiler") And Not ELFValido(carpeta+"/compilers/pbcompilerc"))
    ProcedureReturn Fallar("El paquete no contiene IDE y compilador ELF Linux x64 completos y ejecutables.")
  EndIf
  If TipoArchivo(carpeta+"/purelibraries")<>16384 Or TipoArchivo(carpeta+"/residents")<>16384
    ProcedureReturn Fallar("Faltan las bibliotecas o los residentes de PureBasic.")
  EndIf
  ProcedureReturn #True
EndProcedure
Procedure.s IdentidadEstaticaMotor(carpeta.s,motor.s)
  Protected archivo, *buffer, tamano, posicion, cantidad, texto.s, mejor.s
  If Not ELFValido(carpeta+"/compilers/"+motor) : ProcedureReturn "" : EndIf
  archivo=ReadFile(#PB_Any,carpeta+"/compilers/"+motor)
  If Not archivo : ProcedureReturn "" : EndIf
  tamano=Lof(archivo)
  If tamano<=0 Or tamano>33554432 : CloseFile(archivo) : ProcedureReturn "" : EndIf
  *buffer=AllocateMemory(tamano+1)
  If Not *buffer : CloseFile(archivo) : ProcedureReturn "" : EndIf
  If ReadData(archivo,*buffer,tamano)=tamano
    For posicion=0 To tamano-20
      If PeekA(*buffer+posicion)=80 And PeekS(*buffer+posicion,10,#PB_Ascii)="PureBasic "
        cantidad=0
        While cantidad<180 And posicion+cantidad<tamano And PeekA(*buffer+posicion+cantidad)>=32 And PeekA(*buffer+posicion+cantidad)<127 : cantidad+1 : Wend
        texto=PeekS(*buffer+posicion,cantidad,#PB_Ascii)
        If FindString(texto,"Linux") And FindString(texto,"x64") And Asc(Mid(texto,11,1))>=48 And Asc(Mid(texto,11,1))<=57
          If Len(texto)>Len(mejor) Or (FindString(texto,"Free") And Not FindString(mejor,"Free")) : mejor=texto : EndIf
        EndIf
        texto=""
      EndIf
    Next
  EndIf
  CloseFile(archivo) : FreeMemory(*buffer) : ProcedureReturn mejor
EndProcedure
Procedure.s IdentidadEstatica(carpeta.s)
  Protected identidad.s=IdentidadEstaticaMotor(carpeta,"pbcompiler")
  If identidad="" : identidad=IdentidadEstaticaMotor(carpeta,"pbcompilerc") : EndIf
  ProcedureReturn identidad
EndProcedure
Procedure PonerIdentidad(*version.VersionPB, texto.s)
  Protected indice, caracter.s, numero.s
  If Left(texto,10)<>"PureBasic " Or Not FindString(texto,"Linux") Or Not FindString(texto,"x64") : ProcedureReturn #False : EndIf
  For indice=11 To Len(texto)
    caracter=Mid(texto,indice,1)
    If Not FindString("0123456789.",caracter) : Break : EndIf
    numero+caracter
  Next
  If CountString(numero,".")<1 Or Left(numero,1)="." Or Right(numero,1)="." Or FindString(numero,"..") Or Len(numero)>24 : ProcedureReturn #False : EndIf
  *version\Numero=numero : *version\Identidad=StringField(texto,1,#LF$)
  *version\Edicion="completa"
  If FindString(LCase(texto),"free") Or FindString(LCase(texto),"demo")
    *version\Edicion="gratuita"
  ElseIf FindString(LCase(texto),"c backend")
    ; La demo 6.41 C omite Free de su banner. No inferir licencia completa.
    *version\Edicion="desconocida"
  EndIf
  ProcedureReturn #True
EndProcedure
