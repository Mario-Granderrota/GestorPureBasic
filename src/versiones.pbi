Procedure.s Etiqueta(*dato.VersionPB)
  ProcedureReturn Politica::Etiqueta(*dato\Numero,*dato\Identidad)
EndProcedure
Procedure CompararVersiones(*nueva.VersionPB,*anterior.VersionPB)
  ProcedureReturn Politica::Comparar(*nueva\Numero,*nueva\Identidad,*anterior\Numero,*anterior\Identidad)
EndProcedure

Procedure.s RelacionVersion(*nueva.VersionPB,*anterior.VersionPB)
  Select CompararVersiones(*nueva,*anterior)
    Case 1 : ProcedureReturn "VERSIÓN SUPERIOR (actualización)"
    Case -1 : ProcedureReturn "VERSIÓN ANTERIOR (retroceso)"
    Default : ProcedureReturn "MISMA VERSIÓN (reinstalación)"
  EndSelect
EndProcedure

