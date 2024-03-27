# Notes on HNSWLib binding for Elixir

## Semantic search example on how to use `HNSWLib`

The code below can be run in an IEX session
or in a Livebook.

```elixir
elixir hnswlib.exs
```

We use the small model [sentence-transformers/paraphrase-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/paraphrase-MiniLM-L6-v2)
from `Hugging Face` to compute embeddings from text
and run a [semantic search](https://sbert.net/examples/applications/semantic-search/README.html).

This model is a vector of dimension [384](https://huggingface.co/sentence-transformers/paraphrase-MiniLM-L6-v2/blob/main/config.json).

### Dependencies

```elixir
Mix.install([
{:bumblebee, "~> 0.5.0"},
{:exla, "~> 0.7.0"},
{:nx, "~> 0.7.0 "},
{:hnswlib, "~> 0.1.5"},
])

Nx.global_default_backend(EXLA.Backend)
```

### Instantiate the `hnswlib` index

#### Metric

You need to endow the vector space with one of the following metrics by setting the `space` argument from the list:

`[:l2, :ip, :cosine]`

> the first is the standard Euclidean metric, the second the inner product, and the third the pseudo-metric "cosine similarity".

We set the `:dimension` to **384**.
We firstly use the `:l2` norm to build the `hnswlib` index:

```elixir
{:ok, index} =
  HNSWLib.Index.new(
    _space = :l2,
             ^^^
    _dim = 384,
    _max_elements = 200
  )
```

### `Nx.Serving`

We build the `Nx.serving` for our model:
it downloads the model file from the Hugging Face.

```elixir
transformer = "sentence-transformers/paraphrase-MiniLM-L6-v2"

{:ok, %{model: _, params: _} = model_info} =
      Bumblebee.load_model({:hf, transformer})

{:ok, tokenizer} =
  Bumblebee.load_tokenizer({:hf, transformer})

serving =
  Bumblebee.Text.TextEmbedding.text_embedding(
    model_info,
    tokenizer,
    defn_options: [compiler: EXLA]
  )
```

### Compute embeddings and add to the index

We check that our index is instantiated and empty:

```elixir
HNSWLib.Index.get_current_count(index)
#{:ok, 0}
```

We compute our first embedding for the word "short":

```elixir
input = "short"
# you compute the embedding
%{embedding: data} =
    Nx.Serving.run(serving, input)
```

You get:

```elixir
%{
  embedding: #Nx.Tensor<
    f32[384]
      [-0.013410531915724277, 0.07099384069442749, -0.013070221990346909,...]
}
```

You then append the embedding to your Index:

```elixir
:ok = HNSWLib.Index.add_items(index, data)

HNSWLib.Index.save_index(index, "my_index.bin")
#{:ok, 1}
```

You should see a file `"my_index.bin"` is your current directory.

When you append an entry one by one, you can get the final indice of the Index with:

```elixir
HNSWLib.Index.get_current_count(index)
```

This means you can persist the index to uniquely identify an item.

> You can also enter a batch of items. You will only get back the last indice. This means that you may need to persist the embedding if you want to identify the input in this case.

Let's enter another entry:

```elixir
input = "tall"
# you get an embedding
%{embedding: data} =
    Nx.Serving.run(serving, input)

# you build your Index struct
:ok = HNSWLib.Index.add_items(index, data)

HNSWLib.Index.save_index(index, "my_index.bin")

HNSWLib.Index.get_current_count(index)
#{:ok, 2}
```

### KNN search

You now run a `knn_query`from a text input - converted into an embedding - to look for the closest element present in the Index.

Let's find the closest item in the Index to the input "small".
We expect to get "short", the first item.

```elixir
input = "small"
# you normalise your query data
%{embedding: query_data} =
  Nx.Serving.run(serving, input)

{:ok, labels, _d} =
    HNSWLib.Index.knn_query(
      index,
      query_data,
      k: 1
    )
```

You should get:

```elixir
{:ok,
 #Nx.Tensor<
   u64[1][1]
   EXLA.Backend<host:0, 0.968243412.4269146128.215737>
   [
     [0]
   ]
 >,
 #Nx.Tensor<
   f32[1][1]
   EXLA.Backend<host:0, 0.968243412.4269146128.215739>
   [
     [0.2972676455974579]
   ]
 >}
```

This means that the nearest neighbour of the given input has the indice "0" in the Index.
This corresponds to the **first** entry "short".

We can recover the embedding to compare:

```elixir
{:ok, data} =
  HNSWLib.Index.get_items(
    index,
    Nx.to_flat_list(labels[0])
  )

hd(data) |> Nx.from_binary(:f32) |> Nx.stack()
```

The result is:

```elixir
##Nx.Tensor<
  f32[1][384]
  EXLA.Backend<host:0, 0.968243412.4269146128.215745>
  [
     [-0.013410531915724277, 0.07099384069442749, -0.013070221990346909,...]
  ]
```

As expected, we recovered the first embedding.

### Change the norm

The model has been trained with the norm `:cosine`. We will use it.

```elixir
{:ok, index} =
    HNSWLib.Index.new(
        _space = :cosine,
                 ^^^
        _dim = 384,
        _max_elements = 200
    )
```

We get the embedding:

```elixir
#Nx.Tensor<
    f32[384]
        [-0.013410531915724277, 0.07099384069442749, -0.013070221990346909,...]

```

When we run the knn search, we find again the same "nearest neighbour" with of course a different distance.

```elixir
#Nx.Tensor<
   u64[1][1]
   EXLA.Backend<host:0, 0.905715445.2882404368.207646>
   [
     [0]
   ]
 >,
 #Nx.Tensor<
   f32[1][1]
   EXLA.Backend<host:0, 0.905715445.2882404368.207647>
   [
     [0.06562089920043945]
   ]
 >}
```

The recovered embedding is however different:

```elixir
#Nx.Tensor<
   f32[1][384]
   EXLA.Backend<host:0, 0.905715445.2882404368.207652>
   [
     [-0.008871854282915592, 0.04696659371256828, -0.00864671915769577,...]
```

The reason is that the "sentence-transformer" model uses differents settings than `Bumblebee`default settings:

```py
SentenceTransformer(
  (0): Transformer({'max_seq_length': 128, 'do_lower_case': False}) with Transformer model: BertModel
  (1): Pooling({'word_embedding_dimension': 384, 'pooling_mode_cls_token': False, 'pooling_mode_mean_tokens': True, 'pooling_mode_max_tokens': False, 'pooling_mode_mean_sqrt_len_tokens': False})
)
```

It performs "mean_tokens_pooling" and "normalizes" the vectors [see here](https://www.sbert.net/docs/package_reference/models.html#sentence_transformers.models.Pooling) with `class sentence_transformers.models.Pooling` and `class sentence_transformers.models.Normalize`.

[This blog post confirms this](https://samrat.me/blog/til-creating-sentence-transformers-embeddings-from-bumblebee).

To recover the embedding, we can:

- **normalize** the tensors with the transformation:

```elixir
%{embedding: t_small} =
    Nx.Serving.run(serving, "short")

n_small =
    Nx.divide(t_small, Nx.LinAlg.norm(t_small))

HNSWLib.Index.add_items(index, n_small)
```

- or just change the options to the [Bumblebee.Text.text_embedding/3](https://hexdocs.pm/bumblebee/0.4.0/Bumblebee.Text.html#text_embedding/3):

```elixir
serving =
    Bumblebee.Text.TextEmbedding.text_embedding(
        model_info,
        tokenizer,
        defn_options: [compiler: EXLA],
        embedding_processor: :l2_norm,
        output_pool: :mean_pooling,
        output_attribute: :hidden_state
    )
```

When we just normalize the vectors, we recover the exact same vector.
When we change the `Bimblebee` settings, the recovered embedding is almost identical:

```elixir
[-0.03144508972764015, 0.12630629539489746, 0.018703171983361244,...]
```

## Notes on vector spaces

A vector space of embeddings can be equipped with a (Euclidean) _inner product_. If $u=(u_1,\dots,u_n)$ and $v=(v_1,\dots,v_n)$ are two embeddings, the (euclidean) inner product is defined as:

$< u,v >=u_1v_1+\cdots+u_nv_n$

This inner product induces an Euclidean _norm_:

$||u|| = \sqrt{< u,u >} = \sqrt{u_1^2+\cdots+u_n^2}$

Let $u_v$ be the perpendicular projection of $u$ on $v$. Then:

$< u, v > = < u_v,v > = ||u||\cdot ||v|| \cos\widehat{u,v}$

The value below is known as the _cosine similarity_.

$<\frac{u}{||u||}\frac{v}{\||v||}> = \cos\widehat{u,v}$.

You will remark that the norm of any embedding $\frac1{||u||}u$ is 1. We say that the embedding is $L_2$-normalised.

The previous formula shows that the inner product of normalised (aka unit) embeddings is the `cosine` of the angle between these "normalised" embeddings.

> Source: <https://en.wikipedia.org/wiki/Cosine_similarity>

_Note that this is not a distance._

The norm in turn induces a _distance_:
$d(u,v) = ||u-v||$

By definition,
$||u-v||^2  = < u-v,u-v >$.

By developing, we obtain:

$||u-v||^2  = ||u||^2+||v||^2-2< u,v >$

Consider now **two normalised** vectors. We have:
$\frac12||u-v||^2=1-\cos\widehat{u,v} = d_c(u,v)$

This is commonly known as the **cosine distance** _when the embeddings are normalised_. It ranges from 0 to 2. Note that it is not a true distance metric.

Finally, note that since we are dealing with finite dimensional vector spaces, all the norms are equivalent (in some precise mathematical way). This means that the limit points are always the same. However, the values of the distances can be quite different, and a "clusterisation" process can give significantly different results.
