Mix.install([
{:bumblebee, "~> 0.5.0"},
{:exla, "~> 0.7.0"},
{:nx, "~> 0.7.0 "},
{:hnswlib, "~> 0.1.5"}
])

Nx.global_default_backend(EXLA.Backend)

IO.puts "Loading the model..................................."
transformer = "sentence-transformers/paraphrase-MiniLM-L6-v2"
{:ok, %{model: _model, params: _params} = model_info} =
  Bumblebee.load_model({:hf, transformer})

{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, transformer})
serving = Bumblebee.Text.TextEmbedding.text_embedding(
  model_info,
  tokenizer,
  defn_options: [compiler: EXLA],
  embedding_processor: :l2_norm
  # output_pool: :mean_pooling,
  # output_attribute: :hidden_state,
  )

# keys = model_info.params |> Map.keys()
# keys |> dbg()

IO.puts ""
IO.puts "======================================================"
IO.puts "Norm: :l2"
{:ok, index} = HNSWLib.Index.new(_space = :l2, _dim = 384, _max_elements = 200)
IO.puts ""
IO.puts "Compute embedding for: 'short' ----------------------"
%{embedding: t_short} = Nx.Serving.run(serving, "short") |> dbg()
HNSWLib.Index.add_items(index, t_short)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "Compute embedding for: 'tall' ----------------------"
%{embedding: t_tall} = Nx.Serving.run(serving, "tall")
HNSWLib.Index.add_items(index, t_tall)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "Compute embedding for: 'average' ----------------------"
%{embedding: t_tall} = Nx.Serving.run(serving, "average")
HNSWLib.Index.add_items(index, t_tall)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "Compute KNN search for: 'small' ----------------------"
%{embedding: data} = Nx.Serving.run(serving, "small")
{:ok, labels, distances} = HNSWLib.Index.knn_query(index, data, k: 1)
idx = Nx.to_flat_list(labels[0])
d = Nx.to_flat_list(distances[0])
%{found_index: hd(idx)+1, distance_to_closeset: hd(d)} |> dbg()
{:ok, dt} = HNSWLib.Index.get_items(index, idx)
recovered = hd(dt) |> Nx.from_binary(:f32) |> Nx.stack()
IO.puts "Check the recovered embedding at the found index is the embedding of 'short' "
{recovered, t_short} |> dbg()


IO.puts ""
IO.puts "======================================================"
IO.puts "Norm: :cosine"
{:ok, index} = HNSWLib.Index.new(_space = :cosine, _dim = 384, _max_elements = 200)
IO.puts ""
IO.puts "No normalisation"
IO.puts ""
IO.puts "Compute embedding for: 'short' ----------------------"
%{embedding: t_small} = Nx.Serving.run(serving, "short") |> dbg()
HNSWLib.Index.add_items(index, t_small)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "Compute embedding for: 'tall' ----------------------"
%{embedding: t_tall} = Nx.Serving.run(serving, "tall")
HNSWLib.Index.add_items(index, t_tall)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "Compute embedding for: 'average' ----------------------"
%{embedding: t_avg} = Nx.Serving.run(serving, "average")
HNSWLib.Index.add_items(index, t_avg)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "KNN search for: 'small' ----------------------"
%{embedding: data} = Nx.Serving.run(serving, "small")
{:ok, labels, distances} = HNSWLib.Index.knn_query(index, data, k: 1) |> dbg()
idx = Nx.to_flat_list(labels[0])
d = Nx.to_flat_list(distances[0])
%{found_index: hd(idx)+1, distance_to_closeset: hd(d)} |> dbg()
{:ok, dt} = HNSWLib.Index.get_items(index, idx)
recovered_from_index = hd(dt) |> Nx.from_binary(:f32) |> Nx.stack()
IO.puts "Check the recovered embedding at the found index is the embedding of 'small' "
{recovered_from_index, t_small} |> dbg()


IO.puts ""
IO.puts "======================================================"
IO.puts "Norm: :cosine"
{:ok, index} = HNSWLib.Index.new(_space = :cosine, _dim = 384, _max_elements = 200)
IO.puts ""
IO.puts "Normalize the tensors"
IO.puts ""
IO.puts "Compute embedding for: 'short' ----------------------"
%{embedding: t_small} = Nx.Serving.run(serving, "short")
n_small = Nx.divide(t_small, Nx.LinAlg.norm(t_small)) |>dbg()
HNSWLib.Index.add_items(index, n_small)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "Compute embedding for: 'tall' ----------------------"
%{embedding: t_tall} = Nx.Serving.run(serving, "tall")
n_tall  = Nx.divide(t_tall, Nx.LinAlg.norm(t_tall))
HNSWLib.Index.add_items(index, n_tall)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "Compute embedding for: 'average' ----------------------"
%{embedding: t_tall} = Nx.Serving.run(serving, "average")
n_avg  = Nx.divide(t_tall, Nx.LinAlg.norm(t_tall))
HNSWLib.Index.add_items(index, n_avg)
HNSWLib.Index.get_current_count(index) |> dbg()

IO.puts "KNN search for: 'small' ----------------------"
%{embedding: data} = Nx.Serving.run(serving, "small")
n_data =  Nx.divide(data, Nx.LinAlg.norm(data))
{:ok, labels, distances} = HNSWLib.Index.knn_query(index, n_data, k: 1)
idx = Nx.to_flat_list(labels[0])
d = Nx.to_flat_list(distances[0])
%{found_index: hd(idx)+1, distance_to_closeset: hd(d)} |> dbg()
{:ok, dt} = HNSWLib.Index.get_items(index, idx)
recovered_from_index = hd(dt) |> Nx.from_binary(:f32) |> Nx.stack()
IO.puts "Check the recovered embedding at the found index is the embedding of 'small' "
{recovered_from_index, n_small} |> dbg()
