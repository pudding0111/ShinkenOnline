// Returns whether the `js-string` built-in is supported.
function detectJsStringBuiltins() {
  let bytes = [
    0,   97,  115, 109, 1,   0,   0,  0,   1,   4,   1,   96,  0,
    0,   2,   23,  1,   14,  119, 97, 115, 109, 58,  106, 115, 45,
    115, 116, 114, 105, 110, 103, 4,  99,  97,  115, 116, 0,   0
  ];
  return WebAssembly.validate(
    new Uint8Array(bytes), {builtins: ['js-string']});
}

// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = detectJsStringBuiltins()
      ? {builtins: ['js-string']} : {};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = detectJsStringBuiltins()
      ? {builtins: ['js-string']} : {};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  async instantiate(additionalImports, {loadDeferredWasm} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
      const exports = dartInstance.exports;
      const read = exports.$listRead;
      const length = exports.$listLength(list);
      const array = new constructor(length);
      for (let i = 0; i < length; i++) {
        array[i] = read(list, i);
      }
      return array;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {

      _1: (x0,x1,x2) => x0.set(x1,x2),
      _2: (x0,x1,x2) => x0.set(x1,x2),
      _6: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._6(f,arguments.length,x0) }),
      _7: x0 => new window.FinalizationRegistry(x0),
      _8: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _9: (x0,x1) => x0.unregister(x1),
      _10: (x0,x1,x2) => x0.slice(x1,x2),
      _11: (x0,x1) => x0.decode(x1),
      _12: (x0,x1) => x0.segment(x1),
      _13: () => new TextDecoder(),
      _14: x0 => x0.buffer,
      _15: x0 => x0.wasmMemory,
      _16: () => globalThis.window._flutter_skwasmInstance,
      _17: x0 => x0.rasterStartMilliseconds,
      _18: x0 => x0.rasterEndMilliseconds,
      _19: x0 => x0.imageBitmaps,
      _192: x0 => x0.select(),
      _193: (x0,x1) => x0.append(x1),
      _194: x0 => x0.remove(),
      _197: x0 => x0.unlock(),
      _202: x0 => x0.getReader(),
      _211: x0 => new MutationObserver(x0),
      _222: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _223: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _226: x0 => new ResizeObserver(x0),
      _229: (x0,x1) => new Intl.Segmenter(x0,x1),
      _230: x0 => x0.next(),
      _231: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _308: x0 => x0.close(),
      _309: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _310: x0 => new window.ImageDecoder(x0),
      _311: x0 => x0.close(),
      _312: x0 => ({frameIndex: x0}),
      _313: (x0,x1) => x0.decode(x1),
      _316: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._316(f,arguments.length,x0) }),
      _317: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._317(f,arguments.length,x0) }),
      _318: (x0,x1) => ({addView: x0,removeView: x1}),
      _319: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._319(f,arguments.length,x0) }),
      _320: f => finalizeWrapper(f, function() { return dartInstance.exports._320(f,arguments.length) }),
      _321: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _322: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._322(f,arguments.length,x0) }),
      _323: x0 => ({runApp: x0}),
      _324: x0 => new Uint8Array(x0),
      _326: x0 => x0.preventDefault(),
      _327: x0 => x0.stopPropagation(),
      _328: (x0,x1) => x0.addListener(x1),
      _329: (x0,x1) => x0.removeListener(x1),
      _330: (x0,x1) => x0.prepend(x1),
      _331: x0 => x0.remove(),
      _332: x0 => x0.disconnect(),
      _333: (x0,x1) => x0.addListener(x1),
      _334: (x0,x1) => x0.removeListener(x1),
      _336: (x0,x1) => x0.append(x1),
      _337: x0 => x0.remove(),
      _338: x0 => x0.stopPropagation(),
      _342: x0 => x0.preventDefault(),
      _343: (x0,x1) => x0.append(x1),
      _344: x0 => x0.remove(),
      _345: x0 => x0.preventDefault(),
      _350: (x0,x1) => x0.removeChild(x1),
      _351: (x0,x1) => x0.appendChild(x1),
      _352: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _353: (x0,x1) => x0.appendChild(x1),
      _354: (x0,x1) => x0.transferFromImageBitmap(x1),
      _355: (x0,x1) => x0.appendChild(x1),
      _356: (x0,x1) => x0.append(x1),
      _357: (x0,x1) => x0.append(x1),
      _358: (x0,x1) => x0.append(x1),
      _359: x0 => x0.remove(),
      _360: x0 => x0.remove(),
      _361: x0 => x0.remove(),
      _362: (x0,x1) => x0.appendChild(x1),
      _363: (x0,x1) => x0.appendChild(x1),
      _364: x0 => x0.remove(),
      _365: (x0,x1) => x0.append(x1),
      _366: (x0,x1) => x0.append(x1),
      _367: x0 => x0.remove(),
      _368: (x0,x1) => x0.append(x1),
      _369: (x0,x1) => x0.append(x1),
      _370: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _371: (x0,x1) => x0.append(x1),
      _372: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _373: x0 => x0.remove(),
      _374: x0 => x0.remove(),
      _375: (x0,x1) => x0.append(x1),
      _376: x0 => x0.remove(),
      _377: (x0,x1) => x0.append(x1),
      _378: x0 => x0.remove(),
      _379: x0 => x0.remove(),
      _380: x0 => x0.getBoundingClientRect(),
      _381: x0 => x0.remove(),
      _394: (x0,x1) => x0.append(x1),
      _395: x0 => x0.remove(),
      _396: (x0,x1) => x0.append(x1),
      _397: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _398: x0 => x0.preventDefault(),
      _399: x0 => x0.preventDefault(),
      _400: x0 => x0.preventDefault(),
      _401: x0 => x0.preventDefault(),
      _402: x0 => x0.remove(),
      _403: (x0,x1) => x0.observe(x1),
      _404: x0 => x0.disconnect(),
      _405: (x0,x1) => x0.appendChild(x1),
      _406: (x0,x1) => x0.appendChild(x1),
      _407: (x0,x1) => x0.appendChild(x1),
      _408: (x0,x1) => x0.append(x1),
      _409: x0 => x0.remove(),
      _410: (x0,x1) => x0.append(x1),
      _411: (x0,x1) => x0.append(x1),
      _412: (x0,x1) => x0.appendChild(x1),
      _413: (x0,x1) => x0.append(x1),
      _414: x0 => x0.remove(),
      _415: (x0,x1) => x0.append(x1),
      _419: (x0,x1) => x0.appendChild(x1),
      _420: x0 => x0.remove(),
      _976: () => globalThis.window.flutterConfiguration,
      _977: x0 => x0.assetBase,
      _982: x0 => x0.debugShowSemanticsNodes,
      _983: x0 => x0.hostElement,
      _984: x0 => x0.multiViewEnabled,
      _985: x0 => x0.nonce,
      _987: x0 => x0.fontFallbackBaseUrl,
      _988: x0 => x0.useColorEmoji,
      _992: x0 => x0.console,
      _993: x0 => x0.devicePixelRatio,
      _994: x0 => x0.document,
      _995: x0 => x0.history,
      _996: x0 => x0.innerHeight,
      _997: x0 => x0.innerWidth,
      _998: x0 => x0.location,
      _999: x0 => x0.navigator,
      _1000: x0 => x0.visualViewport,
      _1001: x0 => x0.performance,
      _1004: (x0,x1) => x0.dispatchEvent(x1),
      _1005: (x0,x1) => x0.matchMedia(x1),
      _1007: (x0,x1) => x0.getComputedStyle(x1),
      _1008: x0 => x0.screen,
      _1009: (x0,x1) => x0.requestAnimationFrame(x1),
      _1010: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1010(f,arguments.length,x0) }),
      _1014: (x0,x1) => x0.warn(x1),
      _1016: (x0,x1) => x0.debug(x1),
      _1017: () => globalThis.window,
      _1018: () => globalThis.Intl,
      _1019: () => globalThis.Symbol,
      _1022: x0 => x0.clipboard,
      _1023: x0 => x0.maxTouchPoints,
      _1024: x0 => x0.vendor,
      _1025: x0 => x0.language,
      _1026: x0 => x0.platform,
      _1027: x0 => x0.userAgent,
      _1028: x0 => x0.languages,
      _1029: x0 => x0.documentElement,
      _1030: (x0,x1) => x0.querySelector(x1),
      _1034: (x0,x1) => x0.createElement(x1),
      _1035: (x0,x1) => x0.execCommand(x1),
      _1039: (x0,x1) => x0.createTextNode(x1),
      _1040: (x0,x1) => x0.createEvent(x1),
      _1044: x0 => x0.head,
      _1045: x0 => x0.body,
      _1046: (x0,x1) => x0.title = x1,
      _1049: x0 => x0.activeElement,
      _1052: x0 => x0.visibilityState,
      _1053: x0 => x0.hasFocus(),
      _1054: () => globalThis.document,
      _1055: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1057: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1060: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1060(f,arguments.length,x0) }),
      _1061: x0 => x0.target,
      _1063: x0 => x0.timeStamp,
      _1064: x0 => x0.type,
      _1066: x0 => x0.preventDefault(),
      _1068: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _1074: x0 => x0.baseURI,
      _1075: x0 => x0.firstChild,
      _1080: x0 => x0.parentElement,
      _1082: x0 => x0.parentNode,
      _1085: (x0,x1) => x0.removeChild(x1),
      _1086: (x0,x1) => x0.removeChild(x1),
      _1087: x0 => x0.isConnected,
      _1088: (x0,x1) => x0.textContent = x1,
      _1090: (x0,x1) => x0.contains(x1),
      _1095: x0 => x0.firstElementChild,
      _1097: x0 => x0.nextElementSibling,
      _1098: x0 => x0.clientHeight,
      _1099: x0 => x0.clientWidth,
      _1100: x0 => x0.offsetHeight,
      _1101: x0 => x0.offsetWidth,
      _1102: x0 => x0.id,
      _1103: (x0,x1) => x0.id = x1,
      _1106: (x0,x1) => x0.spellcheck = x1,
      _1107: x0 => x0.tagName,
      _1108: x0 => x0.style,
      _1109: (x0,x1) => x0.append(x1),
      _1110: (x0,x1) => x0.getAttribute(x1),
      _1111: x0 => x0.getBoundingClientRect(),
      _1116: (x0,x1) => x0.closest(x1),
      _1119: (x0,x1) => x0.querySelectorAll(x1),
      _1121: x0 => x0.remove(),
      _1122: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1123: (x0,x1) => x0.removeAttribute(x1),
      _1124: (x0,x1) => x0.tabIndex = x1,
      _1126: (x0,x1) => x0.focus(x1),
      _1127: x0 => x0.scrollTop,
      _1128: (x0,x1) => x0.scrollTop = x1,
      _1129: x0 => x0.scrollLeft,
      _1130: (x0,x1) => x0.scrollLeft = x1,
      _1131: x0 => x0.classList,
      _1132: (x0,x1) => x0.className = x1,
      _1139: (x0,x1) => x0.getElementsByClassName(x1),
      _1141: x0 => x0.click(),
      _1143: (x0,x1) => x0.hasAttribute(x1),
      _1146: (x0,x1) => x0.attachShadow(x1),
      _1151: (x0,x1) => x0.getPropertyValue(x1),
      _1153: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _1155: (x0,x1) => x0.removeProperty(x1),
      _1157: x0 => x0.offsetLeft,
      _1158: x0 => x0.offsetTop,
      _1159: x0 => x0.offsetParent,
      _1161: (x0,x1) => x0.name = x1,
      _1162: x0 => x0.content,
      _1163: (x0,x1) => x0.content = x1,
      _1177: (x0,x1) => x0.nonce = x1,
      _1183: x0 => x0.now(),
      _1185: (x0,x1) => x0.width = x1,
      _1187: (x0,x1) => x0.height = x1,
      _1191: (x0,x1) => x0.getContext(x1),
      _1267: (x0,x1) => x0.fetch(x1),
      _1268: x0 => x0.status,
      _1269: x0 => x0.headers,
      _1270: x0 => x0.body,
      _1271: x0 => x0.arrayBuffer(),
      _1274: (x0,x1) => x0.get(x1),
      _1277: x0 => x0.read(),
      _1278: x0 => x0.value,
      _1279: x0 => x0.done,
      _1281: x0 => x0.name,
      _1282: x0 => x0.x,
      _1283: x0 => x0.y,
      _1286: x0 => x0.top,
      _1287: x0 => x0.right,
      _1288: x0 => x0.bottom,
      _1289: x0 => x0.left,
      _1299: x0 => x0.height,
      _1300: x0 => x0.width,
      _1301: (x0,x1) => x0.value = x1,
      _1303: (x0,x1) => x0.placeholder = x1,
      _1304: (x0,x1) => x0.name = x1,
      _1305: x0 => x0.selectionDirection,
      _1306: x0 => x0.selectionStart,
      _1307: x0 => x0.selectionEnd,
      _1310: x0 => x0.value,
      _1312: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1315: x0 => x0.readText(),
      _1316: (x0,x1) => x0.writeText(x1),
      _1317: x0 => x0.altKey,
      _1318: x0 => x0.code,
      _1319: x0 => x0.ctrlKey,
      _1320: x0 => x0.key,
      _1321: x0 => x0.keyCode,
      _1322: x0 => x0.location,
      _1323: x0 => x0.metaKey,
      _1324: x0 => x0.repeat,
      _1325: x0 => x0.shiftKey,
      _1326: x0 => x0.isComposing,
      _1327: (x0,x1) => x0.getModifierState(x1),
      _1329: x0 => x0.state,
      _1330: (x0,x1) => x0.go(x1),
      _1333: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _1334: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1335: x0 => x0.pathname,
      _1336: x0 => x0.search,
      _1337: x0 => x0.hash,
      _1341: x0 => x0.state,
      _1347: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1347(f,arguments.length,x0,x1) }),
      _1350: (x0,x1,x2) => x0.observe(x1,x2),
      _1353: x0 => x0.attributeName,
      _1354: x0 => x0.type,
      _1355: x0 => x0.matches,
      _1358: x0 => x0.matches,
      _1360: x0 => x0.relatedTarget,
      _1361: x0 => x0.clientX,
      _1362: x0 => x0.clientY,
      _1363: x0 => x0.offsetX,
      _1364: x0 => x0.offsetY,
      _1367: x0 => x0.button,
      _1368: x0 => x0.buttons,
      _1369: x0 => x0.ctrlKey,
      _1370: (x0,x1) => x0.getModifierState(x1),
      _1373: x0 => x0.pointerId,
      _1374: x0 => x0.pointerType,
      _1375: x0 => x0.pressure,
      _1376: x0 => x0.tiltX,
      _1377: x0 => x0.tiltY,
      _1378: x0 => x0.getCoalescedEvents(),
      _1380: x0 => x0.deltaX,
      _1381: x0 => x0.deltaY,
      _1382: x0 => x0.wheelDeltaX,
      _1383: x0 => x0.wheelDeltaY,
      _1384: x0 => x0.deltaMode,
      _1390: x0 => x0.changedTouches,
      _1392: x0 => x0.clientX,
      _1393: x0 => x0.clientY,
      _1395: x0 => x0.data,
      _1398: (x0,x1) => x0.disabled = x1,
      _1399: (x0,x1) => x0.type = x1,
      _1400: (x0,x1) => x0.max = x1,
      _1401: (x0,x1) => x0.min = x1,
      _1402: (x0,x1) => x0.value = x1,
      _1403: x0 => x0.value,
      _1404: x0 => x0.disabled,
      _1405: (x0,x1) => x0.disabled = x1,
      _1406: (x0,x1) => x0.placeholder = x1,
      _1407: (x0,x1) => x0.name = x1,
      _1408: (x0,x1) => x0.autocomplete = x1,
      _1409: x0 => x0.selectionDirection,
      _1410: x0 => x0.selectionStart,
      _1411: x0 => x0.selectionEnd,
      _1415: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1420: (x0,x1) => x0.add(x1),
      _1423: (x0,x1) => x0.noValidate = x1,
      _1424: (x0,x1) => x0.method = x1,
      _1425: (x0,x1) => x0.action = x1,
      _1450: x0 => x0.orientation,
      _1451: x0 => x0.width,
      _1452: x0 => x0.height,
      _1453: (x0,x1) => x0.lock(x1),
      _1471: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1471(f,arguments.length,x0,x1) }),
      _1482: x0 => x0.length,
      _1483: (x0,x1) => x0.item(x1),
      _1484: x0 => x0.length,
      _1485: (x0,x1) => x0.item(x1),
      _1486: x0 => x0.iterator,
      _1487: x0 => x0.Segmenter,
      _1488: x0 => x0.v8BreakIterator,
      _1492: x0 => x0.done,
      _1493: x0 => x0.value,
      _1494: x0 => x0.index,
      _1498: (x0,x1) => x0.adoptText(x1),
      _1499: x0 => x0.first(),
      _1500: x0 => x0.next(),
      _1501: x0 => x0.current(),
      _1512: x0 => x0.hostElement,
      _1513: x0 => x0.viewConstraints,
      _1515: x0 => x0.maxHeight,
      _1516: x0 => x0.maxWidth,
      _1517: x0 => x0.minHeight,
      _1518: x0 => x0.minWidth,
      _1519: x0 => x0.loader,
      _1520: () => globalThis._flutter,
      _1521: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1522: (x0,x1,x2) => x0.call(x1,x2),
      _1523: () => globalThis.Promise,
      _1524: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1524(f,arguments.length,x0,x1) }),
      _1527: x0 => x0.length,
      _1530: x0 => x0.tracks,
      _1534: x0 => x0.image,
      _1539: x0 => x0.codedWidth,
      _1540: x0 => x0.codedHeight,
      _1543: x0 => x0.duration,
      _1547: x0 => x0.ready,
      _1548: x0 => x0.selectedTrack,
      _1549: x0 => x0.repetitionCount,
      _1550: x0 => x0.frameCount,
      _1595: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1595(f,arguments.length,x0) }),
      _1596: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1597: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1598: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _1599: (x0,x1) => x0.querySelectorAll(x1),
      _1600: (x0,x1) => x0.removeChild(x1),
      _1601: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1601(f,arguments.length,x0) }),
      _1602: (x0,x1) => x0.forEach(x1),
      _1603: x0 => x0.preventDefault(),
      _1604: x0 => x0.preventDefault(),
      _1605: x0 => x0.preventDefault(),
      _1606: (x0,x1) => x0.item(x1),
      _1607: () => new FileReader(),
      _1608: (x0,x1) => x0.readAsText(x1),
      _1609: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1609(f,arguments.length,x0) }),
      _1610: () => globalThis.initializeGA(),
      _1612: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33) => ({screen: x0,event_category: x1,event_label: x2,send_to: x3,value: x4,non_interaction: x5,user_app: x6,user_build: x7,user_platform: x8,devtools_platform: x9,devtools_chrome: x10,devtools_version: x11,ide_launched: x12,flutter_client_id: x13,is_external_build: x14,is_embedded: x15,g3_username: x16,ide_launched_feature: x17,is_wasm: x18,ui_duration_micros: x19,raster_duration_micros: x20,shader_compilation_duration_micros: x21,cpu_sample_count: x22,cpu_stack_depth: x23,trace_event_count: x24,heap_diff_objects_before: x25,heap_diff_objects_after: x26,heap_objects_total: x27,root_set_count: x28,row_count: x29,inspector_tree_controller_id: x30,android_app_id: x31,ios_bundle_id: x32,is_v2_inspector: x33}),
      _1613: x0 => x0.screen,
      _1614: x0 => x0.user_app,
      _1615: x0 => x0.user_build,
      _1616: x0 => x0.user_platform,
      _1617: x0 => x0.devtools_platform,
      _1618: x0 => x0.devtools_chrome,
      _1619: x0 => x0.devtools_version,
      _1620: x0 => x0.ide_launched,
      _1622: x0 => x0.is_external_build,
      _1623: x0 => x0.is_embedded,
      _1624: x0 => x0.g3_username,
      _1625: x0 => x0.ide_launched_feature,
      _1626: x0 => x0.is_wasm,
      _1627: x0 => x0.ui_duration_micros,
      _1628: x0 => x0.raster_duration_micros,
      _1629: x0 => x0.shader_compilation_duration_micros,
      _1630: x0 => x0.cpu_sample_count,
      _1631: x0 => x0.cpu_stack_depth,
      _1632: x0 => x0.trace_event_count,
      _1633: x0 => x0.heap_diff_objects_before,
      _1634: x0 => x0.heap_diff_objects_after,
      _1635: x0 => x0.heap_objects_total,
      _1636: x0 => x0.root_set_count,
      _1637: x0 => x0.row_count,
      _1638: x0 => x0.inspector_tree_controller_id,
      _1639: x0 => x0.android_app_id,
      _1640: x0 => x0.ios_bundle_id,
      _1641: x0 => x0.is_v2_inspector,
      _1643: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29) => ({description: x0,fatal: x1,user_app: x2,user_build: x3,user_platform: x4,devtools_platform: x5,devtools_chrome: x6,devtools_version: x7,ide_launched: x8,flutter_client_id: x9,is_external_build: x10,is_embedded: x11,g3_username: x12,ide_launched_feature: x13,is_wasm: x14,ui_duration_micros: x15,raster_duration_micros: x16,shader_compilation_duration_micros: x17,cpu_sample_count: x18,cpu_stack_depth: x19,trace_event_count: x20,heap_diff_objects_before: x21,heap_diff_objects_after: x22,heap_objects_total: x23,root_set_count: x24,row_count: x25,inspector_tree_controller_id: x26,android_app_id: x27,ios_bundle_id: x28,is_v2_inspector: x29}),
      _1644: x0 => x0.user_app,
      _1645: x0 => x0.user_build,
      _1646: x0 => x0.user_platform,
      _1647: x0 => x0.devtools_platform,
      _1648: x0 => x0.devtools_chrome,
      _1649: x0 => x0.devtools_version,
      _1650: x0 => x0.ide_launched,
      _1652: x0 => x0.is_external_build,
      _1653: x0 => x0.is_embedded,
      _1654: x0 => x0.g3_username,
      _1655: x0 => x0.ide_launched_feature,
      _1656: x0 => x0.is_wasm,
      _1672: () => globalThis.getDevToolsPropertyID(),
      _1673: () => globalThis.getDevToolsPropertyID(),
      _1674: () => globalThis.getDevToolsPropertyID(),
      _1675: () => globalThis.getDevToolsPropertyID(),
      _1677: () => globalThis.hookupListenerForGA(),
      _1678: (x0,x1,x2) => globalThis.gtag(x0,x1,x2),
      _1680: x0 => x0.event_category,
      _1681: x0 => x0.event_label,
      _1683: x0 => x0.value,
      _1684: x0 => x0.non_interaction,
      _1687: x0 => x0.description,
      _1688: x0 => x0.fatal,
      _1689: (x0,x1) => x0.createElement(x1),
      _1690: x0 => new Blob(x0),
      _1691: x0 => globalThis.URL.createObjectURL(x0),
      _1692: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1693: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1694: (x0,x1) => x0.append(x1),
      _1695: x0 => x0.click(),
      _1696: x0 => x0.remove(),
      _1697: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1698: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1699: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1699(f,arguments.length,x0) }),
      _1700: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1701: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1701(f,arguments.length,x0) }),
      _1702: x0 => x0.send(),
      _1703: () => new XMLHttpRequest(),
      _1705: x0 => x0.createRange(),
      _1706: (x0,x1) => x0.selectNode(x1),
      _1707: x0 => x0.getSelection(),
      _1708: x0 => x0.removeAllRanges(),
      _1709: (x0,x1) => x0.addRange(x1),
      _1710: (x0,x1) => x0.createElement(x1),
      _1711: (x0,x1) => x0.add(x1),
      _1712: (x0,x1) => x0.append(x1),
      _1713: (x0,x1,x2) => x0.insertRule(x1,x2),
      _1714: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1714(f,arguments.length,x0) }),
      _1715: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1722: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1725: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1726: (x0,x1) => x0.querySelector(x1),
      _1727: (x0,x1) => x0.appendChild(x1),
      _1728: (x0,x1) => x0.appendChild(x1),
      _1729: (x0,x1) => x0.item(x1),
      _1730: x0 => x0.remove(),
      _1731: x0 => x0.remove(),
      _1732: x0 => x0.remove(),
      _1733: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1733(f,arguments.length,x0) }),
      _1734: x0 => x0.click(),
      _1735: x0 => globalThis.URL.createObjectURL(x0),
      _1751: () => new Array(),
      _1752: x0 => new Array(x0),
      _1754: x0 => x0.length,
      _1756: (x0,x1) => x0[x1],
      _1757: (x0,x1,x2) => x0[x1] = x2,
      _1760: (x0,x1,x2) => new DataView(x0,x1,x2),
      _1762: x0 => new Int8Array(x0),
      _1763: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _1764: x0 => new Uint8Array(x0),
      _1768: x0 => new Int16Array(x0),
      _1770: x0 => new Uint16Array(x0),
      _1772: x0 => new Int32Array(x0),
      _1774: x0 => new Uint32Array(x0),
      _1776: x0 => new Float32Array(x0),
      _1778: x0 => new Float64Array(x0),
      _1779: (o, t) => typeof o === t,
      _1780: (o, c) => o instanceof c,
      _1784: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1784(f,arguments.length,x0) }),
      _1785: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1785(f,arguments.length,x0) }),
      _1811: (decoder, codeUnits) => decoder.decode(codeUnits),
      _1812: () => new TextDecoder("utf-8", {fatal: true}),
      _1813: () => new TextDecoder("utf-8", {fatal: false}),
      _1814: x0 => new WeakRef(x0),
      _1815: x0 => x0.deref(),
      _1821: Date.now,
      _1823: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1824: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1825: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1826: () => typeof dartUseDateNowForTicks !== "undefined",
      _1827: () => 1000 * performance.now(),
      _1828: () => Date.now(),
      _1829: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1830: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1831: () => new WeakMap(),
      _1832: (map, o) => map.get(o),
      _1833: (map, o, v) => map.set(o, v),
      _1834: () => globalThis.WeakRef,
      _1844: s => JSON.stringify(s),
      _1845: s => printToConsole(s),
      _1846: a => a.join(''),
      _1847: (o, a, b) => o.replace(a, b),
      _1849: (s, t) => s.split(t),
      _1850: s => s.toLowerCase(),
      _1851: s => s.toUpperCase(),
      _1852: s => s.trim(),
      _1853: s => s.trimLeft(),
      _1854: s => s.trimRight(),
      _1856: (s, p, i) => s.indexOf(p, i),
      _1857: (s, p, i) => s.lastIndexOf(p, i),
      _1858: (s) => s.replace(/\$/g, "$$$$"),
      _1859: Object.is,
      _1860: s => s.toUpperCase(),
      _1861: s => s.toLowerCase(),
      _1862: (a, i) => a.push(i),
      _1863: (a, i) => a.splice(i, 1)[0],
      _1865: (a, l) => a.length = l,
      _1866: a => a.pop(),
      _1867: (a, i) => a.splice(i, 1),
      _1869: (a, s) => a.join(s),
      _1870: (a, s, e) => a.slice(s, e),
      _1871: (a, s, e) => a.splice(s, e),
      _1872: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _1873: a => a.length,
      _1874: (a, l) => a.length = l,
      _1875: (a, i) => a[i],
      _1876: (a, i, v) => a[i] = v,
      _1878: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _1879: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _1880: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _1881: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _1882: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _1883: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _1884: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _1885: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _1887: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _1888: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _1889: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _1890: (t, s) => t.set(s),
      _1892: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _1893: o => o.byteLength,
      _1894: o => o.buffer,
      _1895: o => o.byteOffset,
      _1896: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _1897: (b, o) => new DataView(b, o),
      _1898: (b, o, l) => new DataView(b, o, l),
      _1899: Function.prototype.call.bind(DataView.prototype.getUint8),
      _1900: Function.prototype.call.bind(DataView.prototype.setUint8),
      _1901: Function.prototype.call.bind(DataView.prototype.getInt8),
      _1902: Function.prototype.call.bind(DataView.prototype.setInt8),
      _1903: Function.prototype.call.bind(DataView.prototype.getUint16),
      _1904: Function.prototype.call.bind(DataView.prototype.setUint16),
      _1905: Function.prototype.call.bind(DataView.prototype.getInt16),
      _1906: Function.prototype.call.bind(DataView.prototype.setInt16),
      _1907: Function.prototype.call.bind(DataView.prototype.getUint32),
      _1908: Function.prototype.call.bind(DataView.prototype.setUint32),
      _1909: Function.prototype.call.bind(DataView.prototype.getInt32),
      _1910: Function.prototype.call.bind(DataView.prototype.setInt32),
      _1913: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _1914: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _1915: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _1916: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1917: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1918: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1931: (o, t) => o instanceof t,
      _1933: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1933(f,arguments.length,x0) }),
      _1934: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1934(f,arguments.length,x0) }),
      _1935: o => Object.keys(o),
      _1936: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _1937: (handle) => clearTimeout(handle),
      _1938: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _1939: (handle) => clearInterval(handle),
      _1940: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _1941: () => Date.now(),
      _1942: (x0,x1) => new WebSocket(x0,x1),
      _1943: (x0,x1) => x0.send(x1),
      _1944: (x0,x1) => x0.send(x1),
      _1945: (x0,x1,x2) => x0.close(x1,x2),
      _1947: x0 => x0.close(),
      _1948: () => new XMLHttpRequest(),
      _1949: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1950: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1951: (x0,x1) => x0.send(x1),
      _1952: x0 => x0.abort(),
      _1953: x0 => x0.getAllResponseHeaders(),
      _1957: () => new XMLHttpRequest(),
      _1958: x0 => x0.send(),
      _1960: () => new FileReader(),
      _1961: (x0,x1) => x0.readAsArrayBuffer(x1),
      _1964: x0 => ({withCredentials: x0}),
      _1965: (x0,x1) => new EventSource(x0,x1),
      _1966: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1966(f,arguments.length,x0) }),
      _1967: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1967(f,arguments.length,x0) }),
      _1968: x0 => x0.close(),
      _1969: (x0,x1,x2) => ({method: x0,body: x1,credentials: x2}),
      _1970: (x0,x1,x2) => x0.fetch(x1,x2),
      _1976: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1976(f,arguments.length,x0) }),
      _1977: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1977(f,arguments.length,x0) }),
      _1987: x0 => ({body: x0}),
      _1988: (x0,x1) => new Notification(x0,x1),
      _1989: () => globalThis.Notification.requestPermission(),
      _1990: x0 => x0.close(),
      _1992: (x0,x1) => x0.groupCollapsed(x1),
      _1993: (x0,x1) => x0.log(x1),
      _1994: x0 => x0.groupEnd(),
      _1995: (x0,x1) => x0.log(x1),
      _1996: (x0,x1) => x0.warn(x1),
      _1997: (x0,x1) => x0.error(x1),
      _1998: (x0,x1) => x0.replace(x1),
      _1999: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _2000: x0 => x0.reload(),
      _2014: (x0,x1) => x0.getItem(x1),
      _2015: (x0,x1,x2) => x0.setItem(x1,x2),
      _2017: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2018: (x0,x1) => x0.exec(x1),
      _2019: (x0,x1) => x0.test(x1),
      _2020: (x0,x1) => x0.exec(x1),
      _2021: (x0,x1) => x0.exec(x1),
      _2022: x0 => x0.pop(),
      _2024: o => o === undefined,
      _2043: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2045: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2046: o => o instanceof RegExp,
      _2047: (l, r) => l === r,
      _2048: o => o,
      _2049: o => o,
      _2050: o => o,
      _2051: b => !!b,
      _2052: o => o.length,
      _2055: (o, i) => o[i],
      _2056: f => f.dartFunction,
      _2057: l => arrayFromDartList(Int8Array, l),
      _2058: l => arrayFromDartList(Uint8Array, l),
      _2059: l => arrayFromDartList(Uint8ClampedArray, l),
      _2060: l => arrayFromDartList(Int16Array, l),
      _2061: l => arrayFromDartList(Uint16Array, l),
      _2062: l => arrayFromDartList(Int32Array, l),
      _2063: l => arrayFromDartList(Uint32Array, l),
      _2064: l => arrayFromDartList(Float32Array, l),
      _2065: l => arrayFromDartList(Float64Array, l),
      _2066: x0 => new ArrayBuffer(x0),
      _2067: (data, length) => {
        const getValue = dartInstance.exports.$byteDataGetUint8;
        const view = new DataView(new ArrayBuffer(length));
        for (let i = 0; i < length; i++) {
          view.setUint8(i, getValue(data, i));
        }
        return view;
      },
      _2068: l => arrayFromDartList(Array, l),
      _2069: (s, length) => {
        if (length == 0) return '';
      
        const read = dartInstance.exports.$stringRead1;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      _2070: (s, length) => {
        if (length == 0) return '';
      
        const read = dartInstance.exports.$stringRead2;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      _2071: (s) => {
        let length = s.length;
        let range = 0;
        for (let i = 0; i < length; i++) {
          range |= s.codePointAt(i);
        }
        const exports = dartInstance.exports;
        if (range < 256) {
          if (length <= 10) {
            if (length == 1) {
              return exports.$stringAllocate1_1(s.codePointAt(0));
            }
            if (length == 2) {
              return exports.$stringAllocate1_2(s.codePointAt(0), s.codePointAt(1));
            }
            if (length == 3) {
              return exports.$stringAllocate1_3(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2));
            }
            if (length == 4) {
              return exports.$stringAllocate1_4(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3));
            }
            if (length == 5) {
              return exports.$stringAllocate1_5(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4));
            }
            if (length == 6) {
              return exports.$stringAllocate1_6(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5));
            }
            if (length == 7) {
              return exports.$stringAllocate1_7(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6));
            }
            if (length == 8) {
              return exports.$stringAllocate1_8(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7));
            }
            if (length == 9) {
              return exports.$stringAllocate1_9(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8));
            }
            if (length == 10) {
              return exports.$stringAllocate1_10(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8), s.codePointAt(9));
            }
          }
          const dartString = exports.$stringAllocate1(length);
          const write = exports.$stringWrite1;
          for (let i = 0; i < length; i++) {
            write(dartString, i, s.codePointAt(i));
          }
          return dartString;
        } else {
          const dartString = exports.$stringAllocate2(length);
          const write = exports.$stringWrite2;
          for (let i = 0; i < length; i++) {
            write(dartString, i, s.charCodeAt(i));
          }
          return dartString;
        }
      },
      _2072: () => ({}),
      _2073: () => [],
      _2074: l => new Array(l),
      _2075: () => globalThis,
      _2076: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2077: (o, p) => p in o,
      _2078: (o, p) => o[p],
      _2079: (o, p, v) => o[p] = v,
      _2080: (o, m, a) => o[m].apply(o, a),
      _2082: o => String(o),
      _2083: (p, s, f) => p.then(s, f),
      _2084: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        return 17;
      },
      _2085: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2086: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2087: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2088: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2089: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2090: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2091: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2092: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2093: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2094: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2095: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2097: x0 => x0.input,
      _2098: x0 => x0.index,
      _2099: x0 => x0.groups,
      _2102: (x0,x1) => x0.exec(x1),
      _2104: x0 => x0.flags,
      _2105: x0 => x0.multiline,
      _2106: x0 => x0.ignoreCase,
      _2107: x0 => x0.unicode,
      _2108: x0 => x0.dotAll,
      _2109: (x0,x1) => x0.lastIndex = x1,
      _2111: (o, p) => o[p],
      _2114: v => v.toString(),
      _2115: (d, digits) => d.toFixed(digits),
      _2118: (d, precision) => d.toPrecision(precision),
      _2119: x0 => x0.random(),
      _2120: x0 => x0.random(),
      _2124: () => globalThis.Math,
      _2126: () => globalThis.document,
      _2127: () => globalThis.window,
      _2132: (x0,x1) => x0.height = x1,
      _2134: (x0,x1) => x0.width = x1,
      _2138: x0 => x0.head,
      _2140: x0 => x0.classList,
      _2145: (x0,x1) => x0.innerText = x1,
      _2146: x0 => x0.style,
      _2147: x0 => x0.sheet,
      _2149: x0 => x0.offsetX,
      _2150: x0 => x0.offsetY,
      _2151: x0 => x0.button,
      _2164: x0 => x0.status,
      _2165: (x0,x1) => x0.responseType = x1,
      _2167: x0 => x0.response,
      _2219: (x0,x1) => x0.withCredentials = x1,
      _2221: x0 => x0.responseURL,
      _2222: x0 => x0.status,
      _2223: x0 => x0.statusText,
      _2225: (x0,x1) => x0.responseType = x1,
      _2226: x0 => x0.response,
      _2306: x0 => x0.style,
      _2784: (x0,x1) => x0.src = x1,
      _2791: (x0,x1) => x0.allow = x1,
      _2803: x0 => x0.contentWindow,
      _3238: (x0,x1) => x0.accept = x1,
      _3252: x0 => x0.files,
      _3278: (x0,x1) => x0.multiple = x1,
      _3296: (x0,x1) => x0.type = x1,
      _4017: (x0,x1) => x0.dropEffect = x1,
      _4022: x0 => x0.files,
      _4034: x0 => x0.dataTransfer,
      _4038: () => globalThis.window,
      _4083: x0 => x0.location,
      _4084: x0 => x0.history,
      _4100: x0 => x0.parent,
      _4102: x0 => x0.navigator,
      _4366: x0 => x0.localStorage,
      _4376: x0 => x0.origin,
      _4385: x0 => x0.pathname,
      _4400: x0 => x0.state,
      _4425: x0 => x0.message,
      _4488: x0 => x0.appVersion,
      _4489: x0 => x0.platform,
      _4492: x0 => x0.userAgent,
      _4493: x0 => x0.vendor,
      _4543: x0 => x0.data,
      _4544: x0 => x0.origin,
      _4932: x0 => x0.readyState,
      _4941: x0 => x0.protocol,
      _4945: (x0,x1) => x0.binaryType = x1,
      _4948: x0 => x0.code,
      _4949: x0 => x0.reason,
      _6692: x0 => x0.type,
      _6800: x0 => x0.parentNode,
      _6814: () => globalThis.document,
      _6907: x0 => x0.body,
      _7618: x0 => x0.offsetX,
      _7619: x0 => x0.offsetY,
      _7704: x0 => x0.key,
      _7705: x0 => x0.code,
      _7706: x0 => x0.location,
      _7707: x0 => x0.ctrlKey,
      _7708: x0 => x0.shiftKey,
      _7709: x0 => x0.altKey,
      _7710: x0 => x0.metaKey,
      _7711: x0 => x0.repeat,
      _7712: x0 => x0.isComposing,
      _8827: x0 => x0.size,
      _8828: x0 => x0.type,
      _8835: x0 => x0.name,
      _8836: x0 => x0.lastModified,
      _8842: x0 => x0.length,
      _8853: x0 => x0.result,
      _11477: (x0,x1) => x0.backgroundColor = x1,
      _11523: (x0,x1) => x0.border = x1,
      _11801: (x0,x1) => x0.display = x1,
      _11965: (x0,x1) => x0.height = x1,
      _12655: (x0,x1) => x0.width = x1,
      _13761: () => globalThis.console,
      _13790: () => globalThis.window.flutterCanvasKit,
      _13791: () => globalThis.window._flutter_skwasmInstance,

    };

    const baseImports = {
      dart2wasm: dart2wasm,


      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
    };

    const deferredLibraryHelper = {
      "loadModule": async (moduleName) => {
        if (!loadDeferredWasm) {
          throw "No implementation of loadDeferredWasm provided.";
        }
        const source = await Promise.resolve(loadDeferredWasm(moduleName));
        const module = await ((source instanceof Response)
            ? WebAssembly.compileStreaming(source, this.builtins)
            : WebAssembly.compile(source, this.builtins));
        return await WebAssembly.instantiate(module, {
          ...baseImports,
          ...additionalImports,
          "wasm:js-string": jsStringPolyfill,
          "module0": dartInstance.exports,
        });
      },
    };

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      "deferredLibraryHelper": deferredLibraryHelper,
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}

