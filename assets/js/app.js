// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

let hooks = {}
hooks.ImageInput = {
  mounted() {
    this.boundHeight = parseInt(this.el.dataset.height);
    this.boundWidth = parseInt(this.el.dataset.width);
    this.inputEl = this.el.querySelector(`#image-input`);
    this.previewEl = this.el.querySelector(`#image-preview`);
    
    this.el.addEventListener("click", (e) => this.inputEl.click());
    this.inputEl.addEventListener("change", (e) => this.loadFile(event.target.files));
    this.el.addEventListener("dragover", (e) => {
      e.stopPropagation();
      e.preventDefault();
      e.dataTransfer.dropEffect = "copy";
    });
    this.el.addEventListener("drop", (e) => {
      e.stopPropagation();
      e.preventDefault();
      this.loadFile(e.dataTransfer.files);
    });
  },

  loadFile(files) {
    const file = files && files[0];
    if (!file) {
      return;
    }
    const reader = new FileReader();
    reader.onload = (readerEvent) => {
      const imgEl = document.createElement("img");
      imgEl.addEventListener("load", (loadEvent) => {
        this.setPreview(imgEl);
        const blob = this.canvasToBlob(this.toCanvas(imgEl));
        this.upload("image", [blob]);
      });
      imgEl.src = readerEvent.target.result;
    };
    reader.readAsDataURL(file);
  },

  setPreview(imgEl) {
    const previewImgEl = imgEl.cloneNode();
    previewImgEl.style.maxHeight = "100%";
    this.previewEl.replaceChildren(previewImgEl);
  },

  toCanvas(imgEl) {
    // We resize the image, such that it fits in the configured height x width, but
    // keep the aspect ratio. We could also easily crop, pad or squash the image, if desired
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");
    const widthScale = this.boundWidth / imgEl.width;
    const heightScale = this.boundHeight / imgEl.height;
    const scale = Math.min(widthScale, heightScale);
    canvas.width = Math.round(imgEl.width * scale);
    canvas.height = Math.round(imgEl.height * scale);
    ctx.drawImage(imgEl, 0, 0, imgEl.width, imgEl.height, 0, 0, canvas.width, canvas.height);
    return canvas;
  },

  canvasToBlob(canvas) {
    const imageData = canvas.getContext("2d").getImageData(0, 0, canvas.width, canvas.height);
    const buffer = this.imageDataToRGBBuffer(imageData);
    const meta = new ArrayBuffer(8);
    const view = new DataView(meta);
    view.setUint32(0, canvas.height, false);
    view.setUint32(4, canvas.width, false);
    return new Blob([meta, buffer], { type: "application/octet-stream" });
  },

  imageDataToRGBBuffer(imageData) {
    const pixelCount = imageData.width * imageData.height;
    const bytes = new Uint8ClampedArray(pixelCount * 3);
    for (let i = 0; i < pixelCount; i++) {
      bytes[i * 3] = imageData.data[i * 4];
      bytes[i * 3 + 1] = imageData.data[i * 4 + 1];
      bytes[i * 3 + 2] = imageData.data[i * 4 + 2];
    }
    return bytes.buffer;
  },
};

// connect if there are any LiveViews on the page
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { hooks: hooks, params: { _csrf_token: csrfToken } });
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
