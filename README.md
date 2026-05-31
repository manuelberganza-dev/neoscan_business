# NeoScan Business

App movil Flutter para operaciones rapidas de Neo Business: caja POS,
escaneo, inventario, notificaciones, estadisticas y trabajo offline.

## Pantallas principales

**Login**

Permite iniciar sesion con un usuario del backend. La app guarda el token y lo
usa para consultar ventas, productos, caja, inventario y notificaciones.

**Inicio**

Muestra el resumen operativo del dia:

- ventas totales del dia
- cantidad de tickets
- impuesto acumulado
- productos con stock bajo
- ventas agrupadas por hora
- totales por metodo de pago
- feed de ventas en vivo

Tambien muestra un badge con notificaciones sin leer.

**POS**

Sirve para vender rapido. Desde aqui se puede buscar o escanear productos,
agregarlos al carrito, cobrar y registrar la venta. Si no hay caja abierta, la
app manda a la pantalla de abrir caja. Al volver desde esa pantalla se regresa
al Inicio para no cerrar la app accidentalmente.

**Abrir / cerrar caja**

Permite abrir caja con monto inicial y cerrar caja al final del turno. La caja
activa se usa para las ventas POS.

**Inventario**

Permite consultar existencias por bodega, registrar ajustes y hacer
transferencias entre bodegas.

**Escaner**

Escaner fullscreen con camara, linterna y modo continuo. Consulta el backend por
codigo de barras y muestra producto, precio y stock.

**OCR de factura**

Pantalla de desarrollo para tomar una foto o elegir una imagen de factura desde
galeria. La app manda la imagen al backend y muestra abajo la respuesta JSON
para validar la lectura. El proveedor OCR se resuelve del lado servidor para no
exponer llaves ni depender del cliente movil.

**Notificaciones**

Lista las notificaciones del backend y permite marcarlas como leidas. Ademas,
recibe eventos en vivo por Action Cable.

## Modo offline

Si el telefono pierde conexion, la app muestra un indicador de modo offline.
Las ventas, ajustes y transferencias se guardan en una cola local SQLite
(Drift). Cuando vuelve la conexion, la app intenta sincronizar automaticamente
los pendientes con el backend.

## Configuracion local

Para usar el backend local desde un telefono Android conectado por USB:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
flutter run --dart-define-from-file=.env
```

Si desconectas el telefono o reinicias `adb`, vuelve a ejecutar `adb reverse`.
Para este modo, `API_BASE_URL` puede quedarse en `http://127.0.0.1:3000/api/v1`
porque el reverse redirige ese puerto del telefono hacia tu PC.

`.env` no se sube a git. Usa `.env.example` como plantilla.

## OCR de facturas de El Salvador

La pantalla sube la imagen a `POST /mobile/ocr_invoice` como multipart con el
campo `image`. Durante desarrollo, la respuesta esperada del backend debe ser
JSON valido con esta forma:

```json
{
  "document_type": "CCF | Factura | Ticket | DTE | Otro",
  "document_number": null,
  "control_number": null,
  "generation_code": null,
  "issued_at": null,
  "supplier": {
    "name": null,
    "nit": null,
    "nrc": null,
    "activity": null,
    "address": null
  },
  "customer": {
    "name": null,
    "nit": null,
    "nrc": null
  },
  "currency": "USD",
  "subtotal": 0,
  "tax": 0,
  "discount": 0,
  "total": 0,
  "items": [
    {
      "description": null,
      "quantity": 0,
      "unit_price": 0,
      "tax_rate": 0.13,
      "total": 0
    }
  ],
  "confidence": 0,
  "warnings": []
}
```

La pantalla OCR muestra este JSON directamente para poder revisar rapidamente si
la lectura de proveedor, documento, montos e items es correcta.
