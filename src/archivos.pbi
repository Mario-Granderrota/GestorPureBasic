; Lectura TAR/GZIP: solo se crean archivos regulares y directorios.
ImportC ""
  EspacioNativo.l(ruta.p-utf8,*informacion) As "statvfs"
EndImport
Procedure.q EspacioLibre(ruta.s)
  Protected Dim datos.a(255)
  If EspacioNativo(ruta,@datos())<>0 : ProcedureReturn -1 : EndIf
  ProcedureReturn PeekQ(@datos()+8)*PeekQ(@datos()+32)
EndProcedure
Procedure.q NumeroOctal(*datos,longitud.i)
  Protected indice, valor.q, codigo, terminado
  For indice=0 To longitud-1
    codigo=PeekA(*datos+indice)
    If codigo=0 Or codigo=32
      If valor>0 : terminado=#True : EndIf
    Else
      If terminado Or codigo<48 Or codigo>55 Or valor>1152921504606846975 : ProcedureReturn -1 : EndIf
      valor=valor*8+codigo-48
    EndIf
  Next
  ProcedureReturn valor
EndProcedure
Procedure RutaTarValida(nombre.s)
  Protected indice, parte.s
  If nombre="" Or Len(nombre)>2048 Or Left(nombre,1)="/" Or FindString(nombre,Chr(92)) Or Controles(nombre) : ProcedureReturn #False : EndIf
  For indice=1 To CountString(nombre,"/")+1
    parte=StringField(nombre,indice,"/")
    If parte="" Or parte="." Or parte=".." Or parte=".gestor2" : ProcedureReturn #False : EndIf
  Next
  ProcedureReturn #True
EndProcedure
Procedure LeerGzip(*archivo,*buffer,cantidad.i)
  Protected leidos, resultado
  While leidos<cantidad
    resultado=GzipLeer(*archivo,*buffer+leidos,cantidad-leidos)
    If resultado<=0 : ProcedureReturn #False : EndIf
    leidos+resultado
  Wend
  ProcedureReturn #True
