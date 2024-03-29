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
import Toastify from "toastify-js";
import Audio from "./micro.js";
import topbar from "../vendor/topbar";

let Hooks = { Audio };

// Hook to track inactivity
Hooks.ActivityTracker = {
  mounted() {
    // Set the inactivity duration in milliseconds
    const inactivityDuration = 8000; // 8 seconds

    // Set a variable to keep track of the timer and if the process to predict example image has already been sent
    let inactivityTimer;
    let processHasBeenSent = false;

    // We use the `mounted()` context to push the event. This is used in the `setTimeout` function below.
    let ctx = this;

    // Function to reset the timer
    function resetInactivityTimer() {
      // Clear the previous timer
      clearTimeout(inactivityTimer);

      // Start a new timer
      inactivityTimer = setTimeout(() => {
        // Perform the desired action after the inactivity duration
        // For example, send a message to the Elixir process using Phoenix Socket
        if (!processHasBeenSent) {
          processHasBeenSent = true;
          ctx.pushEvent("show_examples", {});
        }
      }, inactivityDuration);
    }

    // Call the function to start the timer initially
    resetInactivityTimer();

    // Reset the timer whenever there is user activity
    document.addEventListener("mousemove", resetInactivityTimer);
    document.addEventListener("keydown", resetInactivityTimer);
  },
};

// Hook to show message toast
Hooks.MessageToaster = {
  mounted() {
    this.handleEvent("toast", (payload) => {
      Toastify({
        text: payload.message,
        gravity: "bottom",
        position: "right",
        style: {
          background: "linear-gradient(to right, #f27474, #ed87b5)",
        },
        duration: 4000,
      }).showToast();
    });
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

// Toggles to show upload or semantic search containers
// JavaScript to toggle visibility and styles
document.getElementById('upload_option').addEventListener('click', function() {
  document.getElementById('upload_container').style.display = 'block';
  document.getElementById('search_container').style.display = 'none';

  document.getElementById('upload_option').classList.replace('bg-white', 'bg-blue-500');
  document.getElementById('upload_option').classList.replace('text-gray-900', 'text-white');
  document.getElementById('upload_option').classList.replace('hover:bg-gray-50', 'hover:bg-blue-600');
  document.getElementById('upload_option').getElementsByTagName('svg')[0].classList.replace('text-gray-400', 'text-white');

  document.getElementById('search_option').classList.replace('bg-blue-500', 'bg-white');
  document.getElementById('search_option').classList.replace('text-white', 'text-gray-900');
  document.getElementById('search_option').classList.replace('hover:bg-blue-600', 'hover:bg-gray-50');
  document.getElementById('search_option').getElementsByTagName('svg')[0].classList.replace('text-white', 'text-gray-400');
});

document.getElementById('search_option').addEventListener('click', function() {
  document.getElementById('upload_container').style.display = 'none'; 
  document.getElementById('search_container').style.display = 'block';

  document.getElementById('search_option').classList.replace('bg-white', 'bg-blue-500');
  document.getElementById('search_option').classList.replace('text-gray-900', 'text-white');
  document.getElementById('search_option').classList.replace('hover:bg-gray-50', 'hover:bg-blue-600');
  document.getElementById('search_option').getElementsByTagName('svg')[0].classList.replace('text-gray-400', 'text-white');

  document.getElementById('upload_option').classList.replace('bg-blue-500', 'bg-white');
  document.getElementById('upload_option').classList.replace('text-white', 'text-gray-900');
  document.getElementById('upload_option').classList.replace('hover:bg-blue-600', 'hover:bg-gray-50');
  document.getElementById('upload_option').getElementsByTagName('svg')[0].classList.replace('text-white', 'text-gray-400');
});


// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
