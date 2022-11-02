
class Archivo{
	const property nombre
	var contenido = ""
	
	
	method tieneNombre(nombreDeArchivo) = self.nombre() == nombreDeArchivo
	
	method agregarContenido(contenidoAAgregar){
		contenido += contenidoAAgregar
	}
	
	method eliminarContenido(contenidoAQuitar){
		var posicion = contenido.size() - contenidoAQuitar.size()
		self.validarContenido(contenidoAQuitar, posicion)
		contenido= contenido.take(posicion)
	}
	
	method validarContenido(contenidoAQuitar, posicion){
		if(contenidoAQuitar != contenido.drop(posicion)){
			throw new DomainException(message = "No se puede sacar ese contenido del final del archiv")
		}
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
	var property autor
	
	method aplicarCambiosEn(carpeta){
		cambios.forEach{cambio => cambio.realizar(carpeta)}
	}
	
	method afectaA(unNombreArchivo) = cambios.any{cambio => cambio.modificaA(unNombreArchivo)}
	
	method revert() = new Commit(
		descripcion = "revert" + descripcion,
		cambios = cambios.map{unCambio=>unCambio.revertir()}.reverse(),
		autor = autor
	)
	
}

class Cambio{
	const property nombreDelArchivo
	
	method realizar(carpeta){
		self.validarModificacion(carpeta)
		self.aplicar(carpeta)
	}
	
	method validarModificacion(carpeta) {
		if(!carpeta.contiene(nombreDelArchivo)){
			throw new DomainException(message = "La carpeta no cuenta con el archivo buscado")
		}
	} 
	
	method aplicar(carpeta)
	
	method modificaA(unNombreArchivo) = nombreDelArchivo == unNombreArchivo
}

class Crear inherits Cambio{
	
	override method validarModificacion(carpeta) {
		if(carpeta.contiene(nombreDelArchivo)){
			throw new DomainException(message = "La carpeta ya cuenta con un archivo con es enombre")
		}
	} 
	
	override method aplicar(carpeta){
		carpeta.agregar(nombreDelArchivo)
		
	}
	
	method revertir() = new Eliminar(nombreDelArchivo = nombreDelArchivo)
}

class Eliminar inherits Cambio{
	
	override method aplicar(carpeta){
		carpeta.eliminar(nombreDelArchivo)
	}
	
	method revertir() = new Crear(nombreDelArchivo = nombreDelArchivo)
	
}

class Agregar inherits Cambio{
	const contenidoAAgregar
	
	override method aplicar(carpeta){
		carpeta.buscar(nombreDelArchivo).agregarContenido(contenidoAAgregar)
		}
		
	method revertir() = new Sacar(nombreDelArchivo = nombreDelArchivo, quitarContenido = contenidoAAgregar)
}

class Sacar inherits Cambio{
	const quitarContenido
	
	override method aplicar(carpeta){
		carpeta.buscar(nombreDelArchivo).eliminarContenido(quitarContenido)
	}
	
	method revertir() = new Agregar(nombreDelArchivo = nombreDelArchivo, contenidoAAgregar = quitarContenido)

}

// BRANCHES
class Branch{
	var property commits = []
	var colaboradores = []
	
	method checkoutEn(unaCarpeta) {
		commits.forEach{commit => commit.aplicarCambiosEn(unaCarpeta)}
	}
	
	method logDe(unNombreArchivo) = commits.filter{commit => commit.afectaA(unNombreArchivo)}
	
	
	method autorizarCommitDe(usuario) {
		if(!usuario.tienePermisoParCommitearEn(self)){
			throw new DomainException(message = "No tiene los permisos necesarios")
		}
	}
	
	method esColaborador(usuario) = colaboradores.contains(usuario) 
	
	method agregarColaborador(usuario){
		colaboradores.add(usuario)
	}
	
	method blame(nombreDeArchivo) = self.logDe(nombreDeArchivo).map{commit => commit.autor()}.asSet()
	
	method agregarCommit(commit){
		commits.add(commit)
	}

}
//USUARIOS

class Usuario{
	var property rol
	
	method crearBranch() = new Branch(colaboradores = [self])
	
	method tienePermisoParaCommitearEn(branch) {
		if(!rol.tienePermisosNecesariosEn(branch,self)){
			throw new DomainException(message="No tiene permisos para commitear")
		}
	} 
	method cambiarRol(rolNuevo){
		rol = rolNuevo
	}
	
	method commitear(commit, branch){
		self.tienePermisoParaCommitearEn(branch)
		commit.autor(self)
		branch.agregarCommit(commit)
	}
	
	method convertirEnAdmin(usuarios){
		usuarios.forEach{usuario => usuario.rol(administrador)}
	}
	
	method quitarPermisoAdmin(usuario){
		rol.modificarPermiso(usuario,comun)
	}
	


}

object administrador{
	
	method tienePermisosNecesariosEn(branch, usuario) = true
	
	method cambiarRoles(usuarios, rol){
		usuarios.forEach{usuario => usuario.cambiarRol(rol)}
	}
	
	method modificarPermiso(usuario, unRol){
		usuario.rol(unRol)
	}
}

object comun{
	
	method tienePermisosNecesariosEn(branch, usuario) = branch.esColaborador(usuario)
	
	method modificarPermiso(usuario, unRol){
		throw new DomainException(message="no tiene permiso para modificar rol")
	}
}

object bot{
	
	method tienePermisosNecesariosEn(branch, usuario) = branch.commits().size() > 10 && branch.esColaborador(usuario)
	
	method modificarPermiso(usuario, unRol){
		throw new DomainException(message="no tiene permiso para modificar rol")
	}
}