EndProcedure
Procedure.s CampoTar(*buffer,longitud.i)
  Protected cantidad
  While cantidad<longitud And PeekA(*buffer+cantidad)<>0 : cantidad+1 : Wend
  If cantidad=0 : ProcedureReturn "" : EndIf
  If Not TextoSeguro::UTF8Valido(*buffer,cantidad) : ProcedureReturn Chr(1) : EndIf
  ProcedureReturn PeekS(*buffer,cantidad,#PB_UTF8|#PB_ByteLength)
EndProcedure
Procedure ExtraerTar(origen.s,destino.s)
  Protected archivo, *buffer=AllocateMemory(65536), *cabecera=AllocateMemory(512), tipo, indice, ceros, suma.q, esperado.q
  Protected nombre.s, prefijo.s, nombreLargo.s, nombrePax.s, tamanoPax.q=-1, registro.s, clave.s, valor.s, posicion, espacio, largo, digito, cifra, finRegistro
  Protected tamano.q, restante.q, total.q, modo.q, cantidad, salida, ruta.s, relleno, miembros, bien=#True, raiz.s
  Protected NewMap Vistos.i()
  If Not *buffer Or Not *cabecera
    If *buffer : FreeMemory(*buffer) : EndIf : If *cabecera : FreeMemory(*cabecera) : EndIf
    ProcedureReturn Fallar("Memoria insuficiente para leer el paquete.")
  EndIf
  archivo=GzipAbrir(origen,"rb")
  If Not archivo : FreeMemory(*buffer) : FreeMemory(*cabecera) : ProcedureReturn Fallar("No se puede abrir el paquete.") : EndIf
  Repeat
    If Cancelacion() : bien=Fallar("Extracción cancelada.") : Break : EndIf
    If Not LeerGzip(archivo,*cabecera,512) : bien=Fallar("TAR/GZIP truncado o dañado.") : Break : EndIf
    suma=0 : For indice=0 To 511 : suma+PeekA(*cabecera+indice) : Next
    If suma=0
      ceros+1 : If ceros=2 : Break : EndIf : Continue
    EndIf
    If ceros : bien=Fallar("Final TAR no válido.") : Break : EndIf
    esperado=NumeroOctal(*cabecera+148,8)
    For indice=148 To 155 : suma-PeekA(*cabecera+indice) : suma+32 : Next
    If esperado<0 Or esperado<>suma : bien=Fallar("Cabecera TAR con checksum incorrecto.") : Break : EndIf
    nombre=CampoTar(*cabecera,100) : prefijo=""
    If CampoTar(*cabecera+257,6)="ustar" And PeekA(*cabecera+262)=0 : prefijo=CampoTar(*cabecera+345,155) : EndIf
    If prefijo<>"" : nombre=prefijo+"/"+nombre : EndIf
    tamano=NumeroOctal(*cabecera+124,12) : modo=NumeroOctal(*cabecera+100,8) : tipo=PeekA(*cabecera+156)
    If tamano<0 Or tamano>1073741824 Or modo<0 : bien=Fallar("Tamaño o permisos TAR no admitidos.") : Break : EndIf
    miembros+1
    If miembros>20000 : bien=Fallar("El paquete supera las 20.000 entradas.") : Break : EndIf
    If tipo=76 Or tipo=120 Or tipo=103 ; GNU longname / PAX local / PAX global
      If tamano>65535 : bien=Fallar("Metadatos TAR demasiado largos.") : Break : EndIf
      If Not LeerGzip(archivo,*buffer,tamano) : bien=Fallar("Metadatos TAR truncados.") : Break : EndIf
      If tipo=76
        nombreLargo=CampoTar(*buffer,tamano)
      Else
        posicion=0
        While posicion<tamano
          espacio=posicion : largo=0
          While espacio<tamano And PeekA(*buffer+espacio)<>32
            digito=PeekA(*buffer+espacio)-48
            If digito<0 Or digito>9 Or largo>65535 : bien=#False : Break : EndIf
            largo=largo*10+digito : espacio+1
          Wend
          If Not bien Or espacio>=tamano Or largo<=espacio-posicion+2 Or largo>tamano-posicion : bien=#False : Break : EndIf
          finRegistro=posicion+largo-1
          If PeekA(*buffer+finRegistro)<>10 : bien=#False : Break : EndIf
          If Not TextoSeguro::UTF8Valido(*buffer+espacio+1,finRegistro-espacio-1) : bien=#False : Break : EndIf
          registro=PeekS(*buffer+espacio+1,finRegistro-espacio-1,#PB_UTF8|#PB_ByteLength)
          If StringByteLength(registro,#PB_UTF8)<>finRegistro-espacio-1 Or FindString(registro,"=")<2 : bien=#False : Break : EndIf
          clave=StringField(registro,1,"=") : valor=Mid(registro,FindString(registro,"=")+1)
          If clave="path"
            If tipo=103 Or valor="" : bien=#False : Break : EndIf
            nombrePax=valor
          ElseIf clave="size"
            If tipo=103 Or valor="" Or Len(valor)>10 : bien=#False : Break : EndIf
            For cifra=1 To Len(valor)
              If Not FindString("0123456789",Mid(valor,cifra,1)) : bien=#False : Break : EndIf
            Next
            If Not bien : Break : EndIf
            tamanoPax=Val(valor)
          ElseIf clave="linkpath" Or Left(clave,11)="GNU.sparse."
            bien=#False : Break
          EndIf
          posicion+largo
        Wend
      EndIf
      relleno=(512-tamano%512)%512
      If Not bien Or Not LeerGzip(archivo,*buffer,relleno) : bien=Fallar("Metadatos PAX/GNU no admitidos o dañados.") : Break : EndIf
      Continue
    EndIf
    If nombreLargo<>"" : nombre=nombreLargo : nombreLargo="" : EndIf
    If nombrePax<>"" : nombre=nombrePax : nombrePax="" : EndIf
    If tamanoPax>=0 : tamano=tamanoPax : tamanoPax=-1 : EndIf
    While Left(nombre,2)="./" : nombre=Mid(nombre,3) : Wend
    nombre=RTrim(nombre,"/")
    If nombre="" And tipo=53 And tamano=0 : Continue : EndIf
    If Not RutaTarValida(nombre) Or (tipo<>0 And tipo<>48 And tipo<>53) Or FindMapElement(Vistos(),nombre)
      bien=Fallar("Ruta, duplicado, enlace o tipo no admitido: "+nombre) : Break
    EndIf
    AddMapElement(Vistos(),nombre) : Vistos()=tipo
    If raiz="" : raiz=StringField(nombre,1,"/") : EndIf
    If StringField(nombre,1,"/")<>raiz : bien=Fallar("El paquete contiene varias carpetas raíz.") : Break : EndIf
    ruta=destino+"/"+nombre
    If tipo=53
      If tamano<>0 Or Not CrearCarpetas(ruta) : bien=Fallar("Directorio TAR no válido.") : Break : EndIf
    Else
      total+tamano
      If tamano<0 Or tamano>1073741824 Or total>#MAXIMO_TOTAL : bien=Fallar("El paquete supera los límites de extracción.") : Break : EndIf
      If EspacioLibre(destino)<tamano+33554432 : bien=Fallar("Espacio insuficiente para extraer el paquete.") : Break : EndIf
      If Not CrearCarpetas(RTrim(GetPathPart(ruta),"/")) Or TipoArchivo(ruta)<>0 : bien=Fallar("Colisión en el destino TAR.") : Break : EndIf
      salida=CreateFile(#PB_Any,ruta)
      If Not salida : bien=Fallar("No se puede escribir: "+ruta) : Break : EndIf
      FileBuffersSize(salida,0) : restante=tamano
      While restante>0
        cantidad=65536 : If restante<cantidad : cantidad=restante : EndIf
        If Cancelacion() Or Not LeerGzip(archivo,*buffer,cantidad) : bien=#False : Break : EndIf
        If WriteData(salida,*buffer,cantidad)<>cantidad : bien=#False : Break : EndIf
        restante-cantidad
      Wend
      CloseFile(salida)
      If Not bien Or FileSize(ruta)<>tamano : bien=Fallar("Escritura incompleta, cancelación o archivo truncado: "+nombre) : Break : EndIf
      cantidad=420 : If modo&64 : cantidad=493 : EndIf
      If Not SetFileAttributes(ruta,cantidad) : bien=Fallar("No se pueden establecer los permisos.") : Break : EndIf
      relleno=(512-tamano%512)%512
      If Not LeerGzip(archivo,*buffer,relleno) : bien=Fallar("Relleno TAR truncado.") : Break : EndIf
    EndIf
    If miembros%150=0 : Registrar("Extracción: "+Str(miembros)+" entradas.") : EndIf
  ForEver
  If bien
    ; Consumir el flujo completo verifica también el CRC del GZIP y rechaza datos tras el final TAR.
    total=0
    Repeat
      cantidad=GzipLeer(archivo,*buffer,65536)
      If cantidad=0 : Break : EndIf
      If cantidad<0 : bien=Fallar("CRC o flujo GZIP incorrecto.") : Break : EndIf
      total+cantidad
      If total>16777216 : bien=Fallar("Relleno TAR excesivo.") : Break : EndIf
      For indice=0 To cantidad-1
        If PeekA(*buffer+indice)<>0 : bien=#False : Break : EndIf
      Next
      If Not bien : Fallar("Datos inesperados después del final TAR.") : Break : EndIf
    ForEver
  EndIf
  If GzipCerrar(archivo)<>0 And bien : bien=Fallar("Error al cerrar el GZIP.") : EndIf
  FreeMemory(*buffer) : FreeMemory(*cabecera) : ProcedureReturn bien
EndProcedure
