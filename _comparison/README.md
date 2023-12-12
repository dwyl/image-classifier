# Benchmark comparison between `Bumblebee` models 

In this guide, 
we will walk you through on benchmarking
some image captioning models 
that `Bumblebee` offers.

If you've followed the repo's guide, 
you'll probably have an idea that some models work better than others.
In this guide, we'll provide a more *heuristic* representation of this,
and help you create performance metrics on some of these models.

For this, we'll be using 
the [**COCO Dataset**](https://cocodataset.org/#home),
one of the largest open-source object detection, segmentation
and captioning dataset,
widely used for training, evaluating and testing models.
We'll be using these captioned images 
to compare the yielded results of the `Bumblebee` models
in `Elixir` 
and perform some metric evaluation.


> [!NOTE]
>
> In the `coco_dataset` folder,
> we've already retrieved 50 random images and their respective captions.
> However, we'll guide you through getting these your own
> if you want different images.


# A quick overview of the contents of this folder

You may be overwhelmed with the files that are in this folder.
But don't be! 
We'll explain what each one does.

- the `run.exs` and `manage_models.exs`
are `Elixir` files that we'll use **to run our machine learning models**.
The models are cached in the `models` folder.
- the `coco_download.ipynb` file is a `Jupyter Notebook` file
that **will allow you to download images from the [COCO Dataset](https://cocodataset.org/#home)**.
You don't need to run this file because
we've already downloaded 50 images and their captions
for you beforehand -
these images are located in the `coco_dataset` folder.
However, if you *do want* to run this file,
you need the `annotations` folder.
This folder simply stores information of the captions
of the images from the dataset,
so you don't need to worry about it 🙂.


## 0. Prerequisites 

Before starting, we need to set up our dev environment.
We are going to:

- execute the models **in `Elixir`**.
- perform metric evaluation **in `Python`**.

We're assuming you already have the `Elixir` environment set up
after implementing the application.
So we'll focus on getting the `Python` env set up 😃.

First, install [**`Anaconda`**](https://www.anaconda.com/download).
This program will allow us to create *virtual environments*
in `Python`, each one being contained with their own dependencies.
We will run our `Python` scripts 
(we'll use [`Jupyter Notebooks`](https://jupyter.org/), 
so it's preferred you install it or use `Visual Studio Code` 
to work with these)
inside these environments.

After installing `Anaconda`,
we'll be able to run `conda` command in our terminal! 🎉


## 0.1 Create a virtual environment 

Let's create our virtual env.
In your terminal, run:

```sh
conda create -n <name_of_env> --file requirements.txt
```

In `<name_of_env>`, write any name you want.
In our case, we'll type `comparison`.
The `--file` argument allows us to pass a `requirements.txt` file
with a list of dependencies to install.
We've provided this file inside [this folder](./requirements.txt).

Install the needed dependencies when prompted 
by typing `Y`. 
After this, the env will be created.

To *enter the env*, type:

```sh
conda activate comparison
```

After this, 
you'll have entered in your newly created virtual env
and now you can run commands within it!
Every `Python` dependency you install 
will be made available **only in this virtual env**,
not outside.


## 0.2 Running `Jupyter Notebooks` inside virtual env

If you've installed `Jupyter Notebooks`,
as long as you run it inside this virtual environment through the terminal,
all its dependencies will be available inside the notebook.

If you are using `Visual Studio Code`,
when opening a file `.ipynb` (a `Jupyter Notebook` file),
you will be able to choose the virtual env on the right side.
You can choose the one you've created
(in the following image,
we've named our env `"cocodataset"`).

<p align="center">
  <img src="https://github.com/dwyl/image-classifier/assets/17494745/afcf2e39-d7af-48f5-9110-70a8b585a6f1">
</p>

And that's it!
You're ready to execute `Python` inside `Juypter Notebooks`
to perform some metric evaluation!

Let's kick this off! 🏃‍♂️


## 1. *(Optional)* Downloading the COCO dataset images

> [!NOTE]
>
> This section is entirely optional.
> We've already provided images and captions
> from the **COCO dataset** inside the `coco_dataset` folder.
>
> This chapter is only relevant to those
> that want to experiment with *other* images.

The COCO dataset can be accessed through
[`cocoapi`](https://github.com/cocodataset/cocoapi).
However, to get the images with their respective captions
you have to put in some work.

This process is a bit convoluted.
In fact, you'd have to download the original
`cocoapi` repo,
create folders with the images and annotations
and then run `make` to install the packages needed 
(more information on https://github.com/sliao-mi-luku/Image-Captioning#dataset).

With this is mind, 
we've **simplified this process** and
provided [`coco_download.ipynb`](./coco_download.ipynb)
so you can fetch a random image and caption
and download 50 different random images, 
if you want.

Each executable block is documented,
so you know what it does exactly.
Don't forget: to use this, you will need to 
**run the notebook in the environment you've created**,
since it has all the dependencies needed to run the notebook.

> [!TIP]
>
> We are using the dataset from 2014 because
> it provides a good variety of images.
> However, if you want to experiment with 
> their other datasets,
> you may do so in  https://cocodataset.org/#download.
> 
> As long as you're choosing a dataset that has caption annotations,
> our `Jupyter Notebook` will work.





