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


# _Please_ Star the repo! ⭐️

If you find this package/repo useful, 
please star on GitHub, so that we know! ⭐

Thank you! 🙏