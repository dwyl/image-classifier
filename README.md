<div align="center">

# Image Captioning in `Elixir`

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/dwyl/image-classifier/ci.yml?label=build&style=flat-square&branch=main)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/image-classifier/main.svg?style=flat-square)](https://codecov.io/github/dwyl/image-classifier?branch=main)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/image-classifier/issues)
[![HitCount](https://hits.dwyl.com/dwyl/image-classifier.svg?style=flat-square&show=unique)](https://hits.dwyl.com/dwyl/image-classifier)

Caption your images using 
machine learning models
within `Phoenix`!

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
- [4. Integrating `Bumblebee`](#4-integrating-bumblebee)
  - [4.1 `Nx` configuration](#41-nx-configuration)
  - [4.2 `Async` processing the image for classification](#42-async-processing-the-image-for-classification)
    - [4.2.1 Considerations regarding `async` processes](#421-considerations-regarding-async-processes)
    - [4.2.2 Alternative for better testing](#422-alternative-for-better-testing)
  - [4.3 Image pre-processing](#43-image-pre-processing)
  - [4.4 Updating the view](#44-updating-the-view)
  - [4.5 Check it out!](#45-check-it-out)
  - [4.6 Considerations on user images](#46-considerations-on-user-images)
- [5. Final touches](#5-final-touches)
  - [5.1 Setting max file size](#51-setting-max-file-size)
  - [5.2 Show errors](#52-show-errors)
  - [5.3 Show image preview](#53-show-image-preview)
- [6. What about other models?](#6-what-about-other-models)
- [_Please_ Star the repo! ⭐️](#please-star-the-repo-️)


<br />

# Why? 🤷

Building our 
[app](https://github.com/dwyl/app),
we consider `images` an _essential_ 
medium of communication.

By adding a way of captioning images,
we make it *easy* for people
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
You'll learn how to do this *yourself*,
so grab some coffee and let's get cracking!


## Prerequisites 

This tutorial requires you have `Elixir` and `Phoenix` installed.
If you you don't, please see 
[how to install Elixir](https://github.com/dwyl/learn-elixir#installation)
and 
[Phoenix](https://hexdocs.pm/phoenix/installation.html#phoenix).

We assume you know the basics of `Phoenix` 
and have *some* knowledge of how it works.
If you don't, 
we *highly suggest* you follow our other tutorials first.
e.g: 
[github.com/dwyl/**phoenix-chat-example**](https://github.com/dwyl/phoenix-chat-example)

In addition to this,
**_some_ knowledge of `AWS`** - 
what it is, what an `S3` bucket is/does -
**is assumed**. 

> **Note**: if you have questions or get stuck,
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
since we don't need those in our project.

After this,
if you run `mix phx.server` to run your server,
you should be able to see the following page.

<p align="center">
  <img src="https://github.com/dwyl/imgup/assets/17494745/b40f4e79-e225-4226-8112-c490b5b4bf46">
</p>

We're ready to start implementing!


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
are APIs that allow us to easily download and train pretrained models.
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
*just-in-time* and run them on CPU and/or GPU.

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
we are going to be creating `ImgupLive`,
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
<div class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
  <div class="flex justify-center items-center mx-auto max-w-xl w-[50vw] lg:mx-0">
    <form>
      <div class="space-y-12">
        <div>
          <h2 class="text-base font-semibold leading-7 text-gray-900">Image Classifier</h2>
          <p class="mt-1 text-sm leading-6 text-gray-600">Drag your images and we'll run an AI model to caption it!</p>

          <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">

            <div class="col-span-full">
              <div class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10">
                <div class="text-center">
                  <svg class="mx-auto h-12 w-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                    <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z" clip-rule="evenodd" />
                  </svg>
                  <div class="mt-4 flex text-sm leading-6 text-gray-600">
                    <label for="file-upload" class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
                      <span>Upload a file</span>
                      <input id="file-upload" name="file-upload" type="file" class="sr-only">
                    </label>
                    <p class="pl-1">or drag and drop</p>
                  </div>
                  <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 5MB</p>
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
    <.flash_group flash={@flash} />
    <%= @inner_content %>
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
<div class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
  <div class="flex justify-center items-center mx-auto max-w-xl w-[50vw] lg:mx-0">
    <div class="space-y-12">
      <div class="border-gray-900/10 pb-12">
        <h2 class="text-base font-semibold leading-7 text-gray-900">Image Classification</h2>
        <p class="mt-1 text-sm leading-6 text-gray-600">
            Do simple captioning with this <a href="https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html" class="font-mono font-medium text-sky-500">LiveView</a>
            demo, powered by <a href="https://github.com/elixir-nx/bumblebee" class="font-mono font-medium text-sky-500">Bumblebee</a>.
        </p>

        <!-- File upload section -->
        <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">

          <div class="col-span-full">
            <div
              class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
              phx-drop-target={@uploads.image_list.ref}
            >
              <div class="text-center">
                <svg class="mx-auto h-12 w-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z" clip-rule="evenodd" />
                </svg>
                <div class="mt-4 flex text-sm leading-6 text-gray-600">
                  <label for="file-upload" class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
                    <form phx-change="validate" phx-submit="save">
                      <label class="cursor-pointer">
                        <.live_file_input upload={@uploads.image_list} class="hidden" />
                        Upload
                      </label>
                    </form>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 5MB</p>
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

- used [`<.live_file_input/>`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#live_file_input/1)
for `LiveView` file upload.
We've wrapped this component
with an element that is annotated with the `phx-drop-target` attribute
pointing to the DOM `id` of the file input.
- because `<.live_file_input/>` is being used,
we need to annotate its wrapping element
with `phx-submit` and `phx-change`, 
as per https://hexdocs.pm/phoenix_live_view/uploads.html#render-reactive-elements.

Because we've added these bindings,
we need to add the event handlers in 
`lib/app_web/live/imgup_live.ex`.
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
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{} = _meta ->
          {:ok, entry}
        end)
    end

    {:noreply, socket}
  end
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
we are telling `LiveView` that *whenever the person uploads a file*,
**it is processed immediately and consumed**.

- the `progress` field is handled by the `handle_progress/3` function.
We consume the file in this function by using 
[`consume_uploaded_entry/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#consume_uploaded_entry/3).
Whilst consuming the entry/file,
we can access its path and then use it to our heart's content.
*For now*, we don't need to use it.
But we will in the future to feed our image classifier with it!
After the callback function is executed,
this function "consumes the entry",
essentially deleting the image from the temporary folder
and removing it from the uploaded files list.

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


# 4. Integrating `Bumblebee`

Now here comes the fun part!
It's time to do some image captioning! 🎉


## 4.1 `Nx` configuration

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

We are using [`Nx.Serving`](https://hexdocs.pm/nx/Nx.Serving.html),
which simply allows us to encapsulates tasks, 
be it networking, machine learning, data processing or any other task.

In this specific case,
we are using it to **batch requests**.
This is extremely useful and important
because we are using models that typically run on GPU.
The GPU is *really good* at **parallelizing tasks**.
Therefore, instead of sending an image classification request one by one,
we can *batch them*/bundle them together as much as we can
and then send it over.

We can define the `batch_size` and `batch_timeout` with `Nx.Serving`.
We're going to use the default values, 
hence why we're not explicitly defining them.

With `Nx.Serving`, we define a `serving/0` function
that is then used by it, 
which in turn is executed in the supervision tree.

In the `serving/0` function,
we are loading the [`ResNet-50`](https://huggingface.co/microsoft/resnet-50) model
and its featurizer.

> [!NOTE]
>
> A `featurizer` can be seen as a [`Feature Extractor`](https://huggingface.co/docs/transformers/main_classes/feature_extractor).
> It is essentially a component that is responsible for converting input data 
> into a format that can be processed by a pre-trained language model.
>
> It takes raw information and performs various transformations, 
> such as [tokenization](https://neptune.ai/blog/tokenization-in-nlp), 
> [padding](https://www.baeldung.com/cs/deep-neural-networks-padding), 
> and encoding to prepare the data for model training or inference.

Lastly, this function returns
a builds serving for image classification
by calling [`image_classification/3`](https://hexdocs.pm/bumblebee/Bumblebee.Vision.html#image_classification/3),
where we can define our compiler and task batch size.
We've given our serving function the name `ImageClassifier`.


## 4.2 `Async` processing the image for classification

Now we're ready to send the image to the model
and get a prediction of it!

Every time we upload an image, 
we are going to run **async processing**.
This means that the task responsible for image classification
will be created asynchronously,
meaning that the LiveView *won't have to wait* for this task to finish
to continue working.

For this scenario,
we are going to be using the 
[`Task` module](https://hexdocs.pm/elixir/1.14/Task.html)
to spawn processes to complete this task.

Go to `lib/app_web/live/page_live.ex`
and change the following code.

```elixir
  def handle_progress(:image_list, entry, socket) do
    if entry.done? do

      # Consume the entry and get the tensor to feed to classifier
      tensor = consume_uploaded_entry(socket, entry, fn %{} = meta ->
        {:ok, vimage} = Vix.Vips.Image.new_from_file(meta.path)
        pre_process_image(vimage)
      end)

      # Create an async task to classify the image
      task = Task.async(fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)

      # Update socket assigns to show spinner whilst task is running
      {:noreply, assign(socket, running: true, task_ref: task.ref)}
    else
      {:noreply, socket}
    end
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
>
> The `pre_process_image/1` function is yet to be defined.
> We'll do that in the following section.

In the `handle_progress/3` function,
whilst we are consuming the image,
we are first converting it to a 
[`Vix.Vips.Image`](https://hexdocs.pm/vix/Vix.Vips.Image.html) struct.
using the file path.
We then feed this image to the `pre_process_image/1` function that we'll implement later.

What's important is to notice this line:

```elixir
task = Task.async(fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)
```

We are using [`Task.async/1`](https://hexdocs.pm/elixir/1.12/Task.html#async/1)
to call our `Nx.Serving` build function `ImageClassifier` we've defined earlier,
thus initiating a batched run with the image tensor.
While the task is spawned,
we update the socket assigns with the reference to the task (`:task_ref`)
and update the `:running` assign to `true`, 
so we can show a spinner or a loading animation.

When the task is spawned using `Task.async/1`, 
a couple of things happen in the background.
The new process is monitored by the caller (our `LiveView`), 
which means that the caller will receive a `{:DOWN, ref, :process, object, reason}` message once the process it is monitoring dies. 
And, a link is created between both processes.

Therefore, 
we **don't need to use [`Task.await/2`](https://hexdocs.pm/elixir/1.12/Task.html#await/2)**.
Instead, we create a new handelr to receive the aforementioned.
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
meaning no resources are spent on a process from which nobody expects 
the model result anymore. 


### 4.2.1 Considerations regarding `async` processes

When a task is spawned using `Task.async/2`, 
**it is linked to the caller**.
Which means that they're related: if one dies, the other does too.

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


### 4.2.2 Alternative for better testing

We are spawning async tasks by calling `Task.async/1`.
This is creating an ***unsupervised task**.
Although it's plausible for this simple app,
it's best for us to create a 
[**`Supervisor`**](https://hexdocs.pm/elixir/1.15.7/Supervisor.html)
that manages their child tasks.
This way, we have more control over the execution and lifetime of the child classes.

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

We are creating a [`Task.Supervisor`](https://hexdocs.pm/elixir/1.15.7/Supervisor.html)
with the name `App.TaskSupervisor`.

Now, in `lib/app_web/live/page_live.ex`,
we create the async task like so:

```elixir
  task = Task.Supervisor.async(App.TaskSupervisor, fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)
```

We are now using [`Task.Supervisor.async`](https://hexdocs.pm/elixir/1.15.7/Task.Supervisor.html#async/3),
passing the name of the supervisor we've defined earlier.

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
we do that until the *prediction is made*.


## 4.3 Image pre-processing

As we've noted before,
we need to **pre-process the image before feeding it to the model**.
For this, we have three main steps:

- removing the [`alpha` ](https://en.wikipedia.org/wiki/Alpha_compositing) 
out of the image, flattening it out.
- convert the image to `sRGB` [colourspace](https://en.wikipedia.org/wiki/Color_space).
This is needed to ensure that the image is consistent
and aligns with the model's training data images.
- set the representation of the image as tensor
to `height, width, bands`.
The image tensor will then be organized as a three-dimensional array,
where the first dimension represents the height of the image,
the second refers to the width of the image,
and the third pertains to the different 
[spectral bands/channels of the image](https://en.wikipedia.org/wiki/Multispectral_imaging).

Our `pre_processing/3` function will implement these three steps.
Let's go over it now!

In `lib/app_web/live/page_live.ex`,
add this piece of code.

```elixir
  defp pre_process_image(%Vimage{} = image) do

    # If the image has an alpha channel, we flatten the alpha out of the image --------
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
    # If you want to use {width, height, channels/bands},
    # you need format = `[:width, :height, :bands]` and shape = `{y, x, bands}`.
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

The colourspace-altered image is then converted to a [tensor](https://hexdocs.pm/vix/Vix.Tensor.html),
by calling [`write_to_tensor/1`](https://hexdocs.pm/vix/Vix.Vips.Image.html#write_to_tensor/1).

We then [reshape](https://hexdocs.pm/nx/Nx.html#reshape/3) 
the tensor according to the format that was previously mentioned.

This function returns the processed tensor,
that is then used as input to the model.


## 4.4 Updating the view

All that's left is updating the view
to reflect these changes we've made to the `LiveView`.
Head over to `lib/app_web/live/page_live.html.heex`
and change it to this.

```html
<.flash_group flash={@flash} />
<div class="h-full w-full px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
  <div class="flex justify-center items-center mx-auto max-w-xl w-[50vw] lg:mx-0">
    <div class="space-y-12">
      <div class="border-gray-900/10 pb-12">
        <h2 class="text-base font-semibold leading-7 text-gray-900">Image Classification</h2>
        <p class="mt-1 text-sm leading-6 text-gray-600">
            Do simple classification with this <a href="https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html" class="font-mono font-medium text-sky-500">LiveView</a>
            demo, powered by <a href="https://github.com/elixir-nx/bumblebee" class="font-mono font-medium text-sky-500">Bumblebee</a>.
        </p>

        <!-- File upload section -->
        <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
          <div class="col-span-full">
            <div
              class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
              phx-drop-target={@uploads.image_list.ref}
            >
              <div class="text-center">
                <svg class="mx-auto h-12 w-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z" clip-rule="evenodd" />
                </svg>
                <div class="mt-4 flex text-sm leading-6 text-gray-600">
                  <label for="file-upload" class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
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
              </div>
            </div>
          </div>
        </div>

        <!-- Prediction text -->
        <div class="mt-6 flex space-x-1.5 items-center font-bold text-gray-900 text-xl">
            <span>Description: </span>
            <!-- Spinner -->
            <%= if @running do %>
            <div role="status">
                <div class="relative w-6 h-6 animate-spin rounded-full bg-gradient-to-r from-purple-400 via-blue-500 to-red-400 ">
                    <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-gray-200 rounded-full border-2 border-white"></div>
                </div>
            </div>
            <% else %>
                <%= if @label do %>
                <span class="text-gray-700 font-light"><%= @label %></span>
                <% else %>
                <span class="text-gray-300 font-light">Waiting for image input.</span>
                <% end %>
            <% end %>
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


## 4.5 Check it out!

And that's it!
Our app is now *functional* 🎉.

If you run the app, 
you can drag and drop or select an image.
After this, a task will be spawned that will run the model
against the image that was submitted.

After the prediction is made, it's then shown to the person!

<p align="center">
  <img src="https://github.com/dwyl/aws-sdk-mock/assets/17494745/894b988e-4f60-4781-8838-c7fd95e571f0" />
</p>

You can and **should** try other models.
`ResNet-50` is just one of the many that are supported by `Bumblebee`.
You can see the supported models in https://github.com/elixir-nx/bumblebee#model-support.


## 4.6 Considerations on user images

To maintain the app as simple as possible,
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
We can leverage the [`Canvas API` ](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
to decode and downsize this image in the client-side,
reducing server workload.

You can see an example implementation of this technique 
in `Bumblebee`'s repository 
at https://github.com/elixir-nx/bumblebee/blob/main/examples/phoenix/image_classification.exs.


# 5. Final touches

Although our app is functional,
we can make it **better**. 🎨


## 5.1 Setting max file size

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


## 5.2 Show errors

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
  <div class='mt-2'>
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


## 5.3 Show image preview

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

Next, we need to *read the file while consuming it*,
and properly update the socket assign
so we can show it to the person.

In the same file,
change the `handle_progress/3` function to the following.

```elixir
  def handle_progress(:image_list, entry, socket) do
    if entry.done? do

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
    else
      {:noreply, socket}
    end
  end
```

We're using [`File.read!/1`](https://hexdocs.pm/elixir/1.13/File.html#read/1)
to retrieve the binary representation of the image that was uploaded.
We use [`Base.encode64/2`](https://hexdocs.pm/elixir/1.12/Base.html#encode64/2)
to encode this file binary 
and assign the newly created `image_preview_base64` socket assign
with this base64 representation of the image.

Now, all that's left to do
is to *render the image on our view*.
In `lib/app_web/live/page_live.html.heex`,
locate the line:

```html
<div class="text-center">
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
          <img src={@image_preview_base64} />
      </label>
    </form>
  <% else %>
    <svg class="mx-auto h-12 w-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z" clip-rule="evenodd" />
    </svg>
    <div class="mt-4 flex text-sm leading-6 text-gray-600">
      <label for="file-upload" class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
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


# 6. What about other models?

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
|====================================================================================================| 100% (989.82 MB)
[info] TfrtCpuClient created.
|====================================================================================================| 100% (711.39 KB)
[info] Running AppWeb.Endpoint with cowboy 2.10.0 at 127.0.0.1:4000 (http)
[info] Access AppWeb.Endpoint at http://localhost:4000
[watch] build finished, watching for changes...
```

You may think we're done here.
But we are not! ✋

The **destructuring of the output of the model may not be the same**.
If you try to submit a photo,
you'll get this error:

```sh
no match of right hand side value: %{results: [%{text: "a person holding a large blue ball on a beach"}]}
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
>
> Take note that `BLIP`, 
> when compared to `ResNet-50` (for example),
> is a larger model.
> There are more accurate and even larger models out there
> (for example, the [`blip-image-captioning-large`](https://huggingface.co/Salesforce/blip-image-captioning-large) model,
> the larger version of the model we've just used).
> This is a balancing act: the larger the model, the longer a prediction may take
> and more resources your server will need to have to handle this heavier workload.


# _Please_ Star the repo! ⭐️

If you find this package/repo useful, 
please star on GitHub, so that we know! ⭐

Thank you! 🙏