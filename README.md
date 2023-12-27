<div align="center">

# Image Captioning in `Elixir`

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/dwyl/image-classifier/ci.yml?label=build&style=flat-square&branch=main)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/image-classifier/main.svg?style=flat-square)](https://codecov.io/github/dwyl/image-classifier?branch=main)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/image-classifier/issues)
[![HitCount](https://hits.dwyl.com/dwyl/image-classifier.svg?style=flat-square&show=unique)](https://hits.dwyl.com/dwyl/image-classifier)

Caption your images using
machine learning models
within `Phoenix`!

<p align="center">
  <img src="https://github.com/dwyl/image-classifier/assets/17494745/05d0b510-ef9a-4a51-8425-d27902b0f7ad">
</p>

</div>

<br />

- [Image Captioning in `Elixir`](#image-captioning-in-elixir)
- [Why? 🤷](#why-)
- [What? 💭](#what-)
- [Who? 👤](#who-)
- [How? 💻](#how-)
  - [Prerequisites](#prerequisites)
  - [0. Creating a fresh `Phoenix` project](#0-creating-a-fresh-phoenix-project)
  - [1. Installing initial dependencies](#1-installing-initial-dependencies)
  - [2. Adding `LiveView` capabilities to our project](#2-adding-liveview-capabilities-to-our-project)
  - [3. Receiving image files](#3-receiving-image-files)
  - [4. Integrating `Bumblebee` 🐝](#4-integrating-bumblebee-)
    - [4.1 `Nx` configuration ⚙️](#41-nx-configuration-️)
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
- [Benchmarking models](#benchmarking-models)
- [_Please_ Star the repo! ⭐️](#please-star-the-repo-️)

<br />

# Why? 🤷

Building our
[app](https://github.com/dwyl/app),
we consider `images` an _essential_
medium of communication.

By adding a way of captioning images,
we make it _easy_ for people
to suggest meta tags to describe images
so they become **searchable**.

# What? 💭

This run-through will create a simple
`Phoenix` web application
that will allow you to choose/drag an image
and caption the image.

# Who? 👤

This tutorial is aimed at `Phoenix` beginners
that want to grasp how to do image captioning
within a `Phoenix` application.

If you are completely new to `Phoenix` and `LiveView`,
we recommend you follow the **`LiveView` _Counter_ Tutorial**:
[dwyl/phoenix-liveview-counter-tutorial](https://github.com/dwyl/phoenix-liveview-counter-tutorial)

# How? 💻

In this chapter, we'll go over the development process
of this small application.
You'll learn how to do this _yourself_,
so grab some coffee and let's get cracking!

## Prerequisites

This tutorial requires you have `Elixir` and `Phoenix` installed. <br />
If you you don't, please see
[how to install Elixir](https://github.com/dwyl/learn-elixir#installation)
and
[Phoenix](https://hexdocs.pm/phoenix/installation.html#phoenix).

This guide assumes you know the basics of `Phoenix`
and have _some_ knowledge of how it works.
If you don't,
we _highly suggest_ you follow our other tutorials first.
e.g:
[github.com/dwyl/**phoenix-chat-example**](https://github.com/dwyl/phoenix-chat-example)

In addition to this,
**_some_ knowledge of `AWS`** -
what it is, what an `S3` bucket is/does -
**is assumed**.

> [!NOTE]
> if you have questions or get stuck,
> please open an issue!
> [/dwyl/image-classifier/issues](https://github.com/dwyl/image-classifier/issues)

## 0. Creating a fresh `Phoenix` project

Let's create a fresh `Phoenix` project.
Run the following command in a given folder:

```sh
mix phx.new . --app app --no-dashboard --no-ecto  --no-gettext --no-mailer
```

We're running [`mix phx.new`](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html)
to generate a new project without a dashboard
and mailer (email) service,
since we don't need those features in our project.

After this,
if you run `mix phx.server` to run your server,
you should be able to see the following page.

<p align="center">
  <img src="https://github.com/dwyl/fields/assets/194400/891e890e-c94a-402e-baee-ee47fd3725a7">
</p>

We're ready to start building.

## 1. Installing initial dependencies

Now that we're ready to go,
let's start by adding some dependencies.

Head over to `mix.exs`
and add the following dependencies
to the `deps` section.

```elixir
{:bumblebee, "~> 0.4.2"},
{:exla, "~> 0.6.1"},
{:nx, "~> 0.6.2"},
{:vix, "~> 0.23.1"}
```

- [**`bumblebee`**](https://github.com/elixir-nx/bumblebee),
  a framework that will allows us to integrate
  [`Transformer Models`](https://huggingface.co/docs/transformers/index) in `Phoenix`.
  `Transformers` (from [Hugging Face](https://huggingface.co/))
  are APIs that allow us to easily download and train
  [pretrained models](https://blogs.nvidia.com/blog/2022/12/08/what-is-a-pretrained-ai-model).
  `Bumblebee` aims to support all Transformer Models,
  however some are lacking.
  You may check which ones are supported by visiting
  `Bumblebee`'s repository
  or visiting https://jonatanklosko-bumblebee-tools.hf.space/apps/repository-inspector
  and checking if the model is currently supported.

- [**`EXLA`**](https://hexdocs.pm/exla/EXLA.html),
  Elixir implementation of [Google's XLA](https://www.tensorflow.org/xla/),
  a compiler that provides faster linear algebra calculations
  with `TensorFlow` models.
  This backend compiler is needed for [`Nx`](https://github.com/elixir-nx/nx),
  a framework that allows support for tensors and numerical definitions
  in Elixir.
  We are installing `EXLA` because allows us to compile models
  _just-in-time_ and run them on CPU and/or GPU.

- [**`Nx`**](https://hexdocs.pm/nx/Nx.html),
  a library that allows us to work with
  [`Numerical Elixir`](https://github.com/elixir-nx/),
  Elixir's way of doing [numerical computing](https://www.hilarispublisher.com/open-access/introduction-to-numerical-computing-2168-9679-1000423.pdf).

- [**`Vix`**](https://hexdocs.pm/vix/readme.html),
  an image processing library.

In `config/config.exs`,
let's add our `:nx` configuration
to use `EXLA`.

```elixir
config :nx, default_backend: EXLA.Backend
```

## 2. Adding `LiveView` capabilities to our project

As it stands,
our project is not using `LiveView`.
Let's fix this.

In `lib/app_web/router.ex`,
change the `scope "/"` to the following.

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
<.flash_group flash={@flash} />
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

## 3. Receiving image files

Now, let's start by receiving some image files.
In order to classify them, we need to have access to begin with,
right?

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

- used
  [`<.live_file_input/>`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#live_file_input/1)
  for `LiveView` file upload.
  We've wrapped this component
  with an element that is annotated with the `phx-drop-target` attribute
  pointing to the DOM `id` of the file input.
- because `<.live_file_input/>` is being used,
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
     |> assign(label: nil, running: false, task_ref: nil)
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

  defp handle_progress(:image_list, entry, socket) do
    #if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: _path} = _meta ->
          {:ok, entry}
        end)
    end

    {:noreply, socket}
  end

  defp handle_progress(:iamge_list, _, socket), do: {:noreply, socket}
end
```

- when `mount/3`ing the LiveView,
  we are creating three socket assigns:
  `label` pertains to the model prediction;
  `running` is a boolean referring to whether the model is running or not;
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
  When the chunks are all consummed, we get the boolean `entry.done? == true`.
  We consume the file in this function by using
  [`consume_uploaded_entry/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#consume_uploaded_entry/3).
  The anonymous function to return `{:ok, data}` or `{:postpone, message}`.
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
If you run `mix phx.server`,
nothing will change.


## 4. Integrating `Bumblebee` 🐝

Now here comes the fun part!
It's time to do some image captioning! 🎉


### 4.1 `Nx` configuration ⚙️

We first need to add some initial setup in the
`lib/app/application.ex` file.
Head over there and and change
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
    # Start a worker by calling: App.Worker.start_link(arg)
    # {App.Worker, arg}
  ]

  # See https://hexdocs.pm/elixir/Supervisor.html
  # for other strategies and supported options
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

We are using
[`Nx.Serving`](https://hexdocs.pm/nx/Nx.Serving.html),
which simply allows us to encapsulates tasks,
be it networking, machine learning, data processing or any other task.

In this specific case,
we are using it to **batch requests**.
This is extremely useful and important
because we are using models that typically run on
[GPU](https://en.wikipedia.org/wiki/Graphics_processing_unit).
The GPU is _really good_ at **parallelizing tasks**.
Therefore, instead of sending an image classification request one by one,
we can _batch them_/bundle them together as much as we can
and then send it over.

We can define the `batch_size` and `batch_timeout` with `Nx.Serving`.
We're going to use the default values,
hence why we're not explicitly defining them.

With `Nx.Serving`, we define a `serving/0` function
that is then used by it,
which in turn is executed in the supervision tree.

In the `serving/0` function,
we are loading the
[`ResNet-50`](https://huggingface.co/microsoft/resnet-50)
model
and its featurizer.

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

Lastly, this function returns
a builds serving for image classification
by calling [`image_classification/3`](https://hexdocs.pm/bumblebee/Bumblebee.Vision.html#image_classification/3),
where we can define our compiler and task batch size.
We've given our serving function the name `ImageClassifier`.


### 4.2 `Async` processing the image for classification

Now we're ready to send the image to the model
and get a prediction of it!

Every time we upload an image,
we are going to run **async processing**.
This means that the task responsible for image classification
will be created asynchronously,
meaning that the LiveView _won't have to wait_ for this task to finish
to continue working.

For this scenario,
we are going to be using the
[`Task` module](https://hexdocs.pm/elixir/1.14/Task.html)
to spawn processes to complete this task.

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
    {:noreply, assign(socket, running: true, task_ref: task.ref)}
end

@impl true
def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket) do
  # This is called everytime an Async Task is created.
  # We flush it here.
  Process.demonitor(ref, [:flush])

  # And then destructure the result from the classifier.
  %{predictions: [%{label: label}]} = result

  # Update the socket assigns with result and stopping spinner.
  {:noreply, assign(socket, label: label, running: false)}
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
and update the `:running` assign to `true`,
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
and set `:running` to `false`.

Quite beautiful, isn't it?
With this, we don't have to worry if the person closes the browser tab.
The process dies (as does our `LiveView`),
and the work is automatically cancelled,
meaning no resources are spent
on a process for which nobody expects a result anymore.

#### 4.2.1 Considerations regarding `async` processes

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


#### 4.2.2 Alternative for better testing

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

### 4.3 Image pre-processing

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

The resulting image has its colourspaced changed
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
          <%= if @running do %>
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
if the `:running` socket assign is set to true.
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


### 4.5 Check it out!

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
You can see the supported models in https://github.com/elixir-nx/bumblebee#model-support.


### 4.6 Considerations on user images

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
to decode and downsize this image in the client-side,
reducing server workload.

You can see an example implementation of this technique
in `Bumblebee`'s repository
at https://github.com/elixir-nx/bumblebee/blob/main/examples/phoenix/image_classification.exs

However, since we are not using `JavaScript` for anything,
we can (and _should_!) properly downsize our images
so they better fit the training dataset of the model we use.
This will allow the model to process faster,
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

## 5. Final Touches

Although our app is functional,
we can make it **better**. 🎨

### 5.1 Setting max file size

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
     |> assign(label: nil, running: false, task_ref: nil)
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


### 5.2 Show errors

In case a person uploads an image that is too large,
we should show this feedback to the person!

For this, we can leverage the
[`upload_errors/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#upload_errors/2)
function.
This function will return the entry errors for an upload.
We need to add an handler for one of these errors to show it first.

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


### 5.3 Show image preview

As of now, even though our app predicts the given images,
it is not showing a preview of the image the person submitted.
Let's fix this 🛠️.

Let's add a new socket assign variable
pertaining to the [base64](https://en.wikipedia.org/wiki/Base64) representation
of the image in `lib/app_web/live_page/live.ex`

```elixir
     |> assign(label: nil, running: false, task_ref: nil, image_preview_base64: nil)
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
      {:noreply, assign(socket, running: true, task_ref: task.ref, image_preview_base64: base64)}
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


## 6. What about other models?

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

    {:noreply, assign(socket, label: label, running: false)}
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


## 7. How do I deploy this thing?

There are a few considerations you may want to have
before considering deploying this.
Luckily for you,
we've created a small document
that will **guide you through deploying this app in `fly.io`**!

Check the [`deployment.md`](./deployment.md) file for more information.


## 8. Showing example images

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


### 8.1 Creating a hook in client

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
  You can find more information in https://hexdocs.pm/phoenix_live_view/js-interop.html.
- inside the `mounted()` function,
  we create a `resetInactivityTimer()` function
  that is executed every time the
  **mouse moves** (`mousemove` event)
  and a **key is pressed**(`keydown`).
  This function resets the timer
  that is run whilst there is lack of inactivity.
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
      running?: false,
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
we need to create a handler to our `"show_examples"` event.

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
  with images that are in the same resolution of the dataset the model was trained in.
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
         {:pre_process, {:ok, t_img}} <- {:pre_process, pre_process_image(img_thumb)} do

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

Now we need to handle these newly-created async tasks
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
        {:noreply, assign(socket, label: label, running?: false)}

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
           running?: false,
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


### 8.3 Updating the view 

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
          <%= if @running? do %>
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


### 8.4 Using URL of image instead of base64-encoded

While our example list is being correctly rendered,
we are using additional CPU
to base64 encode our images
so they can be shown to the person.

Initially we did this because
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
      {stage, error} -> {stage, error}
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
        {:noreply, assign(socket, label: label, running?: false)}

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
           running?: false,
           display_list?: true
         )}
    end
  end
```

And that's it!

That last thing we need to do is change our view
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

### 8.5 See it running

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


## 9. Store metadata and classification info

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


### 9.1 Installing dependencies

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


### 9.2 Adding `Postgres` configuration files

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


### 9.3 Creating `Image` schema

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


### 9.4 Changing our LiveView to persist data

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
       running?: false,
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
      {:noreply, assign(socket, running?: true, task_ref: task.ref, image_preview_base64: base64, image_info: image_info)}
    #else
    #  {:noreply, socket}
    #end
  end
```

Check the comment lines for more explanation on the changes that have bee nmade.
We are using `ExImageInfo` to fetch the information from the image
and assigning it to the `image_info` socket we've defined earlier.

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
        {:noreply, assign(socket, label: label, running?: false)}


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
> You can learn more about it in https://github.com/dwyl/learn-postgresql.

## 10. Adding double MIME type check and showing feedback to the person in case of failure

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

We are also introducing a double MIME type check to ensure that only
image files are uploaded and processed.
We use [GenMagic](https://hexdocs.pm/gen_magic/readme.html) provides supervised and customisable access to `libmagic` using a supervised external process.
[This gist](https://gist.github.com/leommoore/f9e57ba2aa4bf197ebc5) explains that Magic numbers are the first bits of a file
which uniquely identify the type of file.

We use the GenMagic server as a daemon; it is started in the Application module.
It is referenced by its name.
When we run `perform`, we obtain a map and compare the mime type with the one
read by `ExImageInfo`.
If they correspond with each other, 
we continue, else we stop the process.

On your computer, 
in order for this to work locally
you should install the package `libmagic-dev`.

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
This dependency will allow us to access `libmagic` 
through `Elixir`.

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

In the Dockerfile (needed to deploy this app), 
we will install the `libmagic-dev` as well:

```Dockerfile
RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates libmagic-dev\
  && apt-get clean && rm -f /var/lib/apt/lists/*_*
```

Add the follwing function in the module App.Image:

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
        Logger.warning(%{gen_magic_response: res})
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
          consume_uploaded_entry(socket, entry, fn %{} = meta ->
             with {:magic, {:ok, %{mime_type: mime}}} <-
                    {:magic, magic_check(path)},
                  file_binary <- File.read!(path),
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
        running?: true,
        task_ref: task.ref,
        image_preview_base64: base64,
        image_info: image_info
      )}

    # Otherwise, if there was an error uploading the image, we log the error and show it to the person.
  else
    %{error: reason} ->
      Logger.info("Error uploading image. #{inspect(reason)}")
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


### 10.1 Showing a toast component with error

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

If `imgup` is down or the image that was sent was,
for example, invalid,
an error should be shown,
like so.

<p align="center">
  <img width="800" src="https://github.com/dwyl/image-classifier/assets/17494745/d730d10c-b45e-4dce-a37a-bb389c3cd548" />
</p>



# Benchmarking models

You may be wondering which model is best suitable for me?
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


# _Please_ Star the repo! ⭐️

If you find this package/repo useful,
please star on GitHub, so that we know! ⭐

Thank you! 🙏
