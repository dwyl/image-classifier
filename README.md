<div align="center">

# Image classifier in `Elixir`

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/dwyl/image-classifier/ci.yml?label=build&style=flat-square&branch=main)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/image-classifier/main.svg?style=flat-square)](https://codecov.io/github/dwyl/image-classifier?branch=main)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/image-classifier/issues)
[![HitCount](https://hits.dwyl.com/dwyl/image-classifier.svg?style=flat-square&show=unique)](https://hits.dwyl.com/dwyl/image-classifier)

Classify your images using 
machine learning models
within `Phoenix`!

</div>

<br />

- [Image classifier in `Elixir`](#image-classifier-in-elixir)
- [Why? 🤷](#why-)
- [What? 💭](#what-)
- [Who? 👤](#who-)
- [How? 💻](#how-)
  - [Prerequisites](#prerequisites)
  - [0. Creating a fresh `Phoenix` project](#0-creating-a-fresh-phoenix-project)
  - [1. Installing initial dependencies](#1-installing-initial-dependencies)
  - [2. Adding `LiveView` capabilities to our project](#2-adding-liveview-capabilities-to-our-project)
  - [3. Receiving image files](#3-receiving-image-files)
- [_Please_ Star the repo! ⭐️](#please-star-the-repo-️)


<br />

# Why? 🤷

Building our 
[app](https://github.com/dwyl/app),
we consider `images` an _essential_ 
medium of communication.

By adding a way of classifying images,
we make it *easy* for people
to suggest meta tags to describe images
so they become **searchable**.


# What? 💭

This run-through will create a simple
`Phoenix` web application
that will allow you to choose/drag an image
and classify the image.


# Who? 👤

This tutorial is aimed at `Phoenix` beginners 
that want to grasp how to do image classifying
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
{:exla, "~> 0.6.1"}
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
<div class="px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
  <div class="mx-auto max-w-xl w-[50vw] lg:mx-0">
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
                  <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 10MB</p>
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
<div class="px-4 py-10 flex justify-center sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
  <div class="mx-auto max-w-xl w-[50vw] lg:mx-0">
    <div class="space-y-12">
      <div class="border-gray-900/10 pb-12">
        <h2 class="text-base font-semibold leading-7 text-gray-900">Image Upload</h2>
        <p class="mt-1 text-sm leading-6 text-gray-600">Drag your images and they'll be uploaded to the cloud! ☁️</p>
        <p class="mt-1 text-sm leading-6 text-gray-600">You may add up to <%= @uploads.image_list.max_entries %> exhibits at a time.</p>

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
                <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 10MB</p>
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
     |> assign(:uploaded_files, [])
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
we are creating a list of uploaded images and assigning it to the socket
`uploaded_files`.
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
However, if you print the `uploaded_file`

# _Please_ Star the repo! ⭐️

If you find this package/repo useful, 
please star on GitHub, so that we know! ⭐

Thank you! 🙏