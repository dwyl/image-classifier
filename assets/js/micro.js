export default {
  mounted() {
    let mediaRecorder;
    let audioChunks = [];
    const recordButton = document.getElementById("record");
    const audioElement = document.getElementById("audio");

    _this = this;

    recordButton.addEventListener("click", () => {
      if (mediaRecorder && mediaRecorder.state === "recording") {
        mediaRecorder.stop();
        recordButton.textContent = "Record";
      } else {
        navigator.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
          mediaRecorder = new MediaRecorder(stream);
          mediaRecorder.start();
          recordButton.classList.remove("bg-blue-500", "hover:bg-blue-700");
          recordButton.classList.add(
            "bg-green-500",
            "hover:bg-green-700",
            "animate-pulse"
          );
          recordButton.textContent = "Stop";

          mediaRecorder.addEventListener("dataavailable", (event) => {
            audioChunks.push(event.data);
          });

          mediaRecorder.addEventListener("stop", () => {
            const audioBlob = new Blob(audioChunks);
            console.log(audioBlob);
            audioElement.src = URL.createObjectURL(audioBlob);

            _this.upload("speech", [audioBlob]);
            audioChunks = [];
            recordButton.classList.remove(
              "bg-green-500",
              "hover:bg-green-700",
              "animate-pulse"
            );
            recordButton.classList.add("bg-blue-500", "hover:bg-blue-700");
          });
        });
      }
    });
  },
};
