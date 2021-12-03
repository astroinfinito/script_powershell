function showmenu {
	param([switch]$Elevated)
		function Test-Admin { #Esta función se encarga de comprobar que tenemos los privielegios adecuados
		  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
		  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
		}

		if ((Test-Admin) -eq $false)  {
		    if ($elevated) 
		    {
		        # Intentamos elevar privilegios, pero no ha habido éxito
		    } 
		    else {
		        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
		}

		exit
	}

	'Corriendo con privilegios de administrador' #Esto nos permitirá ejecutar el script como administrador
    
    Clear-Host
    Write-Host "****************************************************************************"
	Write-Host " Grupo: K.A.U.IT                                                            "
	Write-Host " Componentes: Albert Ibañez, Alejandro Chamorro, Alberto Zarzo, Yahir Arce  "
	Write-Host " Fecha: 16/11/2021                                                          "
	Write-Host " Versión: 1.0                                                               "
	Write-Host "****************************************************************************"
	Write-Host ""
    Write-Host "AUTOMATIZACIÓN DE TAREAS Y PROCESOS DEL SISTEMA."
    Write-Host "1. Ejecutar script monitorización del sistema"
    Write-Host "2. Ejecutar script sistema de ficheros"
    Write-Host "3. Ejecutar script gestión de procesos"
    Write-Host "4. Terminar"

}
 
showmenu
 
