
# App de demostración donde mejoramos considerablemete la app de Apple Scrumdinger #

* En esta iteración de la app se ha añadido la capacidad de transcribir lo que hablamos en la reunión, y también la persistencia, al añadir esto sin controlar las dependencias, hemos perdido la capacidad de ver en la vista previa como progresa el contador de tiempo, el framework de Apple Speech no funciona en la vista previa, esto también nos ocasiona que no podamos hacer pruebas sobre el código, aparte también hemos perdido la capacidad de inyectar datos en el arranque cosa que venia muy bien, y nos permitía cargar datos en sobre la preview.

* Todo esto lo solucionaremos en la próxima interación.

## ¿Que hay de nuevo viejo? ##

* Hemos añadido una nueva librería para gestionar dependencias, ahora podemos hacer que el contador pase de forma inmediata cuando hacemos test, mientra que sigue funcionando igual en producción, esto nos permite agilizar los test y hacerlos posibles, algo que no era tan fácil sin el uso de la nueva librería "swift-dependencies"

* Para la próxima intentaremos mejorar las pruebas de persistencias ya que la versión actual hace un grabado real en el simulador, cuando tiramos las pruebas, también vamos a crear una dependencia controlada, para poder probar la parte de la app que hace uso del Framework Speech.

* Pues esta sería la última iteración para terminar la app, aún se pueden añadir algunas pruebas más, pero como demostración es suficiente, lo próximo será reescribir esta misma app, pero esta vez usando la arquitectura [TCA](https://github.com/pointfreeco/swift-composable-architecture)

Nos vemos pronto ;)



