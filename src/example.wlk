
class Archivo{
	const property nombre
	var contenido = ""
	
	
	method tieneNombre(nombreDeArchivo) = self.nombre() == nombreDeArchivo
	
	method agregarContenido(contenidoAAgregar){
		contenido = contenido + contenidoAAgregar
	}
	
	method quitarContenido(contenidoAQuitar){
		contenido = contenido - contenidoAQuitar
	}
}

class Carpeta{
	const nombre
	var archivos = #{}

	method agregar(nuevoArchivo){
		if(self.contiene(nuevoArchivo.nombre())){
			throw new DomainException (message = "La carpeta ya contiene un archivo con ese nombre")
		}
		else{
			archivos.add(nuevoArchivo)
		}
	}
	method contiene(nombreDeArchivo) = archivos.any{archivo => archivo.tieneNombre(nombreDeArchivo)}
	
	method buscar(nombreArchivo) = archivos.findOrElse({archivo => archivo.tieneNombre(nombreArchivo)}, {throw new DomainException (message = "No existe este archivo en la carpeta")})
	
	method eliminar(archivo){
		archivos.remove(archivo)
	}
}

// COMMITS Y CAMBIOS
class Commit{
	const descripcion
	const cambios = []
	const property autor
	
	method aplicarCambiosEn(carpeta){
		cambios.forEach{cambio => cambio.realizar(carpeta)}
	}
	
	method afectaA(unNombreArchivo) = cambios.any{cambio => cambio.modificaA(unNombreArchivo)}
	
	method revert() = new Commit(
		descripcion = "revert" + descripcion,
		cambios = cambios.map({ cambios => cambios.revertir() }).reverse(),
		autor = autor
	)
	
}

class Cambio{
	const property nombreDelArchivo
	
	method realizar(carpeta){
		const archivo = self.archivoAModificar(carpeta)
		self.aplicar(archivo, carpeta)
	}
	
	method archivoAModificar(carpeta) = carpeta.buscar(nombreDelArchivo)
	
	method aplicar(archivo, carpeta)
	
	method modificaA(unNombreArchivo) = nombreDelArchivo == unNombreArchivo
}

class Crear inherits Cambio{
	
	override method archivoAModificar(carpeta) = new Archivo(nombre = nombreDelArchivo)
	
	override method aplicar(archivo, carpeta){
		carpeta.agregar(archivo)
		
	}
	
	method revertir() = new Eliminar(nombreDelArchivo = nombreDelArchivo)
}

class Eliminar inherits Cambio{
	
	override method aplicar(archivo, carpeta){
		carpeta.eliminar(archivo)
	}
	
	method revertir() = new Crear(nombreDelArchivo = nombreDelArchivo)
	
}

class Agregar inherits Cambio{
	const contenidoAAgregar
	
	override method aplicar(archivo, carpeta){
		archivo.agregarContenido(contenidoAAgregar)
		}
		
	method revertir() = new Sacar(nombreDelArchivo = nombreDelArchivo, quitarContenido = contenidoAAgregar)
}

class Sacar inherits Cambio{
	const quitarContenido
	
	override method aplicar(archivo, carpeta){
		archivo.eliminarContenido(quitarContenido)
	}
	
	method revertir() = new Agregar(nombreDelArchivo = nombreDelArchivo, contenidoAAgregar = quitarContenido)

}

// BRANCHES
class Branches{
	var commits = []
	var colaboradores = []
	
	method checkoutEn(unaCarpeta) {
		commits.forEach{commit => commit.aplicarCambiosEn(unaCarpeta)}
	}
	
	method logDe(unNombreArchivo) = commits.filter{commit => commit.afectaA(unNombreArchivo)}
	
	method commitear(commit) {
		self.autorizarCommitDe(commit.autor())
		commits.add(commit)
	} 
	
	method autorizarCommitDe(usuario) {
		if(!usuario.tienePermisoParCommitearEn(self)){
			throw new DomainException(message = "No tiene los permisos necesarios")
		}
	}
	
	method esColaborador(usuario) = colaboradores.contains(usuario) 
	
	method blame(nombreDeArchivo) = self.logDe(nombreDeArchivo).map{commit => commit.autores()}

}
//USUARIOS

class Usuario{
	var rol
	
	method tienePermisoParaCommitearEn(branch) = branch.esColaborador() || rol.tienePermisosNecesariosEn(branch)
	method cambiarRol(rolNuevo){
		rol = rolNuevo
	}
}

object administrador{
	
	method tienePermisosNecesariosEn(branch) = true
	
	method cambiarRoles(usuarios, rol){
		usuarios.forEach{usuario => usuario.cambiarRol(rol)}
	}
}

object comun{
	
	method tienePermisosNecesariosEn(branch) = false
}

object bot{
	
	method tienePermisosNecesariosEn(branch) = branch.commits().size() > 10 
}

