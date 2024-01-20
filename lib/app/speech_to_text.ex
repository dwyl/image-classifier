# defmodule App.Whisper do
#   def serving do
#     model = "openai/whisper-small"
#     {:ok, whisper} = Bumblebee.load_model({:hf, model})
#     {:ok, featurizer} = Bumblebee.load_featurizer({:hf, model})
#     {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model})
#     {:ok, generation_config} = Bumblebee.load_generation_config({:hf, model})

#     Bumblebee.Audio.speech_to_text_whisper(
#       whisper,
#       featurizer,
#       tokenizer,
#       generation_config,
#       chunk_num_seconds: 30,
#       task: :transcribe,
#       # stream: true,
#       defn_options: [compiler: EXLA]
#     )
#   end
# end