while(($inp = Read-Host -Prompt "Seleccionar una opción") -ne "4"){
 
switch($inp){
        1 {
            Clear-Host
            Write-Host "------------------------------";
            Write-Host "Monitorización del sistema"; 
            Write-Host "------------------------------";
          	Get-WmiObject -class "Win32_Processor"| % { 
			    Write-Host "CPU ID: " $_.DeviceID   
			    Write-Host "CPU Model: " $_.Name
			    Write-Host "CPU Cores: " $_.NumberOfCores
			    Write-Host "CPU Max Speed: " $_.MaxClockSpeed 
			    Write-Host "CPU Status: " $_.Status 
			    Write-Host 
			}
			function espacio_libre{ #Función que nos permite ver el epacio libre en disco
				Get-WmiObject -Class Win32_LogicalDisk
			}
			espacio_libre
			function Procesos{ #Función que nos permite ver todos los procesos del sistema
		    	Get-Process
	 		}
	 		Procesos
	 		function Logs { #Con esta función se creará un registro de logs en el fichero "alerta.log" en caso de superar ciertos valores
			    formatoInicial
			    Write-Host Generacion de logs en casos particulares
			    $nombreOrdenador = read-host "Introduzca el nombre del ordenador"
			    $memoriaTotal=(Get-WmiObject -ComputerName $nombreOrdenador -Class Win32_OperatingSystem).TotalVisibleMemorySize #Se extrae la memoria RAM total del equipo seleccionado
			    $memoriaLibre=(Get-WmiObject -ComputerName $nombreOrdenador -Class Win32_OperatingSystem).FreePhysicalMemory #Se extrae la memoria RAM libre del equipo seleccionado
			    $totalCPU=100;
			    $totalLibre=100;
			    $usoCPU=(Get-WmiObject win32_processor -computername WIN-2MNDDN9A6G8 |  Measure-Object -property LoadPercentage -Average | Foreach {"{0:N2}" -f ($_.Average)}) #Se extrae el porcentaje de uso de la CPU
			    $espacioLibre=(Get-WMIObject  -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object @{n='% Libre';e={"{0:n2}" -f ($_.freespace/$_.size*100)}}) #Se extrae el porcentaje libre del disco duro


			if ($memoriaLibre -lt ($memoriaTotal*25/100)) { #Se crea un registro en caso de superar el 75% de memoria usada
			         $fecha=Get-Date -UFormat "%d/%m/%Y %R" #Extrae la fecha del sistema
			         $Fecha+" Alerta Memoria: El equipo "+$nombreOrdenador+" supera el 75% de memoria usada" | Out-File alerta.log -Append
			         
			         if(-not $param) { #Si no se ejecuta el script con parámetros, se informa al usuario del error por pantalla
			            Write-Warning "MEMORIA - El equipo $nombreOrdenador supera el 75% de memoria usada"
			         }
			    }
			}

			if ($totalCPU -lt ($usoCPU*25/100)) { #Se crea un registro en caso de superar el 75% de memoria usada
			         $fecha=Get-Date -UFormat "%d/%m/%Y %R" #Extrae la fecha del sistema
			         $Fecha+" Alerta CPU: El equipo "+$nombreOrdenador+" supera el 75% del uso de la CPU" | Out-File alerta.log -Append
			         
			         if(-not $param) { #Si no se ejecuta el script con parámetros, se informa al usuario del error por pantalla, cosa que no debería ocurrir ya que para eso hemos puesto el read-host antes
			            Write-Warning "CPU - El equipo $nombreOrdenador supera el 75% del uso de la CPU"
			         }
			}

			if ($totalLibre -gt ($espacioLibre*25/100)) { #Se crea un registro en caso de superar el 75% de memoria usada
			         $fecha=Get-Date -UFormat "%d/%m/%Y %R" #Extrae la fecha del sistema
			         $Fecha+" Alerta Disco: El equipo "+$nombreOrdenador+" supera el 75% de la capacidad del disco duro" | Out-File alerta.log -Append
			         
			         if(-not $param) { #Si no se ejecuta el script con parámetros, se informa al usuario del error por pantalla, cosa que no debería ocurrir ya que para eso hemos puesto el read-host antes
			            Write-Warning "DISCO - El equipo $nombreOrdenador supera el 75% del uso del disco duro"
			         }
			}

			Logs

			#La variable $nombreOrdenador está vacía, por lo tanto se debe especificar el nombre del ordenador.

		    pause;
            break
        }
        2 {
            Clear-Host
            Write-Host "------------------------------";
            Write-Host "Sistema de ficheros";
            Write-Host "------------------------------";
            function localiza_ficheros{
			 $ruta = read-host "Introduzca ruta: "
			 Get-ChildItem -Path $ruta -Force -Recurse; 
			}
			localiza_ficheros
            pause; 
            break
        }
        3 {
            Clear-Host
            Write-Host "------------------------------";
            Write-Host "Gestión de procesos";
            Write-Host "------------------------------"; 
            function localiza_procesos{ #Aquí podemos ver los procesos relacionados con un usuario concreto
				 $user = read-host "Introduzca usuario para ver sus procesos:  "
				 get-process | select processname,Id,@{l="$user";e={$owners[$_.id.tostring()]}}
			}
			function ProcesosTotales { 
			#Esta función nos facilita todos los datos de los procesos ejecutados en el sistema
	 	    $cores = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors #Nos indica el número de cores lógicos de nuestro sistema
	    	$memoriaTotal=(Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize #Nos facilita la memoria total del sistema
	   
		    #Se guarda en la variable "procesosPerfor" el porcentaje de CPU, el PID, el porcentaje de memoria y el tiempo de ejecución
		    $procesosPerfor=Get-WmiObject Win32_PerfFormattedData_PerfProc_Process |
		        Select-Object -Property Name, @{Name = "CPU"; Expression = {($_.PercentProcessorTime/$cores)}}, @{Name = "PID"; Expression = {$_.IDProcess}}, @{Name = "RAM"; Expression = {([math]::round(($_.WorkingSetPrivate*100/(1024*$memoriaTotal)),2))}}, @{Name = "TiempoEjecucion"; Expression = {$_.ElapsedTime}} |
		        Where-Object {$_.Name -notmatch "^(idle|_total|system)$"} | Sort-Object -Property CPU -Descending
		    $procesos=Get-Process -IncludeUserName | Select-Object * #Se guarda en la variable "procesos" toda la información de los procesos del sistema
		    $procesosSalida=@()

	        #Para cada proceso guardado en "procesos" se extrae la información requerida: Nombre, Usuario, PID, CPU(%), Memoria(%), Estado, Hora de inicio, Tiempo de ejecución y Comando que lo inicializó
	        foreach ($proc in $procesos) {
	               $process=New-Object System.Object
	               $perf=$procesosPerfor | Where-Object { $_.PID -eq $proc.Id }

	        if($proc.HasExited -eq "True") {
	            $estado="Detenido"
	        }
	        else { $estado="Activo"}

	        $process | Add-Member -type NoteProperty -Name "Proceso" -Value $proc.Name
	        $process | Add-Member -type NoteProperty -Name "Usuario" -Value $proc.UserName
	        $process | Add-Member -type NoteProperty -Name "PID" -Value $proc.Id
	        $process | Add-Member -type NoteProperty -Name "CPU(%)" -Value $perf.CPU
	        $process | Add-Member -type NoteProperty -Name "Memoria(%)" -Value $perf.RAM
	        $process | Add-Member -type NoteProperty -Name "Estado" -Value $estado
	        $process | Add-Member -type NoteProperty -Name "Hora de inicio" -Value $proc.StartTime
	        $process | Add-Member -type NoteProperty -Name "TPO ejec" -Value $perf.TiempoEjecucion
	        $process | Add-Member -type NoteProperty -Name "Comando inicio" -Value $proc.Path

	        $procesosSalida += $process
	    }
	    if($opcion -eq 2) { #Si la función no ha sido llamada por ProcesosPorcentaje
	        $procesosSalida | Sort-Object -Property Usuario | Format-Table -Autosize #Los procesos están ordenados por el usuario que los ha generado
	        Volver
	    }
	    else { #Si la función ha sido llamada por ProcesosPorcentaje
	        $procesosSalida | Sort-Object -Property Usuario
			    }
			}

			procesosTotales
			localiza_procesos
            pause;
            break
            }
        4 {"Exit"; break}
        default {Write-Host -ForegroundColor red -BackgroundColor white "Opción incorrecta";pause}
        
    }
 
showmenu
}