<div align="center">

# Image Captioning & Semantic Search in `Elixir`

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/dwyl/image-classifier/ci.yml?label=build&style=flat-square&branch=main)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/image-classifier/main.svg?style=flat-square)](https://codecov.io/github/dwyl/image-classifier?branch=main)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/image-classifier/issues)
[![HitCount](https://hits.dwyl.com/dwyl/image-classifier.svg?style=flat-square&show=unique)](https://hits.dwyl.com/dwyl/image-classifier)

Let's use `Elixir` machine learning capabilities
to build an application
that performs **image captioning**
and **semantic search**
to search for uploaded images
with your voice! 🎙️

<p align="center">
  <img src="https://github.com/dwyl/image-classifier/assets/17494745/05d0b510-ef9a-4a51-8425-d27902b0f7ad">
</p>

</div>

<br />

- [Image Captioning \& Semantic Search in `Elixir`](#image-captioning--semantic-search-in-elixir)
  - [Why? 🤷](#why-)
  - [What? 💭](#what-)
  - [Who? 👤](#who-)
  - [How? 💻](#how-)
  - [Prerequisites](#prerequisites)
  - [🌄 Image Captioning in `Elixir`](#-image-captioning-in-elixir)
    - [0. Creating a fresh `Phoenix` project](#0-creating-a-fresh-phoenix-project)
    - [1. Installing initial dependencies](#1-installing-initial-dependencies)
    - [2. Adding `LiveView` capabilities to our project](#2-adding-liveview-capabilities-to-our-project)
    - [3. Receiving image files](#3-receiving-image-files)
    - [4. Integrating `Bumblebee`](#4-integrating-bumblebee)
      - [4.1 `Nx` configuration](#41-nx-configuration)
      - [4.2 `Async` processing the image for classification](#42-async-processing-the-image-for-classification)
        - [4.2.1 Considerations regarding `async` processes](#421-considerations-regarding-async-processes)
        - [4.2.2 Alternative for better testing](#422-alternative-for-better-testing)
      - [4.3 Image pre-processing](#43-image-pre-processing)
    - [4.4 Updating the view](#44-updating-the-view)
      - [4.5 Check it out!](#45-check-it-out)
      - [4.6 Considerations on user images](#46-considerations-on-user-images)
    - [5. Final Touches](#5-final-touches)
      - [5.1 Setting max file size](#51-setting-max-file-size)
      - [5.2 Show errors](#52-show-errors)
      - [5.3 Show image preview](#53-show-image-preview)
    - [6. What about other models?](#6-what-about-other-models)
    - [7. How do I deploy this thing?](#7-how-do-i-deploy-this-thing)
    - [8. Showing example images](#8-showing-example-images)
      - [8.1 Creating a hook in client](#81-creating-a-hook-in-client)
    - [8.2 Handling the example images list event inside our LiveView](#82-handling-the-example-images-list-event-inside-our-liveview)
      - [8.3 Updating the view](#83-updating-the-view)
      - [8.4 Using URL of image instead of base64-encoded](#84-using-url-of-image-instead-of-base64-encoded)
      - [8.5 See it running](#85-see-it-running)
    - [9. Store metadata and classification info](#9-store-metadata-and-classification-info)
      - [9.1 Installing dependencies](#91-installing-dependencies)
      - [9.2 Adding `Postgres` configuration files](#92-adding-postgres-configuration-files)
      - [9.3 Creating `Image` schema](#93-creating-image-schema)
      - [9.4 Changing our LiveView to persist data](#94-changing-our-liveview-to-persist-data)
    - [10. Adding double MIME type check and showing feedback to the person in case of failure](#10-adding-double-mime-type-check-and-showing-feedback-to-the-person-in-case-of-failure)
      - [10.1 Showing a toast component with error](#101-showing-a-toast-component-with-error)
    - [11. Benchmarking image captioning models](#11-benchmarking-image-captioning-models)
  - [🔍 Semantic search](#-semantic-search)
    - [0. Overview of the process](#0-overview-of-the-process)
      - [0.1 Audio transcription](#01-audio-transcription)
      - [0.2 Creating embeddings](#02-creating-embeddings)
      - [0.3 Semantical search](#03-semantical-search)
    - [1. Pre-requisites](#1-pre-requisites)
    - [2. Transcribe an audio recording](#2-transcribe-an-audio-recording)
      - [1.1 Adding a loading spinner](#11-adding-a-loading-spinner)
      - [2.2 Defining `Javascript` hook](#22-defining-javascript-hook)
      - [2.3 Handling audio upload in `LiveView`](#23-handling-audio-upload-in-liveview)
      - [2.4 Serving the `Whisper` model](#24-serving-the-whisper-model)
      - [2.5 Handling the model's response and updating elements in the view](#25-handling-the-models-response-and-updating-elements-in-the-view)
    - [3. Embeddings and semantic search](#3-embeddings-and-semantic-search)
      - [3.1 The `HNSWLib` Index (GenServer)](#31-the-hnswlib-index-genserver)
      - [3.2 Saving the `HNSWLib` Index in the database](#32-saving-the-hnswlib-index-in-the-database)
      - [3.2 The embeding model](#32-the-embeding-model)
    - [4. Using the Index and embeddings](#4-using-the-index-and-embeddings)
      - [4.0 Working example on how to use `HNSWLib`](#40-working-example-on-how-to-use-hnswlib)
        - [4.0.1 Notes on vector spaces](#401-notes-on-vector-spaces)
      - [4.1 Computing the embeddings in our app](#41-computing-the-embeddings-in-our-app)
        - [4.1.1 Changing the `Image` schema so it's embeddable](#411-changing-the-image-schema-so-its-embeddable)
        - [4.1.2 Using embeddings in semantic search](#412-using-embeddings-in-semantic-search)
          - [4.1.2.1 Mount socket assigns](#4121-mount-socket-assigns)
          - [4.1.2.2 Consuming image uploads](#4122-consuming-image-uploads)
          - [4.1.2.3 Using the embeddings to semantically search images](#4123-using-the-embeddings-to-semantically-search-images)
          - [4.1.2.4 Creating embeddings when uploading images](#4124-creating-embeddings-when-uploading-images)
          - [4.1.2.5 Update the LiveView view](#4125-update-the-liveview-view)
  - [_Please_ star the repo! ⭐️](#please-star-the-repo-️)

<br />

## Why? 🤷

Building our [app](https://github.com/dwyl/app),
we consider `images` an _essential_ medium of communication.

You personally may have a collection of images that you want to caption
and semantically retrieve them fast.

By adding a way of captioning images, we make it _easy_ for people to suggest meta tags that describe images so they become **searchable**.

## What? 💭

This run-through will create a simple
`Phoenix` web application
that will allow you to choose/drag an image
and automatically caption the image.

In addition to this,
the app will allow the user to record an audio
which describes the image they want to find.

The audio will be transcribed into text
and be semantically queryable.
We do this by encoding the image captions
as vectors and running `knn search` on them.

## Who? 👤

This tutorial is aimed at `Phoenix` beginners
who want to start exploring the machine-learning capabilities
of the Elixir language within a `Phoenix` application.
We propose to use pre-trained models from Hugging Face via `Bumblebee`
and grasp how to:

- run a model, in particular image captioning.
- how to use embeddings.
- how to run a semantic search using an
  [Approximate Nearest Neighbour](https://towardsdatascience.com/comprehensive-guide-to-approximate-nearest-neighbors-algorithms-8b94f057d6b6)
  algorithm.

If you are completely new to `Phoenix` and `LiveView`,
we recommend you follow the **`LiveView` _Counter_ Tutorial**:

[dwyl/phoenix-liveview-counter-tutorial](https://github.com/dwyl/phoenix-liveview-counter-tutorial)

## How? 💻

In these chapters, we'll go over the development process of this small application.
You'll learn how to do this _yourself_, so grab some coffee and let's get cracking!

This section will be divided into two sections.
One will go over **image captioning**
while the second one will expand the application
by adding **semantic search**.

## Prerequisites

This tutorial requires you to have `Elixir` and `Phoenix` installed.

If you don't, please see [how to install Elixir](https://github.com/dwyl/learn-elixir#installation) and [Phoenix](https://hexdocs.pm/phoenix/installation.html#phoenix).

This guide assumes you know the basics of `Phoenix`
and have _some_ knowledge of how it works.
If you don't, we _highly suggest_ you follow our other tutorials first, e.g: [github.com/dwyl/**phoenix-chat-example**](https://github.com/dwyl/phoenix-chat-example)

In addition to this, **_some_ knowledge of `AWS`** - what it is, what an `S3` bucket is/does - **is assumed**.

> [!NOTE]
> If you have questions or get stuck,
> please open an issue!
> [/dwyl/image-classifier/issues](https://github.com/dwyl/image-classifier/issues)

<div align="center">

## 🌄 Image Captioning in `Elixir`

In this section, we'll start building our application
with `Bumblebee` that supports Transformer models.
At the end of this section,
you'll have a fully functional application
that receives an image,
processes it accordingly
and captions it.

</div>

### 0. Creating a fresh `Phoenix` project

Let's create a fresh `Phoenix` project.
Run the following command in a given folder:

```sh
mix phx.new . --app app --no-dashboard --no-ecto  --no-gettext --no-mailer
```

We're running [`mix phx.new`](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html) to generate a new project without a dashboard and mailer (email) service,
since we don't need those features in our project.

After this, if you run `mix phx.server` to run your server, you should be able to see the following page.

<p align="center">
  <img src="https://github.com/dwyl/fields/assets/194400/891e890e-c94a-402e-baee-ee47fd3725a7">
</p>

We're ready to start building.

### 1. Installing initial dependencies

Now that we're ready to go, let's start by adding some dependencies.

Head over to `mix.exs`and add the following dependencies
to the `deps` section.

```elixir
{:bumblebee, "~> 0.5.0"},
{:exla, "~> 0.7.0"},
{:nx, "~> 0.7.0 "},
{:hnswlib, "~> 0.1.5"},
```

- [**`bumblebee`**](https://github.com/elixir-nx/bumblebee) is a framework that will allows us to integrate
  [`Transformer Models`](https://huggingface.co/docs/transformers/index) in `Phoenix`.
  The `Transformers` (from [Hugging Face](https://huggingface.co/))
  are APIs that allow us to easily download and use
  [pre-trained models](https://blogs.nvidia.com/blog/2022/12/08/what-is-a-pretrained-ai-model).
  The `Bumblebee` package aims to support all Transformer Models, even if some are still lacking.
  You may check which ones are supported by visiting
  `Bumblebee`'s repository or by visiting https://jonatanklosko-bumblebee-tools.hf.space/apps/repository-inspector
  and checking if the model is currently supported.

- [**`Nx`**](https://hexdocs.pm/nx/Nx.html) is a library that allows us to work with
  [`Numerical Elixir`](https://github.com/elixir-nx/), the Elixir's way of doing [numerical computing](https://www.hilarispublisher.com/open-access/introduction-to-numerical-computing-2168-9679-1000423.pdf). It supports tensors and numericla computations.

- [**`EXLA`**](https://hexdocs.pm/exla/EXLA.html) is the Elixir implementation of [Google's XLA](https://www.tensorflow.org/xla/),
  a compiler that provides faster linear algebra calculations
  with `TensorFlow` models.
  This backend compiler is needed for `Nx`.
  We are installing `EXLA` because it allows us to compile models _just-in-time_ and run them on CPU and/or GPU.

- [**`Vix`**](https://hexdocs.pm/vix/readme.html) is an Elixir extension for [libvips](https://www.libvips.org/), an image processing library.

In `config/config.exs`, let's add our `:nx` configuration
to use `EXLA`.

```elixir
config :nx, default_backend: EXLA.Backend
```

### 2. Adding `LiveView` capabilities to our project

As it stands, our project is not using `LiveView`.
Let's fix this.

This will launch a super-powered process that establishes a WebSocket connection
between the server and the browser.

In `lib/app_web/router.ex`, change the `scope "/"` to the following.

```elixir
  scope "/", AppWeb do
    pipe_through :browser

    live "/", PageLive
  end
```

Instead of using the `PageController`,
we are going to be creating `PageLive`,
a `LiveView` file.

Let's create our `LiveView` files.
Inside `lib/app_web`,
create a folder called `live`
and create the following file
`page_live.ex`.

```elixir
#/lib/app_web/live/page_live.ex
defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

```

This is a simple `LiveView` controller.

In the same `live` folder,
create a file called `page_live.html.heex`
and use the following code.

```html
<div
  class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32"
>
  <div
    class="flex justify-center items-center mx-auto max-w-xl w-[50vw] lg:mx-0"
  >
    <form>
      <div class="space-y-12">
        <div>
          <h2 class="text-base font-semibold leading-7 text-gray-900">
            Image Classifier
          </h2>
          <p class="mt-1 text-sm leading-6 text-gray-600">
            Drag your images and we'll run an AI model to caption it!
          </p>

          <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
            <div class="col-span-full">
              <div
                class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
              >
                <div class="text-center">
                  <svg
                    class="mx-auto h-12 w-12 text-gray-300"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <div class="mt-4 flex text-sm leading-6 text-gray-600">
                    <label
                      for="file-upload"
                      class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                    >
                      <span>Upload a file</span>
                      <input
                        id="file-upload"
                        name="file-upload"
                        type="file"
                        class="sr-only"
                      />
                    </label>
                    <p class="pl-1">or drag and drop</p>
                  </div>
                  <p class="text-xs leading-5 text-gray-600">
                    PNG, JPG, GIF up to 5MB
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </form>
  </div>
</div>
```

This is a simple HTML form that uses
[`Tailwind CSS`](https://github.com/dwyl/learn-tailwind)
to enhance the presentation of the upload form.
We'll also remove the unused header of the page layout,
while we're at it.

Locate the file `lib/app_web/components/layouts/app.html.heex`
and remove the `<header>` class.
The file should only have the following code:

```html
<main class="px-4 py-20 sm:px-6 lg:px-8">
  <div class="mx-auto max-w-2xl">
    <.flash_group flash={@flash} /> <%= @inner_content %>
  </div>
</main>
```

Now you can safely delete the `lib/app_web/controllers` folder,
which is no longer used.

If you run `mix phx.server`,
you should see the following screen:

<p align="center">
  <img src="https://github.com/dwyl/imgup/assets/17494745/5a3438fe-fa45-47f9-8cb2-9d6d405f55a0">
</p>

This means we've successfully added `LiveView`
and changed our view!

### 3. Receiving image files

Now, let's start by receiving some image files.

With `LiveView`,
we can easily do this by using
[`allow_upload/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#allow_upload/3)
when mounting our `LiveView`.
With this function, we can easily accept
file uploads with progress.
We can define file types, max number of entries,
max file size,
validate the uploaded file and much more!

Firstly,
let's make some changes to
`lib/app_web/live/page_live.html.heex`.

```html
<div
  class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32"
>
  <div
    class="flex justify-center items-center mx-auto max-w-xl w-[50vw] lg:mx-0"
  >
    <div class="space-y-12">
      <div class="border-gray-900/10 pb-12">
        <h2 class="text-base font-semibold leading-7 text-gray-900">
          Image Classification
        </h2>
        <p class="mt-1 text-sm leading-6 text-gray-600">
          Do simple captioning with this
          <a
            href="https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html"
            class="font-mono font-medium text-sky-500"
            >LiveView</a
          >
          demo, powered by
          <a
            href="https://github.com/elixir-nx/bumblebee"
            class="font-mono font-medium text-sky-500"
            >Bumblebee</a
          >.
        </p>

        <!-- File upload section -->
        <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
          <div class="col-span-full">
            <div
              class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
              phx-drop-target="{@uploads.image_list.ref}"
            >
              <div class="text-center">
                <svg
                  class="mx-auto h-12 w-12 text-gray-300"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                    clip-rule="evenodd"
                  />
                </svg>
                <div class="mt-4 flex text-sm leading-6 text-gray-600">
                  <label
                    for="file-upload"
                    class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                  >
                    <form phx-change="validate" phx-submit="save">
                      <label class="cursor-pointer">
                        <.live_file_input upload={@uploads.image_list}
                        class="hidden" /> Upload
                      </label>
                    </form>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs leading-5 text-gray-600">
                  PNG, JPG, GIF up to 5MB
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

We've added a few features:

- we used
  [`<.live_file_input/>`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#live_file_input/1)
  for `LiveView` file upload.
  We've wrapped this component
  with an element that is annotated with the `phx-drop-target` attribute
  pointing to the DOM `id` of the file input.
- because we used `<.live_file_input/>`,
  we need to annotate its wrapping element
  with `phx-submit` and `phx-change`,
  as per
  [hexdocs.pm/phoenix_live_view/uploads.html#render-reactive-elements](https://hexdocs.pm/phoenix_live_view/uploads.html#render-reactive-elements)

Because we've added these bindings,
we need to add the event handlers in
`lib/app_web/live/page_live.ex`.
Open it and update it to:

```elixir
defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(label: nil, upload_running?: false, task_ref: nil)
     |> allow_upload(:image_list,
       accept: ~w(image/*),
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1,
       chunk_size: 64_000
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove-selected", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image_list, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply, socket}
  end

  defp handle_progress(:image_list, entry, socket) when entry.done? do
    uploaded_file =
      consume_uploaded_entry(socket, entry, fn %{path: _path} = _meta ->
        {:ok, entry}
      end)
    {:noreply, socket}
  end

  defp handle_progress(:image_list, _, socket), do: {:noreply, socket}
end
```

- when `mount/3`ing the LiveView,
  we are creating three socket assigns:
  `label` pertains to the model prediction;
  `upload_running?` is a boolean referring to whether the model is running or not;
  `task_ref` refers to the reference of the task that was created for image classification
  (we'll delve into this further later down the line).
  Additionally, we are using the `allow_upload/3` function to define our upload configuration.
  The most important settings here are `auto_upload` set to `true`
  and the `progress` fields.
  By configuring these two properties,
  we are telling `LiveView` that _whenever the person uploads a file_,
  **it is processed immediately and consumed**.

- the `progress` field is handled by the `handle_progress/3` function.
  It receives chunks from the client with a build-in `UploadWriter` function
  (as explained in the [docs](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.UploadWriter.html)).
  When the chunks are all consumed, we get the boolean `entry.done? == true`.
  We consume the file in this function by using
  [`consume_uploaded_entry/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#consume_uploaded_entry/3).
  The anonymous function returns `{:ok, data}` or `{:postpone, message}`.
  Whilst consuming the entry/file,
  we can access its path and then use its content.
  _For now_, we don't need to use it.
  But we will in the future to feed our image classifier with it!
  After the callback function is executed,
  this function "consumes the entry",
  essentially deleting the image from the temporary folder
  and removing it from the uploaded files list.()

- the `"validate"`, `"remove-selected"`, `"save"` event handlers
  are called whenever the person uploads the image,
  wants to remove it from the list of uploaded images
  and when wants to submit the form,
  respectively.
  You may see that we're not doing much with these handlers;
  we're simply replying with a `:noreply`
  because we don't need to do anything with them.

And that's it!
If you run `mix phx.server`, nothing will change.

### 4. Integrating `Bumblebee`

Now here comes the fun part!
It's time to do some image captioning! 🎉

#### 4.1 `Nx` configuration

We first need to add some initial setup in the
`lib/app/application.ex` file.
Head over there and change
the `start` function like so:

```elixir
@impl true
def start(_type, _args) do
  children = [
    # Start the Telemetry supervisor
    AppWeb.Telemetry,
    # Start the PubSub system
    {Phoenix.PubSub, name: App.PubSub},
    {Nx.Serving, serving: serving(), name: ImageClassifier},
    # Start the Endpoint (http/https)
    AppWeb.Endpoint
  ]

  opts = [strategy: :one_for_one, name: App.Supervisor]
  Supervisor.start_link(children, opts)
end

def serving do
  {:ok, model_info} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
  {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})

  Bumblebee.Vision.image_classification(model_info, featurizer,
    top_k: 1,
    compile: [batch_size: 10],
    defn_options: [compiler: EXLA]
  )
end
```

We are using [`Nx.Serving`](https://hexdocs.pm/nx/Nx.Serving.html), which simply allows us to encapsulate tasks; it can be networking, machine learning, data processing or any other task.

In this specific case, we are using it to **batch requests**.
This is extremely useful and important because we are using models that typically run on
[GPU](https://en.wikipedia.org/wiki/Graphics_processing_unit).
The GPU is _really good_ at **parallelizing tasks**.
Therefore, instead of sending an image classification request one by one, we can _batch them_/bundle them together as much as we can and then send it over.

We can define the `batch_size` and `batch_timeout` with `Nx.Serving`.
We're going to use the default values, hence why we're not explicitly defining them.

With `Nx.Serving`, we define a `serving/0` function
that is then used by it, which in turn is executed in the supervision tree since we declare it as a child in the Application module.

In the `serving/0` function, we are loading the[`ResNet-50`](https://huggingface.co/microsoft/resnet-50) model and its featurizer.

> [!NOTE]
> A `featurizer` can be seen as a
> [`Feature Extractor`](https://huggingface.co/docs/transformers/main_classes/feature_extractor).
> It is essentially a component that is responsible for converting input data
> into a format that can be processed by a pre-trained language model.
>
> It takes raw information and performs various transformations,
> such as
> [tokenization](https://neptune.ai/blog/tokenization-in-nlp),
> [padding](https://www.baeldung.com/cs/deep-neural-networks-padding),
> and encoding to prepare the data for model training or inference.

Lastly, this function returns a serving for image classification by calling [`image_classification/3`](https://hexdocs.pm/bumblebee/Bumblebee.Vision.html#image_classification/3), where we can define our compiler and task batch size.
We gave our serving function the name `ImageClassifier` as declared in the Application module.

#### 4.2 `Async` processing the image for classification

Now we're ready to send the image to the model
and get a prediction of it!

Every time we upload an image,
we are going to run **async processing**.
This means that the task responsible for image classification will be run in another process, thus asynchronously, meaning that the LiveView _won't have to wait_ for this task to finish
to continue working.

For this scenario, we are going to be using the
[`Task` module](https://hexdocs.pm/elixir/1.14/Task.html) to spawn processes to complete this task.

Go to `lib/app_web/live/page_live.ex`
and change the following code.

```elixir
def handle_progress(:image_list, entry, socket) when entry.done? do
    # Consume the entry and get the tensor to feed to classifier
    tensor = consume_uploaded_entry(socket, entry, fn %{} = meta ->
      {:ok, vimage} = Vix.Vips.Image.new_from_file(meta.path)
      pre_process_image(vimage)
    end)

    # Create an async task to classify the image
    task = Task.async(fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)

    # Update socket assigns to show spinner whilst task is running
    {:noreply, assign(socket, upload_running?: true, task_ref: task.ref)}
end

@impl true
def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket) do
  # This is called everytime an Async Task is created.
  # We flush it here.
  Process.demonitor(ref, [:flush])

  # And then destructure the result from the classifier.
  %{predictions: [%{label: label}]} = result

  # Update the socket assigns with result and stopping spinner.
  {:noreply, assign(socket, label: label, upload_running?: false)}
end
```

> [!NOTE]
> The `pre_process_image/1` function is yet to be defined.
> We'll do that in the following section.

In the `handle_progress/3` function,
whilst we are consuming the image,
we are first converting it to a
[`Vix.Vips.Image`](https://hexdocs.pm/vix/Vix.Vips.Image.html) `Struct`
using the file path.
We then feed this image to the `pre_process_image/1` function that we'll implement later.

What's important is to notice this line:

```elixir
task = Task.async(fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)
```

We are using
[`Task.async/1`](https://hexdocs.pm/elixir/1.12/Task.html#async/1)
to call our `Nx.Serving` build function `ImageClassifier` we've defined earlier,
thus initiating a batched run with the image tensor.
While the task is spawned,
we update the socket assigns with the reference to the task (`:task_ref`)
and update the `:upload_running?` assign to `true`,
so we can show a spinner or a loading animation.

When the task is spawned using `Task.async/1`,
a couple of things happen in the background.
The new process is monitored by the caller (our `LiveView`),
which means that the caller will receive a
`{:DOWN, ref, :process, object, reason}`
message once the process it is monitoring dies.
And, a link is created between both processes.

Therefore,
we **don't need to use**
[**`Task.await/2`**](https://hexdocs.pm/elixir/1.12/Task.html#await/2).
Instead, we create a new handler to receive the aforementioned.
That's what we're doing in the
`handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket)` function.
The received message contains a `{ref, result}` tuple,
where `ref` is the monitor’s reference.
We use this reference to stop monitoring the task,
since we received the result we needed from our task
and we can discard an exit message.

In this same function, we destructure the prediction
from the model and assign it to the socket assign `:label`
and set `:upload_running?` to `false`.

Quite beautiful, isn't it?
With this, we don't have to worry if the person closes the browser tab.
The process dies (as does our `LiveView`),
and the work is automatically cancelled,
meaning no resources are spent
on a process for which nobody expects a result anymore.

##### 4.2.1 Considerations regarding `async` processes

When a task is spawned using `Task.async/2`,
**it is linked to the caller**.
Which means that they're related:
if one dies, the other does too.

We ought to take this into account when developing our application.
If we don't have control over the result of the task,
and we don't want our `LiveView` to crash if the task crashes,
we must use a different alternative to spawn our task -
[`Task.Supervisor.async_nolink/3`](https://hexdocs.pm/elixir/1.14/Task.Supervisor.html#async_nolink/3)
can be used for this effect,
meaning we can use it if we want to make sure
our `LiveView` won't die and the error is reported,
even if the task crashes.

We've chosen `Task.async/2` for this very reason.
We are doing something **that takes time/is expensive**
and we **want to stop the task if `LiveView` is closed/crashes**.
However, if you are building something
like a report that has to be generated even if the person closes the browser tab,
this is not the right solution.

##### 4.2.2 Alternative for better testing

We are spawning async tasks by calling `Task.async/1`.
This is creating an **_unsupervised_ task**.
Although it's plausible for this simple app,
it's best for us to create a
[**`Supervisor`**](https://hexdocs.pm/elixir/1.15.7/Supervisor.html)
that manages their child tasks.
This gives more control over the execution
and lifetime of the child tasks.

Additionally, it's better to have these tasks supervised
because it makes it possible to create tests for our `LiveView`.
For this, we need to make a couple of changes.

First, head over to `lib/app/application.ex`
and add a supervisor to the `start/2` function children array.

```elixir
def start(_type, _args) do
  children = [
    AppWeb.Telemetry,
    {Phoenix.PubSub, name: App.PubSub},
    {Nx.Serving, serving: serving(), name: ImageClassifier},
    {Task.Supervisor, name: App.TaskSupervisor},      # add this line
    AppWeb.Endpoint
  ]

  opts = [strategy: :one_for_one, name: App.Supervisor]
  Supervisor.start_link(children, opts)
end
```

We are creating a [`Task.Supervisor`](https://hexdocs.pm/elixir/Supervisor.html)
with the name `App.TaskSupervisor`.

Now, in `lib/app_web/live/page_live.ex`,
we create the async task like so:

```elixir
task = Task.Supervisor.async(App.TaskSupervisor, fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)
```

We are now using
[`Task.Supervisor.async`](https://hexdocs.pm/elixir/1.15.7/Task.Supervisor.html#async/3),
passing the name of the supervisor defined earlier.

And that's it!
We are creating async tasks like before,
the only difference is that they're now **supervised**.

In tests, you can create a small module that waits for the tasks to be completed.

```elixir
defmodule AppWeb.SupervisorSupport do

  @moduledoc """
    This is a support module helper that is meant to wait for all the children of a supervisor to complete.
    If you go to `lib/app/application.ex`, you'll see that we created a `TaskSupervisor`, where async tasks are spawned.
    This module helps us to wait for all the children to finish during tests.
  """

  @doc """
    Find all children spawned by this supervisor and wait until they finish.
  """
  def wait_for_completion() do
    pids = Task.Supervisor.children(App.TaskSupervisor)
    Enum.each(pids, &Process.monitor/1)
    wait_for_pids(pids)
  end

  defp wait_for_pids([]), do: nil
  defp wait_for_pids(pids) do
    receive do
      {:DOWN, _ref, :process, pid, _reason} -> wait_for_pids(List.delete(pids, pid))
    end
  end
end
```

You can call `AppWeb.SupervisorSupport.wait_for_completion()`
in unit tests so they wait for the tasks to complete.
In our case,
we do that until the _prediction is made_.

#### 4.3 Image pre-processing

As we've noted before,
we need to **pre-process the image before passing it to the model**.
For this, we have three main steps:

- removing the [`alpha` ](https://en.wikipedia.org/wiki/Alpha_compositing)
  out of the image, flattening it out.
- convert the image to `sRGB` [colourspace](https://en.wikipedia.org/wiki/Color_space).
  This is needed to ensure that the image is consistent
  and aligns with the model's training data images.
- set the representation of the image as a `Tensor`
  to `height, width, bands`.
  The image tensor will then be organized as a three-dimensional array,
  where the first dimension represents the height of the image,
  the second refers to the width of the image,
  and the third pertains to the different
  [spectral bands/channels of the image](https://en.wikipedia.org/wiki/Multispectral_imaging).

Our `pre_process_image/1` function will implement these three steps.
Let's implement it now! <br />
In `lib/app_web/live/page_live.ex`,
add the following:

```elixir
  defp pre_process_image(%Vimage{} = image) do

    # If the image has an alpha channel, flatten it:
    {:ok, flattened_image} = case Vix.Vips.Image.has_alpha?(image) do
      true -> Vix.Vips.Operation.flatten(image)
      false -> {:ok, image}
    end

    # Convert the image to sRGB colourspace ----------------
    {:ok, srgb_image} = Vix.Vips.Operation.colourspace(flattened_image, :VIPS_INTERPRETATION_sRGB)

    # Converting image to tensor ----------------
    {:ok, tensor} = Vix.Vips.Image.write_to_tensor(srgb_image)

    # We reshape the tensor given a specific format.
    # In this case, we are using {height, width, channels/bands}.
    %Vix.Tensor{data: binary, type: type, shape: {x, y, bands}} = tensor
    format = [:height, :width, :bands]
    shape = {x, y, bands}

    final_tensor =
      binary
      |> Nx.from_binary(type)
      |> Nx.reshape(shape, names: format)

    {:ok, final_tensor}
  end
```

The function receives a `Vix` image,
as detailed earlier.
We use [`flatten/1`](https://hexdocs.pm/vix/Vix.Vips.Operation.html#flatten/2)
to flatten the alpha out of the image.

The resulting image has its colourspace changed
by calling [`colourspace/3`](https://hexdocs.pm/vix/Vix.Vips.Operation.html#colourspace/3),
where we change the to `sRGB`.

The colourspace-altered image is then converted to a
[tensor](https://hexdocs.pm/vix/Vix.Tensor.html),
by calling
[`write_to_tensor/1`](https://hexdocs.pm/vix/Vix.Vips.Image.html#write_to_tensor/1).

We then
[reshape](https://hexdocs.pm/nx/Nx.html#reshape/3)
the tensor according to the format that was previously mentioned.

This function returns the processed tensor,
that is then used as input to the model.

### 4.4 Updating the view

All that's left is updating the view
to reflect these changes we've made to the `LiveView`.
Head over to `lib/app_web/live/page_live.html.heex`
and change it to this.

```html
<.flash_group flash={@flash} />
<div
  class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32"
>
  <div
    class="flex justify-center items-center mx-auto max-w-xl w-[50vw] lg:mx-0"
  >
    <div class="space-y-12">
      <div class="border-gray-900/10 pb-12">
        <h2 class="text-base font-semibold leading-7 text-gray-900">
          Image Classification
        </h2>
        <p class="mt-1 text-sm leading-6 text-gray-600">
          Do simple classification with this
          <a
            href="https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html"
            class="font-mono font-medium text-sky-500"
            >LiveView</a
          >
          demo, powered by
          <a
            href="https://github.com/elixir-nx/bumblebee"
            class="font-mono font-medium text-sky-500"
            >Bumblebee</a
          >.
        </p>

        <!-- File upload section -->
        <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
          <div class="col-span-full">
            <div
              class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
              phx-drop-target="{@uploads.image_list.ref}"
            >
              <div class="text-center">
                <svg
                  class="mx-auto h-12 w-12 text-gray-300"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                    clip-rule="evenodd"
                  />
                </svg>
                <div class="mt-4 flex text-sm leading-6 text-gray-600">
                  <label
                    for="file-upload"
                    class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                  >
                    <form id="upload-form" phx-change="noop" phx-submit="noop">
                      <label class="cursor-pointer">
                        <.live_file_input upload={@uploads.image_list}
                        class="hidden" /> Upload
                      </label>
                    </form>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs leading-5 text-gray-600">
                  PNG, JPG, GIF up to 5MB
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Prediction text -->
        <div
          class="mt-6 flex space-x-1.5 items-center font-bold text-gray-900 text-xl"
        >
          <span>Description: </span>
          <!-- Spinner -->
          <%= if @upload_running? do %>
          <div role="status">
            <div
              class="relative w-6 h-6 animate-spin rounded-full bg-gradient-to-r from-purple-400 via-blue-500 to-red-400 "
            >
              <div
                class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-gray-200 rounded-full border-2 border-white"
              ></div>
            </div>
          </div>
          <% else %> <%= if @label do %>
          <span class="text-gray-700 font-light"><%= @label %></span>
          <% else %>
          <span class="text-gray-300 font-light">Waiting for image input.</span>
          <% end %> <% end %>
        </div>
      </div>
    </div>
  </div>
</div>
```

In these changes,
we've added the output of the model in the form of text.
We are rendering a spinner
if the `:upload_running?` socket assign is set to true.
Otherwise,
we add the `:label`, which holds the prediction made by the model.

You may have also noticed that
we've changed the `phx` event handlers
to `noop`.
This is simply to simplify the `LiveView`.

Head over to `lib/app_web/live/page_live.ex`.
You can now remove the `"validate"`, `"save"`
and `"remove-selected"` handlers,
because we're not going to be needing them.
Replace them with this handler:

```elixir
  @impl true
  def handle_event("noop", _params, socket) do
    {:noreply, socket}
  end
```

#### 4.5 Check it out!

And that's it!
Our app is now _functional_ 🎉.

If you run the app,
you can drag and drop or select an image.
After this, a task will be spawned that will run the model
against the image that was submitted.

Once a prediction is made, display it!

<p align="center">
  <img src="https://github.com/dwyl/aws-sdk-mock/assets/17494745/894b988e-4f60-4781-8838-c7fd95e571f0" />
</p>

You can and **should** try other models.
`ResNet-50` is just one of the many that are supported by `Bumblebee`.
You can see the supported models at https://github.com/elixir-nx/bumblebee#model-support.

#### 4.6 Considerations on user images

To keep the app as simple as possible,
we are receiving the image from the person as is.
Although we are processing the image,
we are doing it so **it is processable by the model**.

We have to understand that:

- in most cases, **full-resolution images are not necessary**,
  because neural networks work on much smaller inputs
  (e.g. `ResNet-50` works with `224px x 224px` images).
  This means that a lot of data is unnecessarily uploaded over the network,
  increasing workload on the server to potentially downsize a large image.
- decoding an image requires an additional package,
  meaning more work on the server.

We can avoid both of these downsides by moving this work to the client.
We can leverage the
[`Canvas API` ](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
to decode and downsize this image on the client-side,
reducing server workload.

You can see an example implementation of this technique
in `Bumblebee`'s repository
at https://github.com/elixir-nx/bumblebee/blob/main/examples/phoenix/image_classification.exs

However, since we are not using `JavaScript` for anything,
we can (and _should_!) properly downsize our images
so they better fit the training dataset of the model we use.
This will allow the model to process faster
since larger images carry over more data that is ultimately unnecessary
for models to make predictions.

Open
`lib/app_web/live/page_live.ex`,
find the `handle_progress/3` function
and change resize the image _before processing it_.

```elixir
    file_binary = File.read!(meta.path)

    # Get image and resize
    # This is dependant on the resolution of the model's dataset.
    # In our case, we want the width to be closer to 640, whilst maintaining aspect ratio.
    width = 640
    {:ok, thumbnail_vimage} = Vix.Vips.Operation.thumbnail(meta.path, width, size: :VIPS_SIZE_DOWN)

    # Pre-process it
    {:ok, tensor} = pre_process_image(thumbnail_vimage)

    #...
```

We are using
[`Vix.Vips.Operation.thumbnail/3`](https://hexdocs.pm/vix/Vix.Vips.Operation.html#thumbnail/3)
to resize our image to a fixed width
whilst maintaining aspect ratio.
The `width` variable can be dependent on the model that you use.
For example, `ResNet-50` is trained on `224px224` pictures,
so you may want to resize the image to this width.

> **Note**: We are using the `thumbnail/3` function
> instead of `resize/3` because it's _much_ faster. <br />
> Check
> https://github.com/libvips/libvips/wiki/HOWTO----Image-shrinking
> to know why.

### 5. Final Touches

Although our app is functional,
we can make it **better**. 🎨

#### 5.1 Setting max file size

In order to better control user input,
we should add a limit to the size of the image that is being uploaded.
It will be easier on our server and ultimately save costs.

Let's add a cap of `5MB` to our app!
Fortunately for you, this is super simple!
You just need to add the `max_file_size`
to the `allow_uploads/2` function
when mounting the `LiveView`!

```elixir
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(label: nil, upload_running?: false, task_ref: nil)
     |> allow_upload(:image_list,
       accept: ~w(image/*),
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1,
       chunk_size: 64_000,
       max_file_size: 5_000_000    # add this
     )}
  end
```

And that's it!
The number is in `bytes`,
hence why we set it as `5_000_000`.

#### 5.2 Show errors

In case a person uploads an image that is too large,
we should show this feedback to the person!

For this, we can leverage the
[`upload_errors/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#upload_errors/2)
function.
This function will return the entry errors for an upload.
We need to add a handler for one of these errors to show it first.

Head over `lib/app_web/live/page_live.ex`
and add the following line.

```elixir
  def error_to_string(:too_large), do: "Image too large. Upload a smaller image up to 5MB."
```

Now, add the following section below the upload form
inside `lib/app_web/live/page_live.html.heex`.

```html
<!-- Show errors -->
<%= for entry <- @uploads.image_list.entries do %>
<div class="mt-2">
  <%= for err <- upload_errors(@uploads.image_list, entry) do %>
  <div class="rounded-md bg-red-50 p-4 mb-2">
    <div class="flex">
      <div class="flex-shrink-0">
        <svg
          class="h-5 w-5 text-red-400"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
            clip-rule="evenodd"
          />
        </svg>
      </div>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-red-800">
          <%= error_to_string(err) %>
        </h3>
      </div>
    </div>
  </div>
  <% end %>
</div>
<% end %>
```

We are iterating over the errors returned by `upload_errors/2`
and invoking `error_to_string/1`,
which we've just defined in our `LiveView`.

Now, if you run the app
and try to upload an image that is too large,
an error will show up.

Awesome! 🎉

<p align="center">
  <img width=800 src="https://github.com/dwyl/aws-sdk-mock/assets/17494745/1bf903eb-31d5-48a4-9da9-1f5f64932b6e" />
</p>

#### 5.3 Show image preview

As of now, even though our app predicts the given images,
it is not showing a preview of the image the person submitted.
Let's fix this 🛠️.

Let's add a new socket assign variable
pertaining to the [base64](https://en.wikipedia.org/wiki/Base64) representation
of the image in `lib/app_web/live_page/live.ex`

```elixir
     |> assign(label: nil, upload_running?: false, task_ref: nil, image_preview_base64: nil)
```

We've added `image_preview_base64`
as a new socket assign,
initializing it as `nil`.

Next, we need to _read the file while consuming it_,
and properly update the socket assign
so we can show it to the person.

In the same file,
change the `handle_progress/3` function to the following.

```elixir
  def handle_progress(:image_list, entry, socket) when entry.done? do
      # Consume the entry and get the tensor to feed to classifier
      %{tensor: tensor, file_binary: file_binary} = consume_uploaded_entry(socket, entry, fn %{} = meta ->
        file_binary = File.read!(meta.path)

        {:ok, vimage} = Vix.Vips.Image.new_from_file(meta.path)
        {:ok, tensor} = pre_process_image(vimage)
        {:ok, %{tensor: tensor, file_binary: file_binary}}
      end)

      # Create an async task to classify the image
      task = Task.Supervisor.async(App.TaskSupervisor, fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)

      # Encode the image to base64
      base64 = "data:image/png;base64, " <> Base.encode64(file_binary)

      # Update socket assigns to show spinner whilst task is running
      {:noreply, assign(socket, upload_running?: true, task_ref: task.ref, image_preview_base64: base64)}
  end
```

We're using [`File.read!/1`](https://hexdocs.pm/elixir/1.13/File.html#read/1)
to retrieve the binary representation of the image that was uploaded.
We use [`Base.encode64/2`](https://hexdocs.pm/elixir/1.12/Base.html#encode64/2)
to encode this file binary
and assign the newly created `image_preview_base64` socket assign
with this base64 representation of the image.

Now, all that's left to do
is to _render the image on our view_.
In `lib/app_web/live/page_live.html.heex`,
locate the line:

```html
<div class="text-center"></div>
```

We are going to update this `<div>`
to show the image with the `image_preview_base64` socket assign.

```html
<div class="text-center">
  <!-- Show image preview -->
  <%= if @image_preview_base64 do %>
  <form id="upload-form" phx-change="noop" phx-submit="noop">
    <label class="cursor-pointer">
      <.live_file_input upload={@uploads.image_list} class="hidden" />
      <img src="{@image_preview_base64}" />
    </label>
  </form>
  <% else %>
  <svg
    class="mx-auto h-12 w-12 text-gray-300"
    viewBox="0 0 24 24"
    fill="currentColor"
    aria-hidden="true"
  >
    <path
      fill-rule="evenodd"
      d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
      clip-rule="evenodd"
    />
  </svg>
  <div class="mt-4 flex text-sm leading-6 text-gray-600">
    <label
      for="file-upload"
      class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
    >
      <form id="upload-form" phx-change="noop" phx-submit="noop">
        <label class="cursor-pointer">
          <.live_file_input upload={@uploads.image_list} class="hidden" />
          Upload
        </label>
      </form>
    </label>
    <p class="pl-1">or drag and drop</p>
  </div>
  <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 5MB</p>
  <% end %>
</div>
```

As you can see,
we are checking if `@image_preview_base64` is defined.
If so, we simply show the image with it as `src` 😊.

Now, if you run the application,
you'll see that after dragging the image,
it is previewed and shown to the person!

<p align="center">
  <img width=800 src="https://github.com/dwyl/image-classifier/assets/17494745/2835c24f-f4ba-48bc-aab0-6b39830156ce" />
</p>

### 6. What about other models?

Maybe you weren't happy with the results from this model.

That's fair. `ResNet-50` is a smaller, "older" model compared to other
image captioning/classification models.

What if you wanted to use others?
Well, as we've mentioned before,
`Bumblebee` uses
[**Transformer models from `HuggingFace`**](https://huggingface.co/docs/transformers/index).
To know if one is supported
(as shown in [`Bumblebee`'s docs](https://github.com/elixir-nx/bumblebee#model-support)),
we need to check the `config.json` file
in the model repository
and copy the class name under `"architectures"`
and search it on `Bumblebee`'s codebase.

For example,
here's one of the more popular image captioning models -
Salesforce's `BLIP` -
https://huggingface.co/Salesforce/blip-image-captioning-large/blob/main/config.json.

<p align="center">
  <img width="48%" src="https://github.com/elixir-nx/bumblebee/assets/17494745/33dc869f-37f7-4d18-b126-3a0bd0d578d3" />
  <img width="48%" src="https://github.com/elixir-nx/bumblebee/assets/17494745/8f1d115c-171b-42bf-b974-08172c957a09" />
</p>

If you visit `Bumblebee`'s codebase
and search for the class name,
you'll find it is supported.

<p align="center">
  <img width="800" src="https://github.com/elixir-nx/bumblebee/assets/17494745/500eb97b-c20a-4c9a-846e-327cdcd1c37c" />
</p>

Awesome!
Now we can use it!

If you dig around `Bumblebee`'s docs as well
(https://hexdocs.pm/bumblebee/Bumblebee.Vision.html#image_to_text/5),
you'll see that we've got to use `image_to_text/5` with this model.
It needs a `tokenizer`, `featurizer` and a `generation-config`
so we can use it.

Let's do it!
Head over to `lib/app/application.ex`,
and change the `serving/0` function.

```elixir
  def serving do
    {:ok, model_info} = Bumblebee.load_model({:hf, "Salesforce/blip-image-captioning-base"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "Salesforce/blip-image-captioning-base"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "Salesforce/blip-image-captioning-base"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "Salesforce/blip-image-captioning-base"})

    Bumblebee.Vision.image_to_text(model_info, featurizer, tokenizer, generation_config,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA]
    )
  end
```

As you can see, we're using the repository name of `BLIP`'s model
from the HuggingFace website.

If you run `mix phx.server`,
you'll see that it will download the new models,
tokenizers, featurizer and configs to run the model.

```sh
|======================================================================| 100% (989.82 MB)
[info] TfrtCpuClient created.
|======================================================================| 100% (711.39 KB)
[info] Running AppWeb.Endpoint with cowboy 2.10.0 at 127.0.0.1:4000 (http)
[info] Access AppWeb.Endpoint at http://localhost:4000
[watch] build finished, watching for changes...
```

You may think we're done here.
But we are not! ✋

The **destructuring of the output of the model may not be the same**. <br />
If you try to submit a photo,
you'll get this error:

```sh
no match of right hand side value:
%{results: [%{text: "a person holding a large blue ball on a beach"}]}
```

This means that we need to make some changes
when parsing the output of the model 😀.

Head over to `lib/app_web/live/page_live.ex`
and change the `handle_info/3` function
that is called after the async task is completed.

```elixir
  def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket) do
    Process.demonitor(ref, [:flush])

    %{results: [%{text: label}]} = result # change this line

    {:noreply, assign(socket, label: label, upload_running?: false)}
  end
```

As you can see, we are now correctly destructuring the result from the model.
And that's it!

If you run `mix phx.server`,
you'll see that we got far more accurate results!

<p align="center">
  <img width="800" src="https://github.com/elixir-nx/bumblebee/assets/17494745/0cae2db0-5ca4-4434-9c63-76aadb7d578b" />
</p>

Awesome! 🎉

> [!NOTE]
> Be aware that `BLIP`
> is a _much_ larger model than `ResNet-50`.
> There are more accurate and even larger models out there
> (e.g:
> [`blip-image-captioning-large`](https://huggingface.co/Salesforce/blip-image-captioning-large),
> the larger version of the model we've just used).
> This is a balancing act: the larger the model, the longer a prediction may take
> and more resources your server will need to have to handle this heavier workload.

> [!WARNING]
>
> We've created a small module that allows you to have multiple models
> cached and downloaded and keep this logic contained.
>
> For this, check the [`deployment guide`](./deployment.md#5-a-better-model-management).

### 7. How do I deploy this thing?

There are a few considerations you may want to have
before considering deploying this.
Luckily for you,
we've created a small document
that will **guide you through deploying this app in `fly.io`**!

Check the [`deployment.md`](./deployment.md) file for more information.

### 8. Showing example images

> [!WARNING]
>
> This section assumes you've made the changes made in the previous section.
> Therefore, you should follow the instructions in
> [`7. How do I deploy this thing?`](#7-how-do-i-deploy-this-thing)
> and come back after you're done.

We have a fully functioning application that predicts images.
Now we can add some cool touches to show the person
some examples if they are inactive.

For this,
we are going to need to make **three changes**.

- create a hook in the **client** (`Javascript`)
  to send an event when there's inactivity after
  a given number of seconds.
- change `page_live.ex` **LiveView** to accommodate
  this new event.
- change the **view** m `page_live.html.heex`
  to show these changes to the person.

Let's go over each one!

#### 8.1 Creating a hook in client

We are going to detect the inactivity of the person
with some `Javascript` code.

Head over to `assets/js/app.js`
and change it to the following.

```js
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

// Hooks to track inactivity
let Hooks = {};
Hooks.ActivityTracker = {
  mounted() {
    // Set the inactivity duration in milliseconds
    const inactivityDuration = 8000; // 8 seconds

    // Set a variable to keep track of the timer and if the process to predict example image has already been sent
    let inactivityTimer;
    let processHasBeenSent = false;

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

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
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
```

- we have added a `Hooks` variable,
  with a property **`ActivityTracker`**.
  This hook has the `mounted()` function
  that is executed when the component that is hooked with this hook is mounted.
  You can find more information at https://hexdocs.pm/phoenix_live_view/js-interop.html.
- inside the `mounted()` function,
  we create a `resetInactivityTimer()` function
  that is executed every time the
  **mouse moves** (`mousemove` event)
  and a **key is pressed**(`keydown`).
  This function resets the timer
  that is run whilst there is a lack of inactivity.
- if the person is inactive for _8 seconds_,
  we create an event `"show_examples"`.
  We will create a handler in the LiveView
  to handle this event later.
- we add the `Hooks` variable to the `hooks`
  property when initializing the `livesocket`.

And that's it!

For this hook to _actually be executed_,
we need to create a component that uses it
inside our view file.

For this, we can simply create a hidden component
on top of the `lib/app_web/live/page_live.html.heex` file.

Add the following hidden component.

```html
<div class="hidden" id="tracker_el" phx-hook="ActivityTracker" />
```

We use the `phx-hook` attribute
to bind the hook we've created in our `app.js` file
to the component so it's executed.
When this component is mounted,
the `mounted()` function inside the hook
is executed.

And that's it! 👏

Your app won't work yet because
we haven't created a handler
to handle the `"show_examples"` event.

Let's do that right now!

### 8.2 Handling the example images list event inside our LiveView

Now that we have our client sorted,
let's head over to our LiveView
at `lib/app_web/live/page_live.ex`
and make the needed changes!

Before anything,
let's add socket assigns that we will need throughout our adventure!
On top of the file,
change the socket assigns to the following.

```elixir
  socket
    |> assign(
      # Related to the file uploaded by the user
      label: nil,
      upload_running?: false,
      task_ref: nil,
      image_preview_base64: nil,

      # Related to the list of image examples
      example_list_tasks: [],
      example_list: [],
      display_list?: false
    )
```

We've added **three new assigns**:

- **`example_list_tasks`** is a list of
  the async tasks that are created for each example image.
- **`example_list`** is a list of the example images
  with their respective predictions.
- **`display_list?`** is a boolean that
  tells us if the list is to be shown or not.

Awesome! Let's continue.

As we've mentioned before,
we need to create a handler for our `"show_examples"` event.

Add the following function to the file.

```elixir

  @image_width 640

  def handle_event("show_examples", _data, socket) do

    # Only run if the user hasn't uploaded anything
    if(is_nil(socket.assigns.task_ref)) do
      # Retrieves a random image from Unsplash with a given `image_width` dimension
      random_image = "https://source.unsplash.com/random/#{@image_width}x#{@image_width}"

      # Spawns prediction tasks for example image from random Unsplash image
      tasks = for _ <- 1..2 do
        {:req, body} = {:req, Req.get!(random_image).body}
        predict_example_image(body)
      end


      # List to change `example_list` socket assign to show skeleton loading
      display_example_images = Enum.map(tasks, fn obj -> %{predicting?: true, ref: obj.ref} end)

      # Updates the socket assigns
      {:noreply, assign(socket, example_list_tasks: tasks, example_list: display_example_images)}

    else
      {:noreply, socket}
    end
  end

```

> [!WARNING]
>
> We are using the
> [`req`](https://github.com/wojtekmach/req) package
> to download the file binary from the URL.
> Make sure to install it in the `mix.exs` file.

- we are using the [Unsplash API](https://unsplash.com/developers),
  an _awesome_ image API with lots of photos!
  They provide a `/random` URL that yields a random photo.
  In this URL we can inclusively define the dimensions we want!
  That's what we're doing in the first line of the function.
  We are using a module constant `@image_width 640` on top of the file,
  so add that to the top of the file.
  This function is relevant because we preferably want to deal
  with images that are in the same resolution as the dataset the model was trained in.
- we are creating **two async tasks** that retrieve the binary of the image
  and pass it on to a `predict_example_image/1` function
  (we will create this function next).
- the two tasks that we've created are in an array `tasks`.
  We create _another array_ `display_example_images` with the same number of elements as `tasks`,
  which will have two properties:
  **`predicting`**, meaning if the image is being predicted by the model;
  and **`ref`**, the reference of the task.
- we assign the `tasks` array to the `example_list_tasks` socket assign
  and `display_example_images` array to the `example_list` array.
  So `example_list` will temporarily hold
  objects with `:predicting` and `:ref` properties
  whilst the model is being executed.

As we've just mentioned,
we are making use of a function called
`predict_example_image/1` to make predictions
of a given file binary.

Let's implement it now!
In the same file, add:

```elixir
  def predict_example_image(body) do
    with {:vix, {:ok, img_thumb}} <-
           {:vix, Vix.Vips.Operation.thumbnail_buffer(body, @image_width)},
         {:pre_process, {:ok, t_img}} <-
           {:pre_process, pre_process_image(img_thumb)} do

      # Create an async task to classify the image from unsplash
      Task.Supervisor.async(App.TaskSupervisor, fn ->
        Nx.Serving.batched_run(ImageClassifier, t_img)
      end)
      |> Map.merge(%{base64_encoded_url: "data:image/png;base64, " <> Base.encode64(body)})

    else
      {stage, error} -> {stage, error}
    end
  end
```

For the body of the image to be executed by the model,
it needs to go through some pre-processing.

- we are using [`thumbnail_buffer/3`](https://hexdocs.pm/vix/Vix.Vips.Operation.html#thumbnail_buffer/3)
  to make sure it's properly resized
  and then feeding the result to our own implemented
  `pre_process_image/1` function
  so it can be converted to a parseable tensor by the model.
- after these two operations are successfully completed,
  we spawn two async tasks (like we've done before)
  and feed it to the model.
  We add the base64-encoded image
  to the return value so it can later be shown to the person.
- if these operations fail, we return an error.

Great job! 👏

Our example images async tasks have successfully been created
and are on their way to the model!

Now we need to handle these newly created async tasks
once they are completed.
As we know, we are handling our async tasks completion
in the `def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket)` function.
Let's change it like so.

```elixir
  def handle_info({ref, result}, %{assigns: assigns} = socket) do
    # Flush async call
    Process.demonitor(ref, [:flush])

    # You need to change how you destructure the output of the model depending
    # on the model you've chosen for `prod` and `test` envs on `models.ex`.)
    label =
      case Application.get_env(:app, :use_test_models, false) do
        true ->
          App.Models.extract_test_label(result)

        # coveralls-ignore-start
        false ->
          App.Models.extract_prod_label(result)
        # coveralls-ignore-stop
      end

    cond do

      # If the upload task has finished executing, we update the socket assigns.
      Map.get(assigns, :task_ref) == ref ->
        {:noreply, assign(socket, label: label, upload_running?: false)}

      # If the example task has finished executing, we upload the socket assigns.
      img = Map.get(assigns, :example_list_tasks) |> Enum.find(&(&1.ref == ref)) ->

        # Update the element in the `example_list` enum to turn "predicting?" to `false`
        updated_example_list = Map.get(assigns, :example_list)
        |> Enum.map(fn obj ->
          if obj.ref == img.ref do
            Map.put(obj, :base64_encoded_url, img.base64_encoded_url)
            |> Map.put(:label, label)
            |> Map.put(:predicting?, false)

          else
            obj
          end end)

        {:noreply,
         assign(socket,
           example_list: updated_example_list,
           upload_running?: false,
           display_list?: true
         )}
    end
  end
```

The only change we've made is that
we've added a [`cond`](https://hexdocs.pm/elixir/1.16/case-cond-and-if.html#cond)
flow structure.
We are essentially checking
if the task reference that has been completed
is **from the uploaded image from the person** (`:task_ref` socket assign)
or **from an example image** (inside the `:example_list_tasks` socket assign list).

If it's the latter,
we retrieve we are updating
the `example_list` socket assign list
with the **prediction** (`:label`),
the **base64-encoded image from the task list** (`:base64_encoded_url`)
and setting the `:predicting` property to `false`.

And that's it!
Great job! 🥳

#### 8.3 Updating the view

Now that we've made all the necessary changes to our LiveView,
we need to update our view so it reflects them!

Head over to `lib/app_web/live/page_live.html.heex`
and change it to the following piece of code.

```html
<div class="hidden" id="tracker_el" phx-hook="ActivityTracker" />
<div
  class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-24 lg:px-8 xl:px-28 xl:py-32"
>
  <div class="flex flex-col justify-start">
    <div class="flex justify-center items-center w-full">
      <div class="2xl:space-y-12">
        <div class="mx-auto max-w-2xl lg:text-center">
          <p>
            <span
              class="rounded-full w-fit bg-brand/5 px-2 py-1 text-[0.8125rem] font-medium text-center leading-6 text-brand"
            >
              <a
                href="https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html"
                target="_blank"
                rel="noopener noreferrer"
              >
                🔥 LiveView
              </a>
              +
              <a
                href="https://github.com/elixir-nx/bumblebee"
                target="_blank"
                rel="noopener noreferrer"
              >
                🐝 Bumblebee
              </a>
            </span>
          </p>
          <p
            class="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl"
          >
            Caption your image!
          </p>
          <h3 class="mt-6 text-lg leading-8 text-gray-600">
            Upload your own image (up to 5MB) and perform image captioning with
            <a
              href="https://elixir-lang.org/"
              target="_blank"
              rel="noopener noreferrer"
              class="font-mono font-medium text-sky-500"
            >
              Elixir
            </a>
            !
          </h3>
          <p class="text-lg leading-8 text-gray-400">
            Powered with
            <a
              href="https://elixir-lang.org/"
              target="_blank"
              rel="noopener noreferrer"
              class="font-mono font-medium text-sky-500"
            >
              HuggingFace🤗
            </a>
            transformer models, you can run this project locally and perform
            machine learning tasks with a handful lines of code.
          </p>
        </div>
        <div class="border-gray-900/10">
          <!-- File upload section -->
          <div class="col-span-full">
            <div
              class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
              phx-drop-target="{@uploads.image_list.ref}"
            >
              <div class="text-center">
                <!-- Show image preview -->
                <%= if @image_preview_base64 do %>
                <form id="upload-form" phx-change="noop" phx-submit="noop">
                  <label class="cursor-pointer">
                    <.live_file_input upload={@uploads.image_list}
                    class="hidden" />
                    <img src="{@image_preview_base64}" />
                  </label>
                </form>
                <% else %>
                <svg
                  class="mx-auto h-12 w-12 text-gray-300"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                    clip-rule="evenodd"
                  />
                </svg>
                <div class="mt-4 flex text-sm leading-6 text-gray-600">
                  <label
                    for="file-upload"
                    class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                  >
                    <form id="upload-form" phx-change="noop" phx-submit="noop">
                      <label class="cursor-pointer">
                        <.live_file_input upload={@uploads.image_list}
                        class="hidden" /> Upload
                      </label>
                    </form>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs leading-5 text-gray-600">
                  PNG, JPG, GIF up to 5MB
                </p>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        <!-- Show errors -->
        <%= for entry <- @uploads.image_list.entries do %>
        <div class="mt-2">
          <%= for err <- upload_errors(@uploads.image_list, entry) do %>
          <div class="rounded-md bg-red-50 p-4 mb-2">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-red-400"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">
                  <%= error_to_string(err) %>
                </h3>
              </div>
            </div>
          </div>
          <% end %>
        </div>
        <% end %>
        <!-- Prediction text -->
        <div
          class="flex mt-2 space-x-1.5 items-center font-bold text-gray-900 text-xl"
        >
          <span>Description: </span>
          <!-- Spinner -->
          <%= if @upload_running? do %>
          <div role="status">
            <div
              class="relative w-6 h-6 animate-spin rounded-full bg-gradient-to-r from-purple-400 via-blue-500 to-red-400 "
            >
              <div
                class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-gray-200 rounded-full border-2 border-white"
              ></div>
            </div>
          </div>
          <% else %> <%= if @label do %>
          <span class="text-gray-700 font-light"><%= @label %></span>
          <% else %>
          <span class="text-gray-300 font-light">Waiting for image input.</span>
          <% end %> <% end %>
        </div>
      </div>
    </div>
    <!-- Examples -->
    <%= if @display_list? do %>
    <div class="flex flex-col">
      <h3
        class="mt-10 text-xl lg:text-center font-light tracking-tight text-gray-900 lg:text-2xl"
      >
        Examples
      </h3>
      <div class="flex flex-row justify-center my-8">
        <div
          class="mx-auto grid max-w-2xl grid-cols-1 gap-x-6 gap-y-20 sm:grid-cols-2"
        >
          <%= for example_img <- @example_list do %>

          <!-- Loading skeleton if it is predicting -->
          <%= if example_img.predicting? == true do %>
          <div
            role="status"
            class="flex items-center justify-center w-full h-full max-w-sm bg-gray-300 rounded-lg animate-pulse"
          >
            <svg
              class="w-10 h-10 text-gray-200 dark:text-gray-600"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="currentColor"
              viewBox="0 0 20 18"
            >
              <path
                d="M18 0H2a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2Zm-5.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Zm4.376 10.481A1 1 0 0 1 16 15H4a1 1 0 0 1-.895-1.447l3.5-7A1 1 0 0 1 7.468 6a.965.965 0 0 1 .9.5l2.775 4.757 1.546-1.887a1 1 0 0 1 1.618.1l2.541 4a1 1 0 0 1 .028 1.011Z"
              />
            </svg>
            <span class="sr-only">Loading...</span>
          </div>

          <% else %>
          <div>
            <img
              id="{example_img.base64_encoded_url}"
              src="{example_img.base64_encoded_url}"
              class="rounded-2xl object-cover"
            />
            <h3 class="mt-1 text-lg leading-8 text-gray-900 text-center">
              <%= example_img.label %>
            </h3>
          </div>
          <% end %> <% end %>
        </div>
      </div>
    </div>
    <% end %>
  </div>
</div>
```

We've made two changes.

- we've added some text to better introduce our application
  at the top of the page.
- added a section to show the example images list.
  This section is only rendered if the
  **`display_list?`** socket assign is set to `true`.
  If so, we iterate over the
  **`example_list`** socket assign list
  and show a [loading skeleton](https://www.freecodecamp.org/news/how-to-build-skeleton-screens-using-css-for-better-user-experience/)
  if the image is `:predicting`.
  If not, it means the image has already been predicted,
  and we show the base64-encoded image
  like we do with the image uploaded by the person.

And that's it! 🎉

#### 8.4 Using URL of image instead of base64-encoded

While our example list is being correctly rendered,
we are using additional CPU
to base64 encode our images
so they can be shown to the person.

Initially, we did this because
`https://source.unsplash.com/random/`
resolves into a different URL every time it is called.
This means that the image that was fed into the model
would be different from the one shown in the example list
if we were to use this URL in our view.

To fix this,
**we need to follow the redirection when the URL is resolved**.

> [!NOTE]
> We can do this with
> [`Finch`](https://github.com/sneako/finch),
> if we wanted to.
>
> We could do something like
> def rand_splash do
>
> ```elixir
> %{scheme: scheme, host: host, path: path} =
>     Finch.build(:get, "https://source.unsplash.com/random/")
>     |> Finch.request!(MyFinch)
>     |> Map.get(:headers)
>     |> Enum.filter(fn {a, _b} -> a == "location" end)
>     |> List.first()
>     |> elem(1)
>     |> URI.parse()
>
>    scheme <> "://" <> host <> path
> end
> ```
>
> And then call it, like so.
>
> ```elixir
> App.rand_splash()
> # https://images.unsplash.com/photo-1694813646634-9558dc7960e3
> ```

Because we are already using
[`req`](https://github.com/wojtekmach/req),
let's make use of it
instead of adding additional dependencies.

Let's first add a function that will do this
in `lib/app_web/live/page_live.ex`.
Add the following piece of code
at the end of the file.

```elixir
  defp track_redirected(url) do
    # Create request
    req = Req.new(url: url)

    # Add tracking properties to req object
    req = req
    |> Req.Request.register_options([:track_redirected])
    |> Req.Request.prepend_response_steps(track_redirected: &track_redirected_uri/1)

    # Make request
    {:ok, response} = Req.request(req)

    # Return the final URI
    %{url: URI.to_string(response.private.final_uri), body: response.body}
  end

  defp track_redirected_uri({request, response}) do
    {request, %{response | private: Map.put(response.private, :final_uri, request.url)}}
  end
```

This function adds properties to the request object
and tracks the redirection.
It will add a [`URI`](https://hexdocs.pm/elixir/1.12/URI.html#summary)
object inside `private.final_uri`.
This function returns
the `body` of the image
and the final `url`
it is resolved to
(the URL of the image).

Now all we need to do is use this function!
Head over to the `handle_event("show_examples"...` function
and change the loop to the following.

```elixir
    tasks = for _ <- 1..2 do
      %{url: url, body: body} = track_redirected(random_image)
      predict_example_image(body, url)
    end
```

We are making use of `track_redirected/1`,
the function we've just created.
We pass both `body` and `url` to `predict_example_image/1`,
which we will now change.

```elixir
  def predict_example_image(body, url) do
    with {:vix, {:ok, img_thumb}} <-
           {:vix, Vix.Vips.Operation.thumbnail_buffer(body, @image_width)},
         {:pre_process, {:ok, t_img}} <- {:pre_process, pre_process_image(img_thumb)} do

      # Create an async task to classify the image from unsplash
      Task.Supervisor.async(App.TaskSupervisor, fn ->
        Nx.Serving.batched_run(ImageClassifier, t_img)
      end)
      |> Map.merge(%{url: url})

    else
      {:vix, {:error, msg}} -> {:error, msg}
      {:pre_process, {:error, msg}} -> {:error, msg}
    end
  end
```

Instead of using `base64_encoded_url`,
we are now using the `url` we've acquired.

The last step we need to do in our LiveView
is to finally use this `url`
in `handle_info/3`.

```elixir
  def handle_info({ref, result}, %{assigns: assigns} = socket) do
    Process.demonitor(ref, [:flush])

    label =
      case Application.get_env(:app, :use_test_models, false) do
        true ->
          App.Models.extract_test_label(result)

        false ->
          App.Models.extract_prod_label(result)
      end

    cond do

      Map.get(assigns, :task_ref) == ref ->
        {:noreply, assign(socket, label: label, upload_running?: false)}

      img = Map.get(assigns, :example_list_tasks) |> Enum.find(&(&1.ref == ref)) ->

        updated_example_list = Map.get(assigns, :example_list)
        |> Enum.map(fn obj ->
          if obj.ref == img.ref do
            obj
            |> Map.put(:url, img.url) # change here
            |> Map.put(:label, label)
            |> Map.put(:predicting?, false)

          else
            obj
          end end)

        {:noreply,
         assign(socket,
           example_list: updated_example_list,
           upload_running?: false,
           display_list?: true
         )}
    end
  end
```

And that's it!

The last thing we need to do is change our view
so it uses the `:url` parameter
instead of the obsolete `:base64_encoded_url`.

Head over to `lib/app_web/live/page_live.html.heex`
and change the `<img>` being shown in the example list
so it uses the `:url` parameter.

```html
<img
  id="{example_img.url}"
  src="{example_img.url}"
  class="rounded-2xl object-cover"
/>
```

And we're done! 🎉

We are now rendering the image on the client
through the URL the Unsplash API resolves into
instead of having the LiveView server
encoding the image.
Therefore, we're saving some CPU
to the thing that matters the most:
_running our model_.

#### 8.5 See it running

Now let's see our application in action!
We are expecting the examples to be shown after
**8 seconds** of inactivity.
If the person is inactive for this time duration,
we fetch a random image from Unsplash API
and feed it to our model!

You should see different images every time you use the app.
Isn't that cool? 😎

<p align="center">
  <img width=800 src="https://github.com/dwyl/image-classifier/assets/17494745/1f8d08d1-f6ca-46aa-8c89-4bab45ad1e54">
</p>

### 9. Store metadata and classification info

Our app is shaping up quite nicely!
As it stands, it's an application that does inference on images.
However, it doesn't save them.

Let's expand our application so it has a **database**
where image classification is saved/persisted!

We'll use **`Postgres`** for this.
Typically, when you create a new `Phoenix` project
with `mix phx.new`,
[a `Postgres` database will be automatically created](https://hexdocs.pm/phoenix/installation.html#postgresql).
Because we didn't do this,
we'll have to configure this ourselves.

Let's do it!

#### 9.1 Installing dependencies

We'll install all the needed dependencies first.
In `mix.exs`, add the following snippet
to the `deps` section.

```elixir
      # HTTP Request
      {:httpoison, "~> 2.2"},
      {:mime, "~> 2.0.5"},
      {:ex_image_info, "~> 0.2.4"},

      # DB
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
```

- [**`httpoison`**](https://github.com/edgurgel/httpoison),
  [**`mime`**](https://hex.pm/packages/mime) and
  [**`ex_image_info`**](https://hex.pm/packages/ex_image_info)
  are used to make HTTP requests,
  get the content type and information from an image file,
  respectively.
  These will be needed to upload a given image to
  [`imgup`](https://github.com/dwyl/imgup),
  by making multipart requests.

- [**`phoenix_ecto`**](https://github.com/phoenixframework/phoenix_ecto),
  [**`ecto_sql`**](https://github.com/elixir-ecto/ecto_sql) and
  [**`postgrex`**](https://github.com/elixir-ecto/postgrex)
  are needed to properly configure our driver in Elixir
  that will connect to a Postgres database,
  in which we will persist data.

Run `mix deps.get` to install these dependencies.

#### 9.2 Adding `Postgres` configuration files

Now let's create the needed files
to properly connect to a Postgres relational database.
Start by going to `lib/app`
and create `repo.ex`.

```elixir
defmodule App.Repo do
  use Ecto.Repo,
    otp_app: :app,
    adapter: Ecto.Adapters.Postgres
end
```

This module will be needed in our configuration files
so our app knows where the database is.

Next, in `lib/app/application.ex`,
add the following line to the `children` array
in the supervision tree.

```elixir
    children = [
      AppWeb.Telemetry,
      App.Repo, # add this line
      {Phoenix.PubSub, name: App.PubSub},
      ...
    ]
```

Awesome! 🎉

Now let's head over to the files inside the `config` folder.

In `config/config.exs`,
add these lines.

```elixir
config :app,
  ecto_repos: [App.Repo],
  generators: [timestamp_type: :utc_datetime]
```

We are referring the module we've previously created (`App.Repo`)
to `ecto_repos` so `ecto` knows where the configuration
for the database is located.

In `config/dev.exs`,
add:

```elixir
config :app, App.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "app_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

We are defining the parameters of the database
that is used during development.

In `config/runtime.exs`,
add:

```elixir
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :app, App.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

   # ...
```

We are configuring the runtime database configuration..

In `config/test.exs`,
add:

```elixir
config :app, App.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
```

Here we're defining the database used during testing.

Now let's create a **migration file** to create our database table.
In `priv/repo/migrations/`, create a file
called `20231204092441_create_images.exs`
(or any other timestamp string)
with the following piece of code.

```elixir
defmodule App.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :url, :string
      add :description, :string
      add :width, :integer
      add :height, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
```

And that's it!
Those are the needed files that our application needs
to properly connect and persist data into the Postgres database.

You can now run `mix ecto.create` and `mix ecto.migrate`
to create the database
and the `"images"` table.

#### 9.3 Creating `Image` schema

For now, let's create a simple table `"images"`
in our database
that has the following properties:

- **`description`**: the description of the image
  from the model.
- **`width`**: width of the image.
- **`height`**: height of the image.
- **`url`**: public URL where the image is publicly hosted.

With this in mind, let's create a new file!
In `lib/app/`, create a file called `image.ex`.

```elixir
defmodule App.Image do
  use Ecto.Schema
  alias App.{Image, Repo}

  @primary_key {:id, :id, autogenerate: true}
  schema "images" do
    field(:description, :string)
    field(:width, :integer)
    field(:url, :string)
    field(:height, :integer)

    timestamps(type: :utc_datetime)
  end

  def changeset(image, params \\ %{}) do
    image
    |> Ecto.Changeset.cast(params, [:url, :description, :width, :height])
    |> Ecto.Changeset.validate_required([:url, :description, :width, :height])
  end

  @doc """
  Uploads the given image to S3
  and adds the image information to the database.
  """
  def insert(image) do
    %Image{}
    |> changeset(image)
    |> Repo.insert!()
  end
end
```

We've just created the `App.Image` schema
with the aforementioned fields.

We've created `changeset/1`, which is used to cast
and validate the properties of a given object
before interacting with the database.

`insert/1` receives an object,
runs it through the changeset
and inserts it in the database.

#### 9.4 Changing our LiveView to persist data

Now that we have our database set up,
let's change some of our code so we persist data into it!
In this section, we'll be working in the `lib/app_web/live/page_live.ex` file.

First, let's import `App.Image`
and create an `ImageInfo` struct to hold the information
of the image throughout the process of uploading
and classifying the image.

```elixir
defmodule AppWeb.PageLive do
  use AppWeb, :live_view
  alias App.Image        # add this import
  alias Vix.Vips.Image, as: Vimage


  defmodule ImageInfo do
    @doc """
    General information for the image that is being analysed.
    This information is useful when persisting the image to the database.
    """
    defstruct [:mimetype, :width, :height, :url, :file_binary]
  end

  # ...
```

We are going to be using `ImageInfo`
in our socket assigns.
Let's add to it when the LiveView is mounting!

```elixir
     |> assign(
       label: nil,
       upload_running?: false,
       task_ref: nil,
       image_info: nil, # add this line
       image_preview_base64: nil,
       example_list_tasks: [],
       example_list: [],
       display_list?: false
     )
```

When the person uploads an image,
we want to retrieve its info (namely its _height_, _width_)
and upload the image to an `S3` bucket (we're doing this through `imgup`)
so we can populate the `:url` field of the schema in the database.

We can retrieve this information _while consuming the entry_
/uploading the image file.
For this, go to `handle_progress(:image_list, entry, socket)`
and change the function to the following.

```elixir
  def handle_progress(:image_list, entry, socket) when entry.done? do
      # We've changed the object that is returned from `consume_uploaded_entry/3` to return an `image_info` object.
      %{tensor: tensor, image_info: image_info} =
        consume_uploaded_entry(socket, entry, fn %{} = meta ->
          file_binary = File.read!(meta.path)

          # Add this line. It uses `ExImageInfo` to retrieve the info from the file binary.
          {mimetype, width, height, _variant} = ExImageInfo.info(file_binary)

          {:ok, thumbnail_vimage} =
            Vix.Vips.Operation.thumbnail(meta.path, @image_width, size: :VIPS_SIZE_DOWN)

          {:ok, tensor} = pre_process_image(thumbnail_vimage)

          # Add this line. Uploads the image to the S3, which returns the `url` and `compressed url`.
          # (we'll implement this function next)
          url = Image.upload_image_to_s3(meta.path, mimetype) |> Map.get("url")

          # Add this line. We are constructing the image_info object to be returned.
          image_info = %ImageInfo{mimetype: mimetype, width: width, height: height, file_binary: file_binary, url: url}

          # Return it
          {:ok, %{tensor: tensor, image_info: image_info}}
        end)

      task =
        Task.Supervisor.async(App.TaskSupervisor, fn ->
          Nx.Serving.batched_run(ImageClassifier, tensor)
        end)

      base64 = "data:image/png;base64, " <> Base.encode64(image_info.file_binary)

      # Change this line so `image_info` is defined when the image is uploaded
      {:noreply, assign(socket, upload_running?: true, task_ref: task.ref, image_preview_base64: base64, image_info: image_info)}
    #else
    #  {:noreply, socket}
    #end
  end
```

Check the comment lines for more explanation on the changes that have bee nmade.
We are using `ExImageInfo` to fetch the information from the image
and assigning it to the `image_info` socket we defined earlier.

We are also using `Image.upload_image_to_s3/2` to upload our image to `imgup`.
Let's define this function in `lib/app/image.ex`.

```elixir
  def upload_image_to_s3(file_path, mimetype) do
    extension = MIME.extensions(mimetype) |> Enum.at(0)

    # Upload to Imgup - https://github.com/dwyl/imgup
    upload_response =
      HTTPoison.post!(
        "https://imgup.fly.dev/api/images",
        {:multipart,
         [
           {
             :file,
             file_path,
             {"form-data", [name: "image", filename: "#{Path.basename(file_path)}.#{extension}"]},
             [{"Content-Type", mimetype}]
           }
         ]},
        []
      )

    # Return URL
    Jason.decode!(upload_response.body)
  end
```

We're using `HTTPoison` to make a multipart request to the `imgup` server,
effectively uploading the image to the server.
If the upload is successful, it returns the `url` of the uploaded image.

Let's go back to `lib/app_web/live/page_live.ex`.
Now that we have `image_info` in the socket assigns,
we can use it to **insert a row in the `"images"` table in the database**.
We only want to do this after the model is done running,
so simply change `handle_info/2` function
(which is called after the model is done with classifying the image).

```elixir
    cond do

      # If the upload task has finished executing, we update the socket assigns.
      Map.get(assigns, :task_ref) == ref ->

        # Insert image to database
        image = %{
          url: assigns.image_info.url,
          width: assigns.image_info.width,
          height: assigns.image_info.height,
          description: label
        }
        Image.insert(image)

        # Update socket assigns
        {:noreply, assign(socket, label: label, upload_running?: false)}


    # ...
```

In the `cond do` statement,
we want to change the one pertaining to the image that is uploaded,
_not the example list_ that is defined below.
We simply create an `image` variable with information
that is passed down to `Image.insert/1`,
effectively adding the row to the database.

And that's it!

Now every time a person uploads an image
and the model is executed,
we are saving its location (`:url`),
information (`:width` and `:height`)
and the result of the classifying model
(`:description`).

🥳

> [!NOTE]
>
> If you're curious and want to see the data in your database,
> we recommend using [`DBeaver`](https://dbeaver.io/),
> an open-source database manager.
>
> You can learn more about it at https://github.com/dwyl/learn-postgresql.

### 10. Adding double MIME type check and showing feedback to the person in case of failure

Currently, we are not handling any errors
in case the upload of the image to `imgup` fails.
Although this is not critical,
it'd be better if we could show feedback to the person
in case the upload to `imgup` fails.
This is good for us as well,
because we _can monitor and locate the error faster_
if we log the errors.

For this, let's head over to `lib/app/image.ex`
and update the `upload_image_to_s3/2` function we've implemented.

```elixir
  def upload_image_to_s3(file_path, mimetype) do
    extension = MIME.extensions(mimetype) |> Enum.at(0)

    # Upload to Imgup - https://github.com/dwyl/imgup
    upload_response =
      HTTPoison.post(
        "https://imgup.fly.dev/api/images",
        {:multipart,
         [
           {
             :file,
             file_path,
             {"form-data", [name: "image", filename: "#{Path.basename(file_path)}.#{extension}"]},
             [{"Content-Type", mimetype}]
           }
         ]},
        []
      )

    # Process the response and return error if there was a problem uploading the image
    case upload_response do
      # In case it's successful
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"url" => url, "compressed_url" => _} = Jason.decode!(body)
        {:ok, url}

      # In case it returns HTTP 400 with specific reason it failed
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        %{"errors" => %{"detail" => reason}} = Jason.decode!(body)
        {:error, reason}

      # In case the request fails for whatever other reason
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
```

As you can see,
we are returning `{:error, reason}` if an error occurs,
and providing feedback alongside it.
If it's successful, we return `{:ok, url}`.

Because we've just changed this function,
we need to also update `def handle_progress(:image_list...`
inside `lib/app_web/live/page_live.ex`
to properly handle this new function output.

We are also introducing a double MIME type check to ensure that only image files are uploaded and processed.
We use [GenMagic](https://hexdocs.pm/gen_magic/readme.html). It provides supervised and customisable access to `libmagic` using a supervised external process.
[This gist](https://gist.github.com/leommoore/f9e57ba2aa4bf197ebc5) explains that Magic numbers are the first bits of a file
which uniquely identifies the type of file.

We use the GenMagic server as a daemon; it is started in the Application module.
It is referenced by its name.
When we run `perform`, we obtain a map and compare the mime type with the one read by `ExImageInfo`.
If they correspond with each other, we continue, or else we stop the process.

On your computer, for this to work locally, you should install the package `libmagic-dev`.

> [!NOTE]
>
> Depending on your OS, you may install `libmagic` in different ways.
> A quick Google search will suffice,
> but here are a few resources nonetheless:
>
> - Mac: https://gist.github.com/eparreno/1845561
> - Windows: https://github.com/nscaife/file-windows
> - Linux: https://zoomadmin.com/HowToInstall/UbuntuPackage/libmagic-dev
>
> **Definitely read `gen_magic`'s installation section in https://github.com/evadne/gen_magic#installation**.
> You may need to perform additional steps.

You'll need to add [`gen_magic`](https://github.com/evadne/gen_magic)
to `mix.exs`.
This dependency will allow us to access `libmagic` through `Elixir`.

```elixir
def deps do
  [
    {:gen_magic, "~> 1.1.1"}
  ]
end
```

In the `Application` module, you should add the `GenMagic` daemon
(the C lib is loaded once for all and referenced by its name).

```elixir
#application.ex
children = [
  ...,
  {GenMagic.Server, name: :gen_magic},
]
```

In the Dockerfile (needed to deploy this app), we will install the `libmagic-dev` as well:

```Dockerfile
RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates libmagic-dev\
  && apt-get clean && rm -f /var/lib/apt/lists/*_*
```

Add the following function in the module App.Image:

```elixir
 @doc """
  Check file type via magic number. It uses a GenServer running the `C` lib "libmagic".
  """
  def gen_magic_eval(path, accepted_mime) do
    GenMagic.Server.perform(:gen_magic, path)
    |> case do
      {:error, reason} ->
        {:error, reason}

      {:ok,
       %GenMagic.Result{
         mime_type: mime,
         encoding: "binary",
         content: _content
       }} ->
        if Enum.member?(accepted_mime, mime),
          do: {:ok, %{mime_type: mime}},
          else: {:error, "Not accepted mime type."}

      {:ok, %GenMagic.Result{} = res} ->
        require Logger
        Logger.warning("⚠️ MIME type error: #{inspect(res)}")
        {:error, "Not acceptable."}
    end
  end
end
```

In the `page_live.ex` module, add the functions:

```elixir
@doc"""
Use the previous function and eturn the GenMagic reponse from the previous function
"""

def magic_check(path) do
  App.Image.gen_magic_eval(path, @accepted_mime)
  |> case do
    {:ok, %{mime_type: mime}} ->
      {:ok, %{mime_type: mime}}

    {:error, msg} ->
      {:error, msg}
  end
end

@doc """
Double-checks the MIME type of uploaded file to ensure that the file
is an image and is not corrupted.
"""
def check_mime(magic_mime, info_mime) do
  if magic_mime == info_mime, do: :ok, else: :error
end
```

We are now ready to double-check the file input
with `ExImageInfo` and `GenMagic` to ensure the safety of the uploads.

```elixir
def handle_progress(:image_list, entry, socket) when entry.done? do
  # We consume the entry only if the entry is done uploading from the image
  # and if consuming the entry was successful.

  with %{tensor: tensor, image_info: image_info} <-
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
             with {:magic, {:ok, %{mime_type: mime}}} <-
                    {:magic, magic_check(path)},
                  {:read, {:ok, file_binary}} <-
                    {:read, File.read(path)},
                  {:image_info, {mimetype, width, height, _variant}} <-
                    {:image_info, ExImageInfo.info(file_binary)},
                  {:check_mime, :ok} <-
                    {:check_mime, check_mime(mime, mimetype)},
                # Get image and resize
                {:ok, thumbnail_vimage} <-
                  Vix.Vips.Operation.thumbnail(path, @image_width, size: :VIPS_SIZE_DOWN),
                # Pre-process it
                {:ok, tensor} <-
                  pre_process_image(thumbnail_vimage) do
              # Upload image to S3
              Image.upload_image_to_s3(path, mimetype)
              |> case do
                {:ok, url} ->
                  image_info = %ImageInfo{
                    mimetype: mimetype,
                    width: width,
                    height: height,
                    file_binary: file_binary,
                    url: url
                  }

                  {:ok, %{tensor: tensor, image_info: image_info}}

                # If S3 upload fails, we return error
                {:error, reason} ->
                  {:ok, %{error: reason}}
              end
            else
              {:error, reason} -> {:postpone, %{error: reason}}
            end
          end) do

    # If consuming the entry was successful, we spawn a task to classify the image
    # and update the socket assigns
    task =
      Task.Supervisor.async(App.TaskSupervisor, fn ->
        Nx.Serving.batched_run(ImageClassifier, tensor)
      end)

    # Encode the image to base64
    base64 = "data:image/png;base64, " <> Base.encode64(image_info.file_binary)

    {:noreply,
      assign(socket,
        upload_running?: true,
        task_ref: task.ref,
        image_preview_base64: base64,
        image_info: image_info
      )}

    # Otherwise, if there was an error uploading the image, we log the error and show it to the person.
  else
    %{error: reason} ->
      Logger.warning("⚠️ Error uploading image. #{inspect(reason)}")
      {:noreply, push_event(socket, "toast", %{message: "Image couldn't be uploaded to S3.\n#{reason}"})}

    _ ->
      {:noreply, socket}
  end
end
```

Phew! That's a lot!
Let's go through the changes we've made.

- we are using the [`with` statement](https://www.openmymind.net/Elixirs-With-Statement/)
  to only feed the image to the model for classification
  in case the upload to `imgup` succeeds.
  We've changed what `consume_uploaded_entry/3` returns
  in case the upload fails - we return `{:ok, %{error: reason}}`.
- in case the upload fails,
  we pattern match the `{:ok, %{error: reason}}` object
  and push a `"toast"` event to the Javascript client
  (we'll implement these changes shortly).

Because we push an event in case the upload fails,
we are going to make some changes to the Javascript client.
We are going to **show a toast with the error when the upload fails**.

#### 10.1 Showing a toast component with error

To show a [toast component](https://getbootstrap.com/docs/4.3/components/toasts/),
we are going to use
[`toastify.js`](https://apvarun.github.io/toastify-js/).

Navigate to `assets` folder
and run:

```sh
  pnpm install toastify-js
```

With this installed, we need to import `toastify` styles
in `assets/css/app.css`.

```css
@import "../node_modules/toastify-js/src/toastify.css";
```

All that's left is **handle the `"toast"` event in `assets/js/app.js`**.
Add the following snippet of code to do so.

```js
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
```

With the `payload.message` we're receiving from the LiveView
(remember when we executed `push_event/3` in our LiveView?),
we are using it to create a `Toastify` object
that is shown in case the upload fails.

And that's it!
Quite easy, isn't it? 😉

If `imgup` is down or the image that was sent was for example, invalid, an error should be shown, like so.

<p align="center">
  <img width="800" src="https://github.com/dwyl/image-classifier/assets/17494745/d730d10c-b45e-4dce-a37a-bb389c3cd548" />
</p>

### 11. Benchmarking image captioning models

You may be wondering: which model is most suitable for me?
Depending on the use case,
`Bumblebee` supports different models
for different scenarios.

To help you make up your mind,
we've created a guide
that benchmarks some of `Bumblebee`-supported models
for image captioning.

Although few models are supported,
as they add more models,
this comparison table will grow.
So any contribution is more than welcome! 🎉

You may check the guide
and all of the code
inside the
[`_comparison`](./_comparison/) folder.

<div align="center">

## 🔍 Semantic search

> Imagine a person wants to see an image that was uploaded
> under a certain theme.
> One way to solve this problem is to perform a **_full-text_ search query** on specific words among these image captions.

<p align="center">
  <img src="https://github.com/dwyl/image-classifier/assets/17494745/b3568de8-2b0c-4413-8528-a3aee4135ea0">
</p>

</div>

> [!NOTE]
>
> This section was kindly implemented and documented by
> [@ndrean](https://github.com/ndrean). It is based on articles written by Sean Moriarty's published in the Dockyard's blog.
> Do check him out! 🎉

We can leverage machine learning to greatly improve this search process:
we'll look for images whose captions _are close in terms of meaning_
to the search.

In this section, you'll learn how to perform
[**semantic search**](https://www.elastic.co/what-is/semantic-search)
with machine learning.
These techniques are widely used in search engines,
including in widespread tools like
[Elastic Search](https://www.elastic.co/).

### 0. Overview of the process

Let's go over the process in detail so we know what to expect.

As it stands, when images are uploaded and captioned,
the URL is saved, as well as the caption,
in our local database.

Here's an overview of how semantic search usually works
(which is what we'll exactly implement).

<p align="center">
  <img width="800" src="https://github.com/dwyl/image-classifier/assets/17494745/90e3d370-b324-46fc-b1f6-83b6240f28a5" />
</p>

> Source: https://www.elastic.co/what-is/semantic-search

We will use the following toolchain:

<p align="center">
  <img width="800" src="https://github.com/ndrean/image-classifier/assets/6793008/f5aad51b-2d49-4184-b5a4-07236449c821" />
</p>

#### 0.1 Audio transcription

We simply let the user start and stop the recording
by using a submit button in a form.
This can of course be greatly refined by using Voice Detection. You may find an example [here](https://github.com/ricky0123/vad).

Firstly, we will:

- record an audio with [MediaRecorder](https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder) API.
- run a **Speech-To-Text** process to produce a text transcription
  from the audio.

We will use the _pre-trained_ model [openai/whisper-small](https://huggingface.co/openai/whisper-small)
from <https://huggingface.co>
and use it with the help of the [Bumblebee.Audio.speech_to_text_whisper](https://hexdocs.pm/bumblebee/Bumblebee.Audio.html#speech_to_text_whisper/5) function.
We get an `Nx.Serving` that we will use to run this model with an input.

#### 0.2 Creating embeddings

We then want to find images whose captions
approximate this text in terms of meaning.
This transcription is the `"target text"`.
This is where **embeddings** come into play:
they are **vector representations** of certain inputs,
which in our case, are the text transcription of the audio file recorded by the user.
We encode each transcription as an embedding
and then use an approximation algorithm to find the closest neighbours.

Our next steps will be to prepare the
[symmetric semantic search](https://www.sbert.net/examples/applications/semantic-search/README.html#symmetric-vs-asymmetric-semantic-search).
We will use a
[transformer](<https://en.wikipedia.org/wiki/Transformer_(machine_learning_model)>) model,
more specifically the pre-trained [sBert](https://www.sbert.net/docs/pretrained_models.html#sentence-embedding-models)
system available in
[Huggingface](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2).

We transform a text into a vector with the sentence-transformer model [`sentence-transformers/paraphrase-MiniLM-L6-v2` ](https://huggingface.co/sentence-transformers/paraphrase-MiniLM-L6-v2).

> [!NOTE]
> You may find models in the [MTEB English leaderboard](https://huggingface.co/spaces/mteb/leaderboard). We looked for "small" models in terms of file size and dimensions. You may want to try and use [GTE small](https://huggingface.co/thenlper/gte-small).

We will run the model with the help of the
[Bumblebee.Text.TextEmbedding.text_embedding](https://hexdocs.pm/bumblebee/Bumblebee.Text.html#text_embedding/3) function.

This encoding is done for each image caption.

#### 0.3 Semantical search

At this point, we have:

- the embedding of the text transcription of the recording made by the user
  (e.g `"a dog"`).
- all the embeddings of all the images in our "image bank".

To search for the images that are related to `"a dog"`,
we need to apply an algorithm that compares these embeddings!

For this, we will run a [**knn_neighbour**](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm) search.
There are several ways to do this.

- we can use`pgvector` , a vector extension of Postgres. It is used to store vectors (the embeddings) and to run similarity searches.
  With `pgvector`, we can run:

  - a full exact search with the [cosine similarity](https://github.com/pgvector/pgvector#distances) operator `<=>`,
  - or use an Approximate Nearest Neighbour seach with indexing algorithms. The extension proposes the [`IVFFLAT`](https://github.com/pgvector/pgvector#ivfflat) and the [`HNSWLIB`](https://github.com/pgvector/pgvector#hnsw) algorithms. You can find some explanations on both algorithms in https://tembo.io/blog/vector-indexes-in-pgvector and https://neon.tech/blog/understanding-vector-search-and-hnsw-index-with-pgvector.

> [!NOTE]
> Note that [Supabase](https://supabase.com/docs/guides/database/extensions/pgvector) can use the `pgvector` extension, and you can use [Supabase with Fly.io](https://fly.io/docs/reference/supabase/).

> [!WARNING]
> Note that you need to save the embeddings (as vectors) into the database, so the database will be intensively used. This may lead to scaling problems and potential race conditions.

- we can alternatively use the `hnswlib` library and its Elixir binding [HNSWLib](https://github.com/elixir-nx/hnswlib).
  This "externalises" the ANN search from the database as it uses an in-memory file.
  This file needs to be persisted on disk, thus at the expense of using the filesystem with again potential race conditions.
  It works with an **[index struct](https://www.datastax.com/guides/what-is-a-vector-index)**: this struct will allow us to efficiently retrieve vector data.

**We will use this last option**,
mostly because we use Fly.io
and `pgvector` is hard to come by on this platform.
We will use a GenServer to wrap all the calls to `hnswlib` so every writes will be run synchronously.
Additionally, you don't rely on a framework that does the heavy lifting for you.
We're here to learn, aren't we? 😃

We will append incrementally the computed embedding from the captions into the Index.
We will get an indice which simply is the order of this embedding in the Index.
We then run a "knn_search" algorithm; the input will be the embedding of the audio transcript.
This algorithm will return the most relevant position(s) - `indices` -
among the `Index` indices that minimize the chosen distance between this input and the existing vectors.

This is where we'll need to save:

- whether the index,
- or the embedding

to look up for the corresponding image(s), depending upon if you append items one by one or by batch.

In our case, you will append items one by one so we will use the index to uniquely recover the nearest image whose caption is close semantically to our audio.

Do note that the measured distance is dependent on the [similarity metric](https://www.pinecone.io/learn/vector-similarity/)
used by the embedding model.
Because the "sentence-transformer" model we've chosen was trained with **_cosine_similarity_**,
this is what we'll use.
Bumblebee may have options to correctly use this metric, but we used a normalisation process which fits our needs.

### 1. Pre-requisites

We have already installed all the dependencies that we need.

> [!WARNING] > **You will also need to install [`ffmpeg`](https://ffmpeg.org/)**.
> Indeed, `Bumblebee` uses `ffmpeg` under the hood to process audio files into tensors,
> but it uses it _as an external dependency_.

And now we're ready to rock and roll! 🎸

### 2. Transcribe an audio recording

> **Source:** <https://dockyard.com/blog/2023/03/07/audio-speech-recognition-in-elixir-with-whisper-bumblebee?utm_source=elixir-merge>

We first need to capture the audio and upload it to the server.

The process is quite similar to the image upload, except that we
use a special Javascript hook to record the audio
and upload it to the Phoenix LiveView.

We use a `live_file_input` in a form to capture the audio and use the Javascript `MediaRecorder API`.
The Javascript code is triggered by an attached hook `Audio` declared in the HTML.
We also let the user listen to his audio by adding an [embedded audio element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/audio) `<audio>` in the HTML.
Its source is the audio blob as a URL object.

#### 1.1 Adding a loading spinner

We also add a spinner to display that the transcription process is running,
in the same way as we did for the captioning process.
To avoid code duplication, we introduce a Phoenix component "Spinner".
Create the file
`spinner.ex` in `lib/app_web/components/`
and create the `Spinner` component,
like so:

```elixir
# /lib/app_web/components/spinner.ex
defmodule AppWeb.Spinner do
  use Phoenix.Component

  attr :spin, :boolean, default: false

  def spin(assigns) do
    ~H"""
    <div :if={@spin} role="status">
      <div class="relative w-6 h-6 animate-spin rounded-full bg-gradient-to-r from-purple-400 via-blue-500 to-red-400 ">
        <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-gray-200 rounded-full border-2 border-white">
        </div>
      </div>
    </div>
    """
  end
end
```

In `page_live_html.heex`, add the following snippet of code.

```html
# page_live.html.heex
<form phx-change="noop">
  <.live_file_input upload={@uploads.speech} class="hidden" />
  <button
    id="record"
    class="bg-blue-500 hover:bg-blue-700 text-white font-bold px-4 rounded"
    type="button"
    phx-hook="Audio"
    disabled="{@mic_off?}"
  >
    <Heroicons.microphone
      outline
      class="w-6 h-6 text-white font-bold group-active:animate-pulse"
    />
    <span id="text">Record</span>
  </button>
</form>
<p class="flex flex-col items-center">
  <audio id="audio" controls></audio>
  <AppWeb.Spinner.spin spin="{@audio_running?}" />
</p>
```

You can also use this component to display the spinner when the captioning task is running,
so this part of your code will shrink to:

```elixir
<!-- Spinner -->
<AppWeb.Spinner.spin spin={@upload_running?} />

<%= if @label do %>
  <span class="text-gray-700 font-light"><%= @label %></span>
<% else %>
  <span class="text-gray-300 font-light">Waiting for image input.</span>
<% end %>
```

#### 2.2 Defining `Javascript` hook

We provide a basic user experience.
We let the user click on a button to start and stop the recording.
We do not try to resample the audio to say 16kHz nor provide automatic start/stop recording.
We next define the hook in a new JS file, located in the `assets/js` folder.
The important part is the `Phoenix.js` function `upload`,
to which we pass an identifier `"speech"`
and a list that contains the audio as a `Blob`.
We use an action button in the HTML,
and attach Javascript listeners to it on the `"click"`, `"dataavailable"` and `"stop"` events.
We also play with the CSS classes to modify the appearance of the action button when recording or not.

Create a file called `assets/js/micro.js`
and use the code below.

```js
// /assets/js/micro.js
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
```

Now let's import this file and declare our `hook` object in our `livesocket` object.
In our `assets/js/app.js` file, let's do:

```js
// /assets/js/app.js
...
import Audio from "./micro.js";
...
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { Audio },
});
```

#### 2.3 Handling audio upload in `LiveView`

We now need to add some server-side code.

The uploaded audio file will be saved on disk
as a temporary file in the `/priv/static/uploads` folder.
We will also make this file _unique_ every time a user records an audio.
We use an `Ecto.UUID` string to the file name and pass it into the Liveview socket.

The Liveview `mount/3` function returns a socket.
Let's update it
and pass extra arguments -
typically booleans for the UI such as the button disabling and the spinner -
as well as another `allow_upload/3` to handle the upload process of the audio file.

In `lib/app_web/live/page_live.ex`,
we change the code like so:

```elixir
#page_live.ex
@upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])
@tmp_wav Path.expand("priv/static/uploads/tmp.wav")

def mount(_,_,socket) do
  socket
  |> assign(
    ...,
    transcription: nil,
    mic_off?: false,
    audio_running?: false,
    tmp_wav: @tmp_wav
  )
  |> allow_upload(:speech,
    accept: :any,
    auto_upload: true,
    progress: &handle_progress/3,
    max_entries: 1
  )
  |> allow_upload(:image_list, ...)
end
```

We then create a specific `handle_progress` for the `:speech` event
as we did with the `:image_list` event.
It will launch a task to run the **Automatic Speech Recognition model**
on this audio file.
We named the serving `"Whisper"`.

```elixir
def handle_progress(:speech, entry, %{assigns: assigns} = socket) when entry.done? do
  tmp_wav =
      socket
      |> consume_uploaded_entry(entry, fn %{path: path} ->
        tmp_wav = assigns.tmp_wav <> Ecto.UUID.generate() <> ".wav"
        :ok = File.cp!(path, tmp_wav)
        {:ok, tmp_wav}
      end)

  audio_task =
    Task.Supervisor.async(
      App.TaskSupervisor,
      fn ->
        Nx.Serving.batched_run(Whisper, {:file, @tmp_wav})
      end
    )

  {:noreply, socket
  |> assign(
    audio_ref: audio_task.ref,
    mic_off?: true,
    audio_running?: true,
    tmp_wav: tmp_wav,
  )}
end
```

And that's it for the Liveview portion!

#### 2.4 Serving the `Whisper` model

Now that we are adding several models,
let's refactor our `models.ex` module
that manages the models.
Since we're dealing with multiple models,
we want our app to shutdown if there's any problem loading them.

We now add the model `Whisper` in the
`lib/app/application.ex`
so it's available throughout the application on runtime.

```elixir
# lib/app/application.ex

def check_models_on_startup do
  App.Models.verify_and_download_models()
  |> case do
    {:error, msg} ->
      Logger.error("⚠️ #{msg}")
      System.stop(0)

    :ok ->
        :ok
  end
end

def start(_type, _args) do
    end

    # model check-up
    :ok = check_models_on_startup()

    children = [
      ...,
    # Nx serving for Speech-to-Text
    {Nx.Serving,
      serving:
        if Application.get_env(:app, :use_test_models) == true do
          App.Models.audio_serving_test()
        else
          App.Models.audio_serving()
        end,
      name: Whisper},
    ,...
  ]
  ...
```

As you can see, we're using a serving similar
to the captioning model we've implemented earlier.
For this to work, we need to make some changes to the
`models.ex` module.
Recall that this module simply manages the models that are
downloaded locally and used in our application.

To implement the functions above,
we change the `lib/app/models.ex` module so it looks like so.

```elixir
defmodule ModelInfo do
  @moduledoc """
  Information regarding the model being loaded.
  It holds the name of the model repository and the directory it will be saved into.
  It also has booleans to load each model parameter at will - this is because some models (like BLIP) require featurizer, tokenizations and generation configuration.
  """

  defstruct [:name, :cache_path, :load_featurizer, :load_tokenizer, :load_generation_config]
end

defmodule App.Models do
  @moduledoc """
  Manages loading the modules and their location according to env.
  """
  require Logger

  # IMPORTANT: This should be the same directory as defined in the `Dockerfile`
  # where the models will be downloaded into.
  @models_folder_path Application.compile_env!(:app, :models_cache_dir)

  # Embedding-------
  @embedding_model %ModelInfo{
    name: "sentence-transformers/paraphrase-MiniLM-L6-v2",
    cache_path: Path.join(@models_folder_path, "paraphrase-MiniLM-L6-v2"),
    load_featurizer: false,
    load_tokenizer: true,
    load_generation_config: true
  }
  # Captioning --
  @captioning_test_model %ModelInfo{
    name: "microsoft/resnet-50",
    cache_path: Path.join(@models_folder_path, "resnet-50"),
    load_featurizer: true
  }

  @captioning_prod_model %ModelInfo{
    name: "Salesforce/blip-image-captioning-base",
    cache_path: Path.join(@models_folder_path, "blip-image-captioning-base"),
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }

  # Audio transcription --
  @audio_test_model %ModelInfo{
    name: "openai/whisper-small",
    cache_path: Path.join(@models_folder_path, "whisper-small"),
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }

  @audio_prod_model %ModelInfo{
    name: "openai/whisper-small",
    cache_path: Path.join(@models_folder_path, "whisper-small"),
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }

  def extract_captioning_test_label(result) do
    %{predictions: [%{label: label}]} = result
    label
  end

  def extract_captioning_prod_label(result) do
    %{results: [%{text: label}]} = result
    label
  end

  @doc """
  Verifies and downloads the models according to configuration
  and if they are already cached locally or not.

  The models that are downloaded are hardcoded in this function.
  """
  def verify_and_download_models() do
    {
      Application.get_env(:app, :force_models_download, false),
      Application.get_env(:app, :use_test_models, false)
    }
    |> case do
      {true, true} ->
        # Delete any cached pre-existing models
        File.rm_rf!(@models_folder_path)

        with :ok <- download_model(@captioning_test_model),
             :ok <- download_model(@embedding_model),
             :ok <- download_model(@audio_test_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end

      {true, false} ->
        # Delete any cached pre-existing models
        File.rm_rf!(@models_folder_path)

        with :ok <- download_model(@captioning_prod_model),
             :ok <- download_model(@audio_prod_model),
             :ok <- download_model(@embedding_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end

      {false, false} ->
        # Check if the prod model cache directory exists or if it's not empty.
        # If so, we download the prod models.

        with :ok <- check_folder_and_download(@captioning_prod_model),
             :ok <- check_folder_and_download(@audio_prod_model),
             :ok <- check_folder_and_download(@embedding_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end

      {false, true} ->
        # Check if the test model cache directory exists or if it's not empty.
        # If so, we download the test models.

        with :ok <- check_folder_and_download(@captioning_test_model),
             :ok <- check_folder_and_download(@audio_test_model),
             :ok <- check_folder_and_download(@embedding_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end
    end
  end

  @doc """
  Serving function that serves the `Bumblebee` captioning model used throughout the app.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def caption_serving do
    load_offline_model(@captioning_prod_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
            Bumblebee.Vision.image_to_text(
              model.model_info,
              model.featurizer,
              model.tokenizer,
              model.generation_config,
              compile: [batch_size: 1],
              defn_options: [compiler: EXLA],
              # needed to run on `Fly.io`
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  @doc """
  Serving function that serves the `Bumblebee` audio transcription model used throughout the app.
  """
  def audio_serving do
    load_offline_model(@audio_prod_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
            Bumblebee.Audio.speech_to_text_whisper(
              model.model_info,
              model.featurizer,
              model.tokenizer,
              model.generation_config,
              chunk_num_seconds: 30,
              task: :transcribe,
              defn_options: [compiler: EXLA],
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  @doc """
  Serving function for tests only. It uses a test audio transcription model.
  """
  def audio_serving_test do
    load_offline_model(@audio_test_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
            Bumblebee.Audio.speech_to_text_whisper(
              model.model_info,
              model.featurizer,
              model.tokenizer,
              model.generation_config,
              chunk_num_seconds: 30,
              task: :transcribe,
              defn_options: [compiler: EXLA],
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  @doc """
  Serving function for tests only. It uses a test captioning model.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def caption_serving_test do
    load_offline_model(@captioning_test_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
            Bumblebee.Vision.image_classification(
              model.model_info,
              model.featurizer,
              top_k: 1,
              compile: [batch_size: 10],
              defn_options: [compiler: EXLA],
              # needed to run on `Fly.io`
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  # Loads the models from the cache folder.
  # It will load the model and the respective the featurizer, tokenizer and generation config if needed,
  # and return a map with all of these at the end.
  @spec load_offline_model(map()) ::
          {:ok, map()} | {:error, String.t()}

  defp load_offline_model(model) do
    Logger.info("ℹ️ Loading #{model.name}...")

    # Loading model
    loading_settings = {:hf, model.name, cache_dir: model.cache_path, offline: true}

    Bumblebee.load_model(loading_settings)
    |> case do
      {:ok, model_info} ->
        info = %{model_info: model_info}

        # Load featurizer, tokenizer and generation config if needed
        info =
          if Map.get(model, :load_featurizer) do
            {:ok, featurizer} = Bumblebee.load_featurizer(loading_settings)
            Map.put(info, :featurizer, featurizer)
          else
            info
          end

        info =
          if Map.get(model, :load_tokenizer) do
            {:ok, tokenizer} = Bumblebee.load_tokenizer(loading_settings)
            Map.put(info, :tokenizer, tokenizer)
          else
            info
          end

        info =
          if Map.get(model, :load_generation_config) do
            {:ok, generation_config} =
              Bumblebee.load_generation_config(loading_settings)

            Map.put(info, :generation_config, generation_config)
          else
            info
          end

        # Return a map with the model and respective parameters.
        {:ok, info}

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Downloads the pre-trained models according to a given %ModelInfo struct.
  # It will load the model and the respective the featurizer, tokenizer and generation config if needed.
  @spec download_model(map()) :: {:ok, map()} | {:error, binary()}
  defp download_model(model) do
    Logger.info("ℹ️ Downloading #{model.name}...")

    # Download model
    downloading_settings = {:hf, model.name, cache_dir: model.cache_path}

    # Download featurizer, tokenizer and generation config if needed
    Bumblebee.load_model(downloading_settings)
    |> case do
      {:ok, _} ->
        if Map.get(model, :load_featurizer) do
          {:ok, _} = Bumblebee.load_featurizer(downloading_settings)
        end

        if Map.get(model, :load_tokenizer) do
          {:ok, _} = Bumblebee.load_tokenizer(downloading_settings)
        end

        if Map.get(model, :load_generation_config) do
          {:ok, _} = Bumblebee.load_generation_config(downloading_settings)
        end

        :ok

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Checks if the folder exists and downloads the model if it doesn't.
  def check_folder_and_download(model) do
    :ok = File.mkdir_p!(@models_folder_path)

    model_location =
      Path.join(model.cache_path, "huggingface")

    if File.ls(model_location) == {:error, :enoent} or File.ls(model_location) == {:ok, []} do
      download_model(model)
      |> case do
        :ok -> :ok
        {:error, msg} -> {:error, msg}
      end
    else
      Logger.info("ℹ️ No download needed: #{model.name}")
      :ok
    end
  end
end
```

That's a lot! But we just need to focus on some new parts we've added:

- we've created **`audio_serving_test/1`** and
  **`audio_serving/1`**, our audio serving functions
  that are used in the `application.ex` file.
- added `@audio_prod_model` and `@audio_test_model`,
  the `Whisper` model definitions to be used to download the models locally.
- refactored the image captioning model definitions to be more clear.

Now we're successfully serving audio-to-text capabilities
in our application!

#### 2.5 Handling the model's response and updating elements in the view

We expect the response of this task to be
in the following form:

```elixir
%{
  chunks:
    [%{
      text: "Hi there",
              #^^^the text of our audio
      start_timestamp_seconds: nil,
      end_timestamp_seconds: nil
    }]
}
```

We capture this response in a `handle_info` callback
where we simply prune the temporary audio file
and update the socket state with the result,
and update the booleans used for our UI
(the spinner element, the button availability and reset of the task once done).

```elixir
def handle_info({ref, %{chunks: [%{text: text}]} = _result}, %{assigns: assigns} = socket)
      when assigns.audio_ref == ref do
  Process.demonitor(ref, [:flush])
  File.rm!(assigns.tmp_wav)

  {:noreply,
    assign(socket,
      transcription: String.trim(text),
      mic_off?: false,
      audio_running?: false,
      audio_ref: nil,
      tmp_wav: @tmp_wav
    )}
end
```

And that's it for this section!
Our application is now able to **record audio**
and **transcribe it**. 🎉

### 3. Embeddings and semantic search

We want to encode every caption and the input text
into an embedding which is a vector of a specific vector space.
In other words, we encode a string into a list of numbers.

We chose the transformer `"sentence-transformers/paraphrase-MiniLM-L6-v2"` model.

This transformer uses a **`384`** dimensional vector space.
Since this transformer is trained with a `cosine metric`,
we embed the vector space of embeddings with the same distance.
You can read more about [cosine_similarity here](https://en.wikipedia.org/wiki/Cosine_similarity).

This model is loaded and served by an `Nx.Serving` started in the Application module like all other models.

#### 3.1 The `HNSWLib` Index (GenServer)

This library [`HNSWLib`](https://github.com/elixir-nx/hnswlib)
works with an **[index](https://www.datastax.com/guides/what-is-a-vector-index)**.
We instantiate the Index file in a `GenServer` which holds the index in the state.

We will use an Index file that is saved locally in our file system.
This file will be updated any time we append an embedding;
all the client calls and writes to the HNSWLib index are handled by the GenServer.
They will happen synchronously. We want to minimize the race conditions in case several users interact with the app.
This app is only meant to run **on a single node**.

It is started in the Application module (`application.ex`).
When the app starts, we either read or create this file. The file is saved in the "/priv/static/uploads" folder.

Because we are deploying with Fly.io, we need to persist the Index file in the database because the machine - thus its attached volume - is pruned when inactive.

It is crucial to save the correspondence between the `Image` table and the Index file to retrieve the correct images.
In simple terms, **the file in the `Index` table in the DB must correspond to the Index file in the system.**

We therefore disable a user from loading several times the same file as otherwise,
we would have several indexes for the same picture.
This is done through **SHA computation**.

Since computations using models is a long-run process,
and because several users may interact with the app,
we need several steps to ensure that the information is synchronized between the database and the index file.

We also endow the vector space with a `:cosine` pseudo-metric.

Add the following `GenServer` file:
it will load the Index file,
and also provide a client API to interact with the Index,
which is held in the state of the GenServer.

Again, this solution works for a single node _only_.

```elixir
defmodule App.KnnIndex do
  use GenServer

  @moduledoc """
  A GenServer to load and handle the Index file for HNSWLib.
  It loads the index from the FileSystem if existing or from the table HnswlibIndex.
  It creates an new one if no Index file is found in the FileSystem
  and if the table HnswlibIndex is empty.
  It holds the index and the App.Image singleton table in the state.
  """

  require Logger

  @dim 384
  @max_elements 200
  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])
  @saved_index if Application.compile_env(:app, :knnindex_indices_test, false),
                 do: Path.join(@upload_dir, "indexes_test.bin"),
                 else: Path.join(@upload_dir, "indexes.bin")

  # Client API ------------------
  def start_link(args) do
    :ok = File.mkdir_p!(@upload_dir)
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def index_path do
    @saved_index
  end

  def save_index_to_db do
    GenServer.call(__MODULE__, :save_index_to_db)
  end

  def get_count do
    GenServer.call(__MODULE__, :get_count)
  end

  def add_item(embedding) do
    GenServer.call(__MODULE__, {:add_item, embedding})
  end

  def knn_search(input) do
    GenServer.call(__MODULE__, {:knn_search, input})
  end

  def not_empty_index do
    GenServer.call(__MODULE__, :not_empty)
  end

  # ---------------------------------------------------
  @impl true
  def init(args) do
    # Trying to load the index file
    index_path = Keyword.fetch!(args, :index)
    space = Keyword.fetch!(args, :space)

    case File.exists?(index_path) do
      # If the index file doesn't exist, we try to load from the database.
      false ->
        {:ok, index, index_schema} =
          App.HnswlibIndex.maybe_load_index_from_db(space, @dim, @max_elements)

        {:ok, {index, index_schema, space}}

      # If the index file does exist, we compare the one with teh table and check for incoherences.
      true ->
        Logger.info("ℹ️ Index file found on disk. Let's compare it with the database...")

        App.Repo.get_by(App.HnswlibIndex, id: 1)
        |> case do
          nil ->
            {:stop,
             {:error,
              "Error comparing the index file with the one on the database. Incoherence on table."}}

          schema ->
            check_integrity(index_path, schema, space)
        end
    end
  end

  defp check_integrity(path, schema, space) do
    # We check the count of the images in the database and the one in the index.
    with db_count <-
           App.Repo.all(App.Image) |> length(),
         {:ok, index} <-
           HNSWLib.Index.load_index(space, @dim, path),
         {:ok, index_count} <-
           HNSWLib.Index.get_current_count(index),
         true <-
           index_count == db_count do
      Logger.info("ℹ️ Integrity: ✅")
      {:ok, {index, schema, space}}

      # If it fails, we return an error.
    else
      false ->
        {:stop,
         {:error, "Integrity error. The count of images from index differs from the database."}}

      {:error, msg} ->
        Logger.error("⚠️ #{msg}")
        {:stop, {:error, msg}}
    end
  end

  @impl true
  def handle_call(:save_index_to_db, _, {index, index_schema, space} = state) do
    # We read the index file and try to update the index on the table as well.
    File.read(@saved_index)
    |> case do
      {:ok, file} ->
        {:ok, updated_schema} =
          index_schema
          |> App.HnswlibIndex.changeset(%{file: file})
          |> App.Repo.update()

        {:reply, {:ok, updated_schema}, {index, updated_schema, space}}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:get_count, _, {index, _, _} = state) do
    {:ok, count} = HNSWLib.Index.get_current_count(index)
    {:reply, count, state}
  end

  def handle_call({:add_item, embedding}, _, {index, _, _} = state) do
    # We add the new item to the index and update it.
    with :ok <-
           HNSWLib.Index.add_items(index, embedding),
         {:ok, idx} <-
           HNSWLib.Index.get_current_count(index),
         :ok <-
           HNSWLib.Index.save_index(index, @saved_index) do

      {:reply, {:ok, idx}, state}
    else
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:knn_search, nil}, _, state) do
    {:reply, {:error, "No index found"}, state}
  end

  def handle_call({:knn_search, input}, _, {index, _, _} = state) do
    # We search for the nearest neighbors of the input embedding.
    case HNSWLib.Index.knn_query(index, input, k: 1) do
      {:ok, labels, _distances} ->

        response =
          labels[0]
          |> Nx.to_flat_list()
          |> hd()
          |> then(fn idx ->
            App.Repo.get_by(App.Image, %{idx: idx + 1})
          end)

        # TODO: add threshold on  "distances"
        {:reply, response, state}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:not_empty, _, {index, _, _} = state) do
    case HNSWLib.Index.get_current_count(index) do
      {:ok, 0} ->
        Logger.warning("⚠️ Empty index.")
        {:reply, :error, state}

      {:ok, _} ->
        {:reply, :ok, state}
    end
  end
end

```

Let's unpack a bit of what we are doing here.

- we first are **defining the module constants**.
  Here, we add the dimensions of the embedding vector space
  (these are dependent on the model you choose).
  Check with the model you've used to tweak this settings optimally.

- define the upload directory where **the index file will be saved inside the filesystem**.
- when the GenServer is initialized (`init/1` function),
  we perform several _integrity verifications_,
  checking if both the `Index` file in the filesystem
  and the file in the `Index` table
  (from now on, this table will be called `HnswlibIndex`,
  under the name of the same schema).
  These validations essentially make sure the content
  of both files are the same.

- the other functions provide a basic API for
  callers to add items to the index file,
  so it is saved.

#### 3.2 Saving the `HNSWLib` Index in the database

As you may have seen from the previous GenServer,
we are calling functions from a module called
`App.HnswlibIndex` that we have not yet created.

This module pertains to the **schema** that will hold
information of the `HNSWLib` table.
This table will only have a single row,
with the file contents.
As we've discussed earlier,
we will compare the Index file in this row
with the one in the filesystem
to check for any inconsistencies that may arise.

Let's implement this module now!

Inside `lib/app`, create a file called `hnswlib_index.ex`
and use the following code.

```elixir
defmodule App.HnswlibIndex do
  use Ecto.Schema
  alias App.HnswlibIndex

  require Logger

  @moduledoc """
  Ecto schema to save the HNSWLib Index file into a singleton table
  with utility functions
  """

  schema "hnswlib_index" do
    field(:file, :binary)
    field(:lock_version, :integer, default: 1)
  end

  def changeset(struct \\ %__MODULE__{}, params \\ %{}) do
    struct
    |> Ecto.Changeset.cast(params, [:id, :file])
    |> Ecto.Changeset.optimistic_lock(:lock_version)
    |> Ecto.Changeset.validate_required([:id])
  end

  @doc """
  Tries to load index from DB.
  If the table is empty, it creates a new one.
  If the table is not empty but there's no file, an index is created from scratch.
  If there's one, we use it and load it to be used throughout the application.
  """
  def maybe_load_index_from_db(space, dim, max_elements) do
    # Check if the table has an entry
    App.Repo.get_by(HnswlibIndex, id: 1)
    |> case do
      # If the table is empty
      nil ->
        Logger.info("ℹ️ No index file found in DB. Creating new one...")
        create(space, dim, max_elements)

      # If the table is not empty but has no file
      response when response.file == nil ->
        Logger.info("ℹ️ Empty index file in DB. Recreating one...")

        # Purge the table and create a new file row in it
        App.Repo.delete_all(App.HnswlibIndex)
        create(space, dim, max_elements)

      # If the table is not empty and has a file
      index_db ->
        Logger.info("ℹ️ Index file found in DB. Loading it...")

        # We get the path of the index
        with path <- App.KnnIndex.index_path(),
             # Save the file on disk
             :ok <- File.write(path, index_db.file),
             # And load it
             {:ok, index} <- HNSWLib.Index.load_index(space, dim, path) do
          {:ok, index, index_db}
        end
    end
  end

  defp create(space, dim, max_elements) do
    # Inserting the row in the table
    {:ok, schema} =
      HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
      |> App.Repo.insert()

    # Creates index
    {:ok, index} =
      HNSWLib.Index.new(space, dim, max_elements)

    # Builds index for testing only
    if Mix.env() == :test do
      empty_index =
        Application.app_dir(:app, ["priv", "static", "uploads"])
        |> Path.join("indexes_empty.bin")

      HNSWLib.Index.save_index(index, empty_index)
    end

    {:ok, index, schema}
  end
end
```

In this module:

- we are creating **two fields**: `lock_version`,
  to simply check the version of the file;
  and `file`,
  the binary content of the index file.

- `lock_version` will be extremely useful to
  perform [**optmistic locking**](https://stackoverflow.com/questions/129329/optimistic-vs-pessimistic-locking),
  which is what we do in the `changeset/2` function.
  This will allow us to prevent deadlocking
  when two different people upload the same image at the same time,
  and overcome any race condition that may occur.
  This will maintain the data consistency in the Index file.

- `maybe_load_index_from_db/3` fetches the singleton row
  on this table and checks if the file exists in the row.
  If it doesn't, it creates a new one.
  Otherwise, it just loads the existing one inside the row.

- `create/3` creates a new index file.
  It's a private function that encapsulates creating
  the Index file so it can be used in the singleton row
  inside the table.

And that's it!
We've added additional code to conditionally create different indexes
according to the environment
(useful for testing),
but you can safely ignore those conditional calls
if you're not interested in testing
(though you should 😛).

#### 3.2 The embeding model

We provide a serving for the embedding model in the `App.Models` module.
It should look like this:

```elixir
#App.Models
@embedding_model %ModelInfo{
    name: "sentence-transformers/paraphrase-MiniLM-L6-v2",
    cache_path: Path.join(@models_folder_path, "paraphrase-MiniLM-L6-v2"),
    load_featurizer: false,
    load_tokenizer: true,
    load_generation_config: true
  }

def embedding() do
    load_offline_model(@embedding_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          # return n %Nx.Serving{} struct
          %Nx.Serving{} =
            Bumblebee.Text.TextEmbedding.text_embedding(
              model.model_info,
              model.tokenizer,
              defn_options: [compiler: EXLA],
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end


def verify_and_download_models() do
    force_models_download = Application.get_env(:app, :force_models_download, false)
    use_test_models = Application.get_env(:app, :use_test_models, false)

    case {force_models_download, use_test_models} do
      {true, true} ->
        File.rm_rf!(@models_folder_path)
        download_model(@captioning_test_model)
        download_model(@audio_test_model)

      {true, false} ->
        File.rm_rf!(@models_folder_path)
        download_model(@embedding_model)
        ^^^
        download_model(@captioning_prod_model)
        download_model(@audio_prod_model)

      {false, false} ->
        check_folder_and_download(@embedding_model)
        ^^
        check_folder_and_download(@captioning_prod_model)
        check_folder_and_download(@audio_prod_model)

      {false, true} ->
        check_folder_and_download(@captioning_test_model)
        check_folder_and_download(@audio_test_model)
    end
  end
```

You then add the `Nx.Serving` for the embeddings:

```elixir
#application.ex

children = [
  ...,
  {Nx.Serving,
    serving: App.Models.embedding(),
    name: Embedding,
    batch_size: 5
  },
  ...
]
```

Your `application.ex` file should look like so:

```elixir
defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger
  use Application

  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])

  @saved_index if Application.compile_env(:app, :knnindex_indices_test, false),
                 do: Path.join(@upload_dir, "indexes_test.bin"),
                 else: Path.join(@upload_dir, "indexes.bin")

  def check_models_on_startup do
    App.Models.verify_and_download_models()
    |> case do
      {:error, msg} ->
        Logger.error("⚠️ #{msg}")
        System.stop(0)

      :ok ->
        Logger.info("ℹ️ Models: ✅")
        :ok
    end
  end

  @impl true
  def start(_type, _args) do
    :ok = check_models_on_startup()

    children = [
      # Start the Telemetry supervisor
      AppWeb.Telemetry,
      # Setup DB
      App.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Nx serving for the embedding
      {Nx.Serving, serving: App.Models.embedding(), name: Embedding, batch_size: 1},
      # Nx serving for Speech-to-Text
      {Nx.Serving,
       serving:
         if Application.get_env(:app, :use_test_models) == true do
           App.Models.audio_serving_test()
         else
           App.Models.audio_serving()
         end,
       name: Whisper},
      # Nx serving for image classifier
      {Nx.Serving,
       serving:
         if Application.get_env(:app, :use_test_models) == true do
           App.Models.caption_serving_test()
         else
           App.Models.caption_serving()
         end,
       name: ImageClassifier},
      {GenMagic.Server, name: :gen_magic},

      # Adding a supervisor
      {Task.Supervisor, name: App.TaskSupervisor},
      # Start the Endpoint (http/https)
      AppWeb.Endpoint
      # Start a worker by calling: App.Worker.start_link(arg)
      # {App.Worker, arg}
    ]

    # We are starting the HNSWLib Index GenServer only during testing.
    # Because this GenServer needs the database to be seeded first,
    # we only add it when we're not testing.
    # When testing, you need to spawn this process manually (it is done in the test_helper.exs file).
    children =
      if Application.get_env(:app, :start_genserver, true) == true do
        Enum.concat(children, [{App.KnnIndex, [space: :cosine, index: @saved_index]}])
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

> [!NOTE]
>
> We have added a few alterations to how the supervision tree
> in `application.ex` is initialized.
> This is because we _test our code_,
> so that's why you see some of these changes above.
>
> If you don't want to change test the code,
> you can ignore the conditional changes that are made
> to the supervision tree according to the environment
> (which we do to check if the code is being tested or not).

### 4. Using the Index and embeddings

In this section, we'll go over how to use the Index
and the embeddings and tie everything together to
have a working application 😍.

If you want to better understand embeddings and
how to use `HNSWLib`,
the math behind it and see a working example
of running an embedding model,
you can check the next section.
However, _it is entirely optional_
and not necessary for our app.

#### 4.0 Working example on how to use `HNSWLib`

The code below can be run in an IEX session
or in a Livebook.

> [!NOTE]
>
> This whole section is _entirely optional_.
> It will just delve more deeply into embedding
> and provide you with a one-file working example
> where you can play around with vector embeddings
> and get a feel of how everything works.

You can endow the vector space with the following metrics by setting the `space` argument from the list:

`[:l2, :ip, :cosine]`

The first is the standard Euclidean metric, the second the inner product, and the third the pseudo-metric "cosine similarity".

We use the small model `"sentence-transformers/paraphrase-MiniLM-L6-v2"` to compute embeddings from text.
We then use it with `Nx.Serving` to run the model.

```elixir
Mix.install([
{:bumblebee, "~> 0.5.0"},
{:exla, "~> 0.7.0"},
{:nx, "~> 0.7.0 "},
{:hnswlib, "~> 0.1.5"},
])

Nx.global_default_backend(EXLA.Backend)

{:ok, index} =
  HNSWLib.Index.new(
    _space = :cosine,
    _dim = 384,
    _max_elements = 200
  )

transformer = "sentence-transformers/paraphrase-MiniLM-L6-v2"

{:ok, %{model: _, params: _} = model_info} =
      Bumblebee.load_model({:hf, transformer})

{:ok, tokenizer} =
  Bumblebee.load_tokenizer({:hf, transformer})

serving =
  Bumblebee.Text.TextEmbedding.text_embedding(
    model_info,
    tokenizer,
    defn_options: [compiler: EXLA],
    output_pool: :mean_pooling,
    output_attribute: :hidden_state,
    embedding_processor: :l2_norm
  )

HNSWLib.Index.get_current_count(index)
#{:ok, 0}
```

You compute an embedding for the word "short":

```elixir
input = "short"
# you compute the embedding
%{embedding: data} =
    Nx.Serving.run(serving, input)
```

and you get:

```elixir
%{
  embedding: #Nx.Tensor<
    f32[384]
    [-0.03144503012299538, 0.12630629539489746, 0.018703147768974304,...]
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

You can also enter a batch of items. You will only get back the last indice.
This means that you may need to persist the embedding if you want to identify the input in this case.

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
     [0.3143616318702698]
   ]
 >}
```

This means that the nearest neighbour of the given input has the indice "0" in the Index.
This corresponds to the entry "short".

We can recover the embedding to compare:

```elixir
{:ok, data} =
  HNSWLib.Index.get_items(
    index,
    Nx.to_flat_list(labels[0])
  )

Enum.map(data, fn
  d -> Nx.from_binary(d, :f32)
end)
|> Nx.stack()
```

The result is:

```elixir
##Nx.Tensor<
  f32[1][384]
  EXLA.Backend<host:0, 0.968243412.4269146128.215745>
  [
     [-0.031445033848285675, 0.12630631029605865, 0.018703149631619453,...]
  ]
```

You should now be able to
recover the first embedding.

##### 4.0.1 Notes on vector spaces

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

Consider now two normalised vectors. We have:
$\frac12||u-v||^2=1-\cos\widehat{u,v} = d_c(u,v)$

This is commonly known as the **cosine distance** _when the embeddings are normalised_. It ranges from 0 to 2. Note that it is not a true distance metric.

Finally, note that since we are dealing with finite dimensional vector spaces, all the norms are equivalent (in some precise mathematical way). This means that the limit points are always the same. However, the values of the distances can be quite different, and a "clusterisation" process can give significantly different results.

The first hint as to which norm to choose is to take the norm used to train the model.

#### 4.1 Computing the embeddings in our app

```elixir
@tmp_wav Path.expand("priv/static/uploads/tmp.wav")

def mount(_, _, socket) do
  {:ok,
    socket
    |> assign(
    ...,
    # Related to the Audio
    transcription: nil,
    mic_off?: false,
    audio_running?: false,
    audio_search_result: nil,
    tmp_wav: @tmp_wav,
    )
    |> allow_upload(:speech,...)
    [...]
  }
end
```

Recall that every time you upload an image,
you get back a URL from our bucket
and you compute a caption as a string.
We will now compute an embedding from this string
and save it in the Index.
This is done in the `handle_info` callback.

Update the Liveview `handle_info` callback where we handle the captioning results:

```elixir
def handle_info({ref, result}, %{assigns: assigns} = socket) do
  # Flush async call
    Process.demonitor(ref, [:flush])

    cond do
      # If the upload task has finished executing,
      # we update the socket assigns.
      Map.get(assigns, :task_ref) == ref ->
        image =
          %{
            url: assigns.image_info.url,
            width: assigns.image_info.width,
            height: assigns.image_info.height,
            description: label
          }

        with %{embedding: data} <-
               Nx.Serving.batched_run(Embedding, label),
             # compute a normed embedding (cosine case only) on the text result
             normed_data <-
               Nx.divide(data, Nx.LinAlg.norm(data)),
             {:check_used, {:ok, pending_image}} <-
               {:check_used, App.Image.check_before_append_to_index(image.sha1)} do
          {:ok, idx}  =
            App.KnnIndex.add_item(normed_data) do
          # save the App.Image to the DB
          Map.merge(image, %{idx: idx, caption: label})
          |> App.Image.insert()

          {:noreply,
           socket
           |> assign(
            upload_running?: false,
            task_ref: nil,
            label: label
           )
          }
        else
          {:error, msg} ->
            {:noreply,
             socket
             |> put_flash(:error, msg)
             |> assign(
              upload_running?: false,
              task_ref: nil,
              label: nil
            )
          }
        end
      [...]
    end
end
```

Every time we produce an audio file, we transcribe it into a text.
We then compute the embedding of the audio input transcription and run an ANN search.
The last step should return a (possibly) populated `%App.Image{}` struct with a look-up in the database.
We then update the `"audio_search_result"` assign with it and display the transcription.

Modify the following handler:

```elixir
def handle_info({ref, %{chunks: [%{text: text}]} = result}, %{assigns: assigns} = socket)
      when assigns.audio_ref == ref do
  Process.demonitor(ref, [:flush])
  File.rm!(@tmp_wav)

  # compute an normed embedding (cosine case only) on the text result
  # and returns an App.Image{} as the result of a "knn_search"
   with %{embedding: input_embedding} <-
           Nx.Serving.batched_run(Embedding, text),
         normed_input_embedding <-
           Nx.divide(input_embedding, Nx.LinAlg.norm(input_embedding)),
         {:not_empty_index, :ok} <-
           {:not_empty_index, App.KnnIndex.not_empty_index()},
         #  {:not_empty_index, App.HnswlibIndex.not_empty_index(index)},
         %App.Image{} = result <-
           App.KnnIndex.knn_search(normed_input_embedding) do

    {:noreply,
       assign(socket,
         transcription: String.trim(text),
         mic_off?: false,
         audio_running?: false,
         audio_search_result: result,
         audio_ref: nil,
         tmp_wav: @tmp_wav
       )}
  # record without entries
      {:not_empty_index, :error} ->
        {:noreply,
         assign(socket,
           mic_off?: false,
           audio_search_result: nil,
           audio_running?: false,
           audio_ref: nil,
           tmp_wav: @tmp_wav
         )}

      nil ->
        {:noreply,
         assign(socket,
           transcription: String.trim(text),
           mic_off?: false,
           audio_search_result: nil,
           audio_running?: false,
           audio_ref: nil,
           tmp_wav: @tmp_wav
         )}
    end
end
```

We next come back to the `knn_search` function we defined in the "KnnIndex" GenServer.
The "approximate nearest neighbour" search function uses the function `HNSWLib.Index.knn_query/3`.
It returns a tuple `{:ok, indices, distances}` where "indices" and "distances" are lists.
The length is the number of neighbours you want to find parametrized by the `k` parameter.
With `k=1`, we ask for a single neighbour.

> [!NOTE]
>
> You may further use a cut-off distance to exclude responses that might not be meaningful.

We will now display the found image with the URL field of the `%App.Image{}` struct.

Add this to `"page_live.html.heex"`:

```html
<!-- /lib/app_Web/live/page_live.html.heex -->

<div :if="{@audio_search_result}">
  <img src="{@audio_search_result.url}" alt="found_image" />
</div>
```

##### 4.1.1 Changing the `Image` schema so it's embeddable

Now we'll save the index found.
Let's add a column to the `Image` table.
To do this, run a `mix` task to generate a timestamped file.

```bash
mix ecto.gen.migration add_idx_to_images
```

In the `"/priv/repo"` folder, open the newly created file and add:

```elixir
defmodule App.Repo.Migrations.AddIdxToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add(:idx, :integer, default: 0)
      add(:sha1, :string)
    end
  end
end
```

and run the migration
by running `mix ecto.migrate`.

Modify the `App.Image` struct and the changeset:

```elixir
@primary_key {:id, :id, autogenerate: true}
schema "images" do
  field(:description, :string)
  field(:width, :integer)
  field(:url, :string)
  field(:height, :integer)
  field(:idx, :integer)
  field(:sha1, :string)

  timestamps(type: :utc_datetime)
end

def changeset(image, params \\ %{}) do
  image
  |> Ecto.Changeset.cast(params, [:url, :description, :width, :height, :idx, :sha1])
  |> Ecto.Changeset.validate_required([:width, :height])
  |> Ecto.Changeset.unique_constraint(:sha1, name: :images_sha1_index)
  |> Ecto.Changeset.unique_constraint(:idx, name: :images_idx_index)
end
```

We've added the fields `idx` and `sha1` to the image schema.
The former pertains to the index of the image
within the `HNSWLIB` index file,
so we can look for the image.
The latter pertains to the `sha1` representation of the image.
This will allow us to check if two images are the same,
so we can avoid adding duplicate images
and save some throughput in our application.

In our `changeset/2` function,
we've fundamentally added two `unique_constraint/3` functions
to check for the uniqueness of the newly added
`idx` and `sha1` function.
These are enforced at the database level so we don't have
duplicated images.

In addition to these changes,
we are going to need functions to
**calculate the `sha1` of the image**.
Add the following functions to the same file.

```elixir
  def calc_sha1(file_binary) do
    :crypto.hash(:sha, file_binary)
    |> Base.encode16()
  end

  def check_sha1(sha1) when is_binary(sha1) do
    App.Repo.get_by(App.Image, %{sha1: sha1})
    |> case do
      nil ->
        nil

      %App.Image{} = image ->
        {:ok, image}
    end
  end
```

- `calc_sha1/1` uses the `:crypto` package to hash the file binary
  and encode it.
- `check_sha1/1` fetches an image according to a given `sha1` code
  and returns the result.

And that's all we need to deal with our images!

##### 4.1.2 Using embeddings in semantic search

Now we have

- all the embedding models ready to be used,
- our Index file correctly created and maintained through
  filesystem and in the database in the `hnswlib_index` schema,
- the needed `sha1` functions to check for duplicated images.

It's time to bring everything together and use all of these tools
to implement semantic search into our application.

We are going to be working inside `lib/app_web/live/page_live.ex` from now on.

###### 4.1.2.1 Mount socket assigns

First, we are going to update our socket assigns on `mount/3`.

```elixir

  @image_width 640
  @accepted_mime ~w(image/jpeg image/jpg image/png image/webp)
  @tmp_wav Path.expand("priv/static/uploads/tmp.wav")

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       # Related to the file uploaded by the user
       label: nil,
       upload_running?: false,
       task_ref: nil,
       image_info: nil,
       image_preview_base64: nil,

       # Related to the list of image examples
       example_list_tasks: [],
       example_list: [],
       display_list?: false,

       # Related to the Audio
       transcription: nil,
       mic_off?: false,
       audio_running?: false,
       audio_search_result: nil,
       tmp_wav: @tmp_wav
     )
     |> allow_upload(:image_list,
       accept: ~w(image/*),
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1,
       chunk_size: 64_000,
       max_file_size: 5_000_000
     )
     |> allow_upload(:speech,
       accept: :any,
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1
     )}
  end
```

To reiterate:

- we've added a few fields related to audio.

  - `transcription` will pertain to the result of the audio transcription
    that will occur after transcribing the audio from the person.
  - `mic_off?` is simply a toggle to visually show the person
    whether the microphone is recording or not.
  - `audio_running?` is a boolean to show the person
    if the audio transcription and semantic searching are occuring (loading).
  - `audio_search_result` is the result of the image
    that is closest semantically to the image's label from the
    transcribed audio.
  - `tmp_wav` is the path of the temporary audio file
    that is saved in the filesystem while the audio is being transcribed.

- additionally, we also have added
  `allow_upload/3` pertaining to the audio upload
  (it is tagged as `:speech` and is being handled
  in the same function as the upload `:image_list`).

These are the socket assigns
that will allow us to dynamically update the person using our app
with what the app is doing.

###### 4.1.2.2 Consuming image uploads

As you can see, we are using `handle_progress/3`
with `allow_upload/3`.
As we know, `handle_progress/3` is called whenever an upload happens
(whether an image or recording of the person's voice).
We define two different declarations for how we want to
process `:image` uploads and `:speech` uploads.

Let's start with the first one.

We have added `sha1` and `idx` as fields to our image schema.
Therefore, we are going to need to make some changes
to the `handle_progress/3` of the `:image_list`.
Change it like so:

```elixir
def handle_progress(:image_list, entry, socket) when entry.done? do
    # We consume the entry only if the entry is done uploading from the image
    # and if consuming the entry was successful.
    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      with {:magic, {:ok, %{mime_type: mime}}} <- {:magic, magic_check(path)},
           # Check if file can be properly read
           {:read, {:ok, file_binary}} <- {:read, File.read(path)},
           # Check the image info
           {:image_info, {mimetype, width, height, _variant}} <-
             {:image_info, ExImageInfo.info(file_binary)},
           # Check mime type
           {:check_mime, :ok} <- {:check_mime, check_mime(mime, mimetype)},
           # Get SHA1 code from the image and check it
           sha1 = App.Image.calc_sha1(file_binary),
           {:sha_check, nil} <- {:sha_check, App.Image.check_sha1(sha1)},
           # Get image and resize
           {:ok, thumbnail_vimage} <- Vops.thumbnail(path, @image_width, size: :VIPS_SIZE_DOWN),
           # Pre-process the image as tensor
           {:pre_process, {:ok, tensor}} <- {:pre_process, pre_process_image(thumbnail_vimage)} do
        # Create image info to be saved as partial image
        image_info = %{
          mimetype: mimetype,
          width: width,
          height: height,
          sha1: sha1,
          description: nil,
          url: nil,
          # set a random big int to the "idx" field
          idx: :rand.uniform(1_000_000_000_000) * 1_000
        }

        # Save partial image
        App.Image.insert(image_info)
        |> case do
          {:ok, _} ->
            image_info =
              Map.merge(image_info, %{
                file_binary: file_binary
              })

            {:ok, %{tensor: tensor, image_info: image_info, path: path}}

          {:error, changeset} ->
            {:error, changeset.errors}
        end
        |> handle_upload()
      else
        {:magic, {:error, msg}} -> {:postpone, %{error: msg}}
        {:read, msg} -> {:postpone, %{error: inspect(msg)}}
        {:image_info, nil} -> {:postpone, %{error: "image_info error"}}
        {:check_mime, :error} -> {:postpone, %{error: "Bad mime type"}}
        {:sha_check, {:ok, %App.Image{}}} -> {:postpone, %{error: "Image already uploaded"}}
        {:pre_process, {:error, _msg}} -> {:postpone, %{error: "pre_processing error"}}
        {:error, reason} -> {:postpone, %{error: inspect(reason)}}
      end
    end)
    |> case do
      # If consuming the entry was successful, we spawn a task to classify the image
      # and update the socket assigns
      %{tensor: tensor, image_info: image_info} ->
        task =
          Task.Supervisor.async(App.TaskSupervisor, fn ->
            Nx.Serving.batched_run(ImageClassifier, tensor)
          end)

        # Encode the image to base64
        base64 = "data:image/png;base64, " <> Base.encode64(image_info.file_binary)

        {:noreply,
         assign(socket,
           upload_running?: true,
           task_ref: task.ref,
           image_preview_base64: base64,
           image_info: image_info
         )}

      # Otherwise, if there was an error uploading the image, we log the error and show it to the person.
      %{error: errors} ->
        Logger.warning("⚠️ Error uploading image. #{inspect(errors)}")
        {:noreply, push_event(socket, "toast", %{message: "Image couldn't be uploaded to S3"})}
    end
  end
```

Let's go over these changes.
Some of these is code that has been written prior,
but for clarification, we'll go over them again.

- we use `consume_uploaded_entry/3` to consume the image
  that the person uploads.
  To consume the image successfully,
  the image goes through an array of validations.

  - we use `magic_check/1` to check the MIME type of the image validity.
  - we read the contents of the image using `ExImageInfo.info/1`.
  - we check if the MIME type is valid using `check_mime/2`.
  - we calculate the `sha1` with the `App.Image.calc_sha1/1` function
    we've developed earlier.
  - we resize the image and scale it down to the same width
    as the images that are trained using the image captioning model we've chosen
    (to yield better results and to save memory bandwidth).
    We use `Vix.Operations.thumbnail/3` to resize the image.
  - finally, we convert the resized image to a tensor using
    `pre_process_image/1` so it can be consumed by our image captioning model.

- after this series of validations,
  we use the image info we've obtained earlier to
  **create an "early-save" of the image**.
  With this, we are saving the image and associating it with
  the `sha1` that was retrieved from the image contents.
  We are doing this "partial image saving"
  in case two identical images are being uploaded at the same time.
  Because we are enforcing `sha1` to be unique at the database level,
  this race condition is solved by the database optimistically.

- afterwards, we call `handle_upload/0`.
  This function will upload the image to the `S3` bucket.
  We are going to implement this function in just a second 😉.

- if the upload is successful,
  using the tensor and the image information from the previous steps,
  we spawn the async task to run the model.
  This step should be familiar to you
  since we've already implemented this.
  Finally, we update the socket assigns accordingly.

- we handle all possible errors in the `else` statement of the
  `with` flow control statement before the image is uploaded.

Hopefully, this demystifies some of the code we've just implemented!

Because we are using `handle_upload/0` in this function
to upload the image to our `S3` bucket,
let's do it right now!

```elixir
def handle_upload({:ok, %{path: path, tensor: tensor, image_info: image_info} = map})
    when is_map(map) do
  # Upload the image to S3
  Image.upload_image_to_s3(path, image_info.mimetype)
  |> case do
    # If the upload is successful, we update the socket assigns with the image info
    {:ok, url} ->
      image_info =
        struct(
          %ImageInfo{},
          Map.merge(image_info, %{url: url})
        )

      {:ok, %{tensor: tensor, image_info: image_info}}

    # If S3 upload fails, we return error
    {:error, reason} ->
      Logger.warning("⚠️ Error uploading image: #{inspect(reason)}")
      {:postpone, %{error: "Bucket error"}}
  end
end

def handle_upload({:error, error}) do
  Logger.warning("⚠️ Error creating partial image: #{inspect(error)}")
  {:postpone, %{error: "Error creating partial image"}}
end
```

This function is fairly easy to understand.
We upload the image by calling `Image.upload_image_to_s3/2` and,
if successful,
we add the returning URL to the image struct.
Otherwise, we handle the error and return it.

After this small detour,
let's implement the `handle_progress/3`
for the **`:speech` uploads**,
that is, the audio the person records.

```elixir
  def handle_progress(:speech, entry, %{assigns: assigns} = socket) when entry.done? do
    # We consume the audio file
    tmp_wav =
      socket
      |> consume_uploaded_entry(entry, fn %{path: path} ->
        tmp_wav = assigns.tmp_wav <> Ecto.UUID.generate() <> ".wav"
        :ok = File.cp!(path, tmp_wav)
        {:ok, tmp_wav}
      end)

    # After consuming the audio file, we spawn a task to transcribe the audio
    audio_task =
      Task.Supervisor.async(
        App.TaskSupervisor,
        fn ->
          Nx.Serving.batched_run(Whisper, {:file, tmp_wav})
        end
      )

    # Update the socket assigns
    {:noreply,
     assign(socket,
       audio_ref: audio_task.ref,
       mic_off?: true,
       tmp_wav: tmp_wav,
       audio_running?: true,
       audio_search_result: nil,
       transcription: nil
     )}
  end
```

As we know, this function is called after the upload is completed.
In the case of audio uploads,
the hook is called by the person recording their voice
in `assets/js/app.js`.
Similarly to the `handle_progress/3` function of the `:image_list` uploads,
we also use `consume_uploaded_entry/3` to consume the audio file.

- we consume the audio file and save it in our filesystem
  as a `.wav` file.
- we spawn the async task and use the `whisper` audio transcription model
  with the audio file we've just saved.
- we update the socket assigns accordingly.

Pretty simple, right?

###### 4.1.2.3 Using the embeddings to semantically search images

In this section, we'll finally use
our embedding model and semantically search for our images!

As you've seen in the previous section,
we've spawned the task to transcribe the audio into the `whipser` model.
Now we need a handler!
For this scenario,
add the following function.

```elixir
  @impl true
  def handle_info({ref, %{chunks: [%{text: text}]} = _result}, %{assigns: assigns} = socket)
      when assigns.audio_ref == ref do
    Process.demonitor(ref, [:flush])
    File.rm!(assigns.tmp_wav)

    # Compute an normed embedding (cosine case only) on the text result
    # and returns an App.Image{} as the result of a "knn_search"
    with {:not_empty_index, :ok} <-
           {:not_empty_index, App.KnnIndex.not_empty_index()},
         %{embedding: input_embedding} <-
           Nx.Serving.batched_run(Embedding, text),
         %Nx.Tensor{} = normed_input_embedding <-
           Nx.divide(input_embedding, Nx.LinAlg.norm(input_embedding)),
         %App.Image{} = result <-
           App.KnnIndex.knn_search(normed_input_embedding) do
      {:noreply,
       assign(socket,
         transcription: String.trim(text),
         mic_off?: false,
         audio_running?: false,
         audio_search_result: result,
         audio_ref: nil,
         tmp_wav: @tmp_wav
       )}
    else
      # Stop transcription if no entries in the Index
      {:not_empty_index, :error} ->
        {:noreply,
         socket
         |> push_event("toast", %{message: "No images yet"})
         |> assign(
           mic_off?: false,
           transcription: "!! The image bank is empty. Please upload some !!",
           audio_search_result: nil,
           audio_running?: false,
           audio_ref: nil,
           tmp_wav: @tmp_wav
         )}

      nil ->
        {:noreply,
         assign(socket,
           transcription: String.trim(text),
           mic_off?: false,
           audio_search_result: nil,
           audio_running?: false,
           audio_ref: nil,
           tmp_wav: @tmp_wav
         )}
    end
  end
```

Let's break down this function:

- given the **recording text transcription**:
  - we check if the Index file holding is _not empty_.
  - we use the text transcription and run it
    **through the embedding model** and get its result.
  - with the embedding we've received from the model,
    we **normalize it**.
  - with the normalized embedding,
    we \*\*run it through a `knn search`.
    For this, we call the `App.KnnIndex.knn_search/1` function
    we've defined in the `App.KnnIndex` GenServer
    we've implemented earlier on.
  - the `knn search` returns the closest semantical image
    (through the image caption)
    from the audio transcription.
  - upon the success of this process, we update the socket assigns.
  - otherwise, we handle each error case accordingly
    and update the socket assigns.

And that's it!
We just add to sequentially call the functions
that we've implemented prior!

###### 4.1.2.4 Creating embeddings when uploading images

Now that we have _used_ the embeddings,
there's one thing we forgot:
**we forgot to keep track of the embeddings of each image that is uploaded**.
These embeddings are saved in the Index file.

To fix this, we need to create an embedding of the image
after it is uploaded and captioned.
Head over to the `handle_info/2` pertaining to the image captioning,
and change it to the following piece of code:

```elixir
  def handle_info({ref, result}, %{assigns: assigns} = socket) do
    # Flush async call
    Process.demonitor(ref, [:flush])

    # You need to change how you destructure the output of the model depending
    # on the model you've chosen for `prod` and `test` envs on `models.ex`.)
    label =
      case Application.get_env(:app, :use_test_models, false) do
        true ->
          App.Models.extract_captioning_test_label(result)

        # coveralls-ignore-start
        false ->
          App.Models.extract_captioning_prod_label(result)
          # coveralls-ignore-stop
      end

    %{image_info: image_info} = assigns

    cond do
      # If the upload task has finished executing, we run the embedding model on the image
      Map.get(assigns, :task_ref) == ref ->
        image =
          %{
            url: image_info.url,
            width: image_info.width,
            height: image_info.height,
            description: label,
            sha1: image_info.sha1
          }

        # Create embedding task
        with %{embedding: data} <- Nx.Serving.batched_run(Embedding, label),
             # Compute a normed embedding (cosine case only) on the text result
             normed_data <- Nx.divide(data, Nx.LinAlg.norm(data)),
             # Check the SHA1 of the image
             {:check_used, {:ok, pending_image}} <-
               {:check_used, App.Image.check_sha1(image.sha1)} do
          Ecto.Multi.new()
          # Save updated Image to DB
          |> Ecto.Multi.run(:update_image, fn _, _ ->
            idx = App.KnnIndex.get_count() + 1

            Ecto.Changeset.change(pending_image, %{
              idx: idx,
              description: image.description,
              url: image.url
            })
            |> App.Repo.update()
          end)

          # Save Index file to DB
          |> Ecto.Multi.run(:save_index, fn _, _ ->
            {:ok, _idx} = App.KnnIndex.add_item(normed_data)
            App.KnnIndex.save_index_to_db()
          end)
          |> App.Repo.transaction()
          |> case do
            {:error, :update_image, _changeset, _} ->
              {:noreply,
               socket
               |> push_event("toast", %{message: "Invalid entry"})
               |> assign(
                 upload_running?: false,
                 task_ref: nil,
                 label: nil
               )}

            {:error, :save_index, _, _} ->
              {:noreply,
               socket
               |> push_event("toast", %{message: "Please retry"})
               |> assign(
                 upload_running?: false,
                 task_ref: nil,
                 label: nil
               )}

            {:ok, _} ->
              {:noreply,
               socket
               |> assign(
                 upload_running?: false,
                 task_ref: nil,
                 label: label
               )}
          end
        else
          {:check_used, nil} ->
            {:noreply,
             socket
             |> push_event("toast", %{message: "Race condition"})
             |> assign(
               upload_running?: false,
               task_ref: nil,
               label: nil
             )}

          {:error, msg} ->
            {:noreply,
             socket
             |> push_event("toast", %{message: msg})
             |> assign(
               upload_running?: false,
               task_ref: nil,
               label: nil
             )}
        end

      # If the example task has finished executing, we upload the socket assigns.
      img = Map.get(assigns, :example_list_tasks) |> Enum.find(&(&1.ref == ref)) ->
        # Update the element in the `example_list` enum to turn "predicting?" to `false`
        updated_example_list = update_example_list(assigns, img, label)

        {:noreply,
         assign(socket,
           example_list: updated_example_list,
           upload_running?: false,
           display_list?: true
         )}
    end
  end
```

Let's go over the flow of this function:

- we extract the captioning label from the result of the image captioning model.
  This code is the same as it was before.
- afterwards, we get the label
  and **feed it into the embedding model**.
- the embedding model yields the embedding,
  _we normalize it_ and **check if the `sha1` code of the image is already being used**.
- if these three processes occur successfuly,
  we perform a _database transaction_ where
  we **save the updated image to the database**,
  **update the Index file count (we increment it)**
  and **save the index file to the database**.
- we finally update the socket assigns accordingly.
- if any of the previous calls fail,
  we handle these error scenarios
  and update the socket assigns.

And that's it!
Our app is fully loaded with semantic search capabilities! 🔋

###### 4.1.2.5 Update the LiveView view

All that's left is updating our view.
We are going to add basic elements
to make this transition as smooth as possible.

Head over to `lib/app_web/live/page_live.html.heex`
and update it as so:

```html
<div class="hidden" id="tracker_el" phx-hook="ActivityTracker" />
<div
  class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-24 lg:px-8 xl:px-28 xl:py-32"
>
  <div class="flex flex-col justify-start">
    <div class="flex justify-center items-center w-full">
      <div class="2xl:space-y-12">
        <div class="mx-auto max-w-2xl lg:text-center">
          <p>
            <span
              class="rounded-full w-fit bg-brand/5 px-2 py-1 text-[0.8125rem] font-medium text-center leading-6 text-brand"
            >
              <a
                href="https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html"
                target="_blank"
                rel="noopener noreferrer"
              >
                🔥 LiveView
              </a>
              +
              <a
                href="https://github.com/elixir-nx/bumblebee"
                target="_blank"
                rel="noopener noreferrer"
              >
                🐝 Bumblebee
              </a>
            </span>
          </p>
          <p
            class="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl"
          >
            Caption your image!
          </p>
          <h3 class="mt-6 text-lg leading-8 text-gray-600">
            Upload your own image (up to 5MB) and perform image captioning with
            <a
              href="https://elixir-lang.org/"
              target="_blank"
              rel="noopener noreferrer"
              class="font-mono font-medium text-sky-500"
            >
              Elixir
            </a>
            !
          </h3>
          <p class="text-lg leading-8 text-gray-400">
            Powered with
            <a
              href="https://elixir-lang.org/"
              target="_blank"
              rel="noopener noreferrer"
              class="font-mono font-medium text-sky-500"
            >
              HuggingFace🤗
            </a>
            transformer models, you can run this project locally and perform
            machine learning tasks with a handful lines of code.
          </p>
        </div>
        <div></div>
        <div class="border-gray-900/10">
          <!-- File upload section -->
          <div class="col-span-full">
            <div
              class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
              phx-drop-target="{@uploads.image_list.ref}"
            >
              <div class="text-center">
                <!-- Show image preview -->
                <%= if @image_preview_base64 do %>
                <form id="upload-form" phx-change="noop" phx-submit="noop">
                  <label class="cursor-pointer">
                    <%= if not @upload_running? do %> <.live_file_input
                    upload={@uploads.image_list} class="hidden" /> <% end %>
                    <img src="{@image_preview_base64}" />
                  </label>
                </form>
                <% else %>
                <svg
                  class="mx-auto h-12 w-12 text-gray-300"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                    clip-rule="evenodd"
                  />
                </svg>
                <div class="mt-4 flex text-sm leading-6 text-gray-600">
                  <label
                    for="file-upload"
                    class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                  >
                    <form id="upload-form" phx-change="noop" phx-submit="noop">
                      <label class="cursor-pointer">
                        <.live_file_input upload={@uploads.image_list}
                        class="hidden" /> Upload
                      </label>
                    </form>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs leading-5 text-gray-600">
                  PNG, JPG, GIF up to 5MB
                </p>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        <!-- Show errors -->
        <%= for entry <- @uploads.image_list.entries do %>
        <div class="mt-2">
          <%= for err <- upload_errors(@uploads.image_list, entry) do %>
          <div class="rounded-md bg-red-50 p-4 mb-2">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-red-400"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">
                  <%= error_to_string(err) %>
                </h3>
              </div>
            </div>
          </div>
          <% end %>
        </div>
        <% end %>
        <!-- Prediction text -->
        <div
          class="flex mt-2 space-x-1.5 items-center font-bold text-gray-900 text-xl"
        >
          <span>Description: </span>
          <!-- conditional Spinner or display caption text or waiting text-->
          <AppWeb.Spinner.spin spin="{@upload_running?}" />
          <%= if @label do %>
          <span class="text-gray-700 font-light"><%= @label %></span>
          <% else %>
          <span class="text-gray-300 font-light">Waiting for image input.</span>
          <% end %>
        </div>
      </div>
    </div>
    <!-- Audio -->
    <br />
    <div class="mx-auto max-w-2xl lg">
      <h2
        class="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl text-center"
      >
        Semantic search using an audio
      </h2>
      <br />
      <p>
        Please record a phrase. You can listen to your audio. It will be
        transcripted automatically into a text and appear below. The semantic
        search for matching images will then run automatically and the found
        image appear below.
      </p>
      <br />
      <form
        id="audio-upload-form"
        phx-change="noop"
        class="flex flex-col items-center"
      >
        <.live_file_input upload={@uploads.speech} class="hidden" />
        <button
          id="record"
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold px-4 rounded flex"
          type="button"
          phx-hook="Audio"
          disabled="{@mic_off?}"
        >
          <Heroicons.microphone
            outline
            class="w-6 h-6 text-white font-bold group-active:animate-pulse"
          />
          <span id="text">Record</span>
        </button>
      </form>
      <br />
      <p class="flex flex-col items-center">
        <audio id="audio" controls></audio>
      </p>
      <br />
      <div
        class="flex mt-2 space-x-1.5 items-center font-bold text-gray-900 text-xl"
      >
        <span>Transcription: </span>
        <AppWeb.Spinner.spin spin="{@audio_running?}" />
        <%= if @transcription do %>
        <span id="output" class="text-gray-700 font-light"
          ><%= @transcription %></span
        >
        <% else %>
        <span class="text-gray-300 font-light">Waiting for audio input.</span>
        <% end %>
      </div>
      <br />

      <div :if="{@audio_search_result}">
        <div class="border-gray-900/10">
          <div
            class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
          >
            <img src="{@audio_search_result.url}" alt="found_image" />
          </div>
        </div>
      </div>
    </div>
    <!-- Examples -->
    <div :if="{@display_list?}" class="flex flex-col">
      <h3
        class="mt-10 text-xl lg:text-center font-light tracking-tight text-gray-900 lg:text-2xl"
      >
        Examples
      </h3>
      <div class="flex flex-row justify-center my-8">
        <div
          class="mx-auto grid max-w-2xl grid-cols-1 gap-x-6 gap-y-20 sm:grid-cols-2"
        >
          <%= for example_img <- @example_list do %>
          <!-- Loading skeleton if it is predicting -->
          <%= if example_img.predicting? == true do %>
          <div
            role="status"
            class="flex items-center justify-center w-full h-full max-w-sm bg-gray-300 rounded-lg animate-pulse"
          >
            <img src={~p"/images/spinner.svg"} alt="spinner" />
            <span class="sr-only">Loading...</span>
          </div>
          <% else %>
          <div>
            <img
              id="{example_img.url}"
              src="{example_img.url}"
              class="rounded-2xl object-cover"
            />
            <h3 class="mt-1 text-lg leading-8 text-gray-900 text-center">
              <%= example_img.label %>
            </h3>
          </div>
          <% end %>
        </div>
      </div>
    </div>
  </div>
</div>
```

As you may have noticed,
we've made some changes to the Audio portion of the HTML.

- we check if the `@transcription` assign exists.
  If so, we display the text to the person.
- we check if the `@audio_search_result` assign is not `nil`.
  If that's the case, the image that is semantically closest
  to the audio transcription is shown to the person.

And that's it!
We are simply showing the person
the results.

And with that, you've successfully added
semantic searching into the application!
Pat yourself on the back! 👏

You've expanded your knowledge in key areas of machine learning
and artificial intelligence,
that is increasingly becoming more prevalent!

## _Please_ star the repo! ⭐️

If you find this package/repo useful,
please star it on GitHub, so that we know! ⭐

Thank you! 🙏

```

```
