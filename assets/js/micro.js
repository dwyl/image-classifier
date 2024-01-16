export default {
  mounted() {
    let mediaRecorder,
      audioChunks = [];

    // Defining the elements and styles to be used during recording
    // and shown on the HTML.
    const recordButton = document.getElementById("record"),
      audioElement = document.getElementById("audio"),
      text = document.getElementById("text"),
      blue = ["bg-blue-500", "hover:bg-blue-700"],
      pulseGreen = ["bg-green-500", "hover:bg-green-700", "animate-pulse"];


    _this = this;

    // Adding event listener for "click" event
    recordButton.addEventListener("click", () => {

      // Check if it's recording.
      // If it is, we stop the record and update the elements.
      if (mediaRecorder && mediaRecorder.state === "recording") {
        mediaRecorder.stop();
        text.textContent = "Record";
      } 

      // Otherwise, it means the user wants to start recording.
      else {
        navigator.mediaDevices.getUserMedia({ audio: true }).then((stream) => {

          // Instantiate MediaRecorder
          mediaRecorder = new MediaRecorder(stream);
          mediaRecorder.start();

          // And update the elements
          recordButton.classList.remove(...blue);
          recordButton.classList.add(...pulseGreen);
          text.textContent = "Stop";

          // Add "dataavailable" event handler
          mediaRecorder.addEventListener("dataavailable", (event) => {
            audioChunks.push(event.data);
          });

          // Add "stop" event handler for when the recording stops.
          mediaRecorder.addEventListener("stop", () => {
            const audioBlob = new Blob(audioChunks);
            // the source of the audio element
            audioElement.src = URL.createObjectURL(audioBlob);

            _this.upload("speech", [audioBlob]);
            audioChunks = [];
            recordButton.classList.remove(...pulseGreen);
            recordButton.classList.add(...blue);
          });
        });
      }
    });
  },
};