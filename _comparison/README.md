# Benchmark comparison between `Bumblebee` models 

The following table compares `Bumblebee's` image captioning models
that are supported.

Feel free to run `Bumblebee`-supported models
and add them to this table!
At the time of writing,
`Bumblebee` doesn't support a lot of 
image captioning models. 
So any contribution is welcome! 🙏

> [!NOTE]
>
> While `ResNet-5` leans more into image classification
> (it returns a list of prediction keywords/tokens),
> we're adding it to the table for simplicity sake.



| Model                       |   ROUGE-1 |   ROUGE-2 |   ROUGE-L |    BLEU |   METEOR |   Word Error Rate |   Time (s) |   Size (in Mb) |
|:----------------------------|----------:|----------:|----------:|--------:|---------:|------------------:|-----------:|---------------:|
| blip-image-captioning-base  |   0.6     |   0.36364 |   0.57983 | 20.0762 |  0.45953 |           0.58333 |    4.16365 |          990.6 |
| blip-image-captioning-large |   0.59167 |   0.33333 |   0.55844 | 19.0449 |  0.53777 |           0.72381 |   11.878   |         1879.9 |
| resnet-50                   |   0       |   0       |   0       |  0      |  0.03953 |           1       |    0.32517 |          102.6 |


> [!NOTE]
>
> All the values in the table above are the median values of 
> [**50 COCO Dataset images**](https://cocodataset.org/#home)
> with the models being run
> on an Apple M1 Pro with 16GB of memory.

<br>
<br>

----

<br>
<br>

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


# 2. Run `run.exs`

The `run.exs` file is a standalone
[`Elixir` script file ](https://thinkingelixir.com/2019-04-running-an-elixir-file-as-a-script/)
that you can execute to make predictions 
based on any `Bumblebee`-supported model you want.

To run the file,
simply execute the following command:

```sh
elixir run.exs
```

When you run this command, 
a `.csv` file will be created inside `coco_dataset`
with the results of the benchmark of a given model.
This new file will have information of the
**execution time** and the **predicted caption**,
with the file name being `"{model_name}_results.csv"`.

**Every time you run the script, the `.csv` results file is overriden**.

To run this file with different models,
you only have to change a few parameters.
If you open `run.exs`,
inside the `Benchmark` module,
you will find a comment block encompassed with 
`CHANGE YOUR SETTINGS HERE -----------------------------------`.
Inside this code block, 
you can change:

- the **image_width** of the image before being fed into the model.
You want this value to be the same 
*as the same dimensions of the dataset the model was trained on*.
The images will be redimensioned to this value 
whilst maintaining aspect ratio.
This step is important because
it will **yield better results** 
and **improve performance whilst running the script**,
since we're optimizing unnecessary data that the model 
would otherwise ignore.

- the **model** being tested.
If can change:
  - the `title`, which is just a label for the image.
  This title should not have the `/` character or any other that might 
  make it look like a path.
  This is because this `title` is used when creating the results file.
  - the `name` of the model,
  which should coincide with the name of the repo in `HuggingFace`.
  (i.e. [`Salesforce/blip-image-captioning-large`](https://huggingface.co/Salesforce/blip-image-captioning-large)).
  - the `cache_path`, pertaining to the location where the model is downloaded
  and cached locally. 
  You should only change the name of the folder
  (don't change `@models_folder_path`).
  - `load_featurizer`, `load_tokenizer` and `load_generation_config`
  allow you to load these parameters if the model needs it.
  We recommend checking [`Bumblebee's` documentation](https://hexdocs.pm/bumblebee/Bumblebee.Vision.html)
  to check if your model needs any of these.

- the `extract_label` function.
This function pattern-matches the output of the model.
You should change it according to the output of the model
so you can successfully retrieve the result.

And these are all the changes you need!
You can change these settings for each model you test
and a new file with the results will be created for each one
inside `coco_dataset`!


## 2.1 Benchmarking different models (important!)

When you make the above changes, 
we are assuming that
you are using the 
[`Bumblebee.Vision.image_to_text/5`](https://hexdocs.pm/bumblebee/Bumblebee.Vision.html#image_to_text/5)
function to create the serving.

The default code for the script pertains to 
[`Salesforce/blip-image-captioning-base`](https://huggingface.co/Salesforce/blip-image-captioning-base).
However, there are other models that `Bumblebee` might support
from the Hugging Face repositories in https://huggingface.co/models?pipeline_tag=image-to-text&sort=downloads.

Some models are not served from 
[`Bumblebee.Vision.image_to_text/5`](https://hexdocs.pm/bumblebee/Bumblebee.Vision.html#image_to_text/5).
If you want to benchmark others 
(as long as they are supported from `Bumblebee`),
you'll have to make additional changes.


### 2.1.1 `ResNet-50`

For example, if you want to test the `resnet-50` model,
you also have to change the `serving/0` function 
inside `manage_models.exs`
so it uses [`Bumblebee.Vision.image_classification/3`](https://hexdocs.pm/bumblebee/Bumblebee.Vision.html#image_classification/3)
instead (the only way to correctly build the `resnet-50` model serving with `Bumblebee`).

```elixir
    Bumblebee.Vision.image_classification(
    model.model_info,
    model.featurizer,
    top_k: 1,
    compile: [batch_size: 10],
    defn_options: [compiler: EXLA],
    preallocate_params: true
  )
```

### 2.1.2 `Salesforce/blip-image-captioning-large`

Normally, for `BLIP` models, 
you would only have to change the settings that were mentioned
in the previous section.

However, **at the time of writing**,
this would result in an error if you wanted to
use [`Salesforce/blip-image-captioning-large`](https://huggingface.co/Salesforce/blip-image-captioning-large).
The bug, although fixed, has not yet been released.

Therefore, for this model,
you'd have to update the imports in `run.exs`.

```elixir
  {:bumblebee, git: "https://github.com/elixir-nx/bumblebee", branch: "main", override: true},
  {:nx, git: "https://github.com/elixir-nx/nx.git", sparse: "nx", override: true},
  {:exla, git: "https://github.com/elixir-nx/nx.git", sparse: "exla", override: true},
```


For more information on this,
check https://github.com/elixir-nx/bumblebee/issues/269#issuecomment-1865198005.




# 3. Run `metrics.ipynb` 

Now that you have the `{model_name}_results.csv` 
generated by the above `Elixir` script,
you can now run `metrics.ipynb`.

This `Jupyter Notebook` will wrangle the data, 
process it 
and create the table with the metrics
to evaluate each model that was benchmarked.

The `Jupyter Notebook` is documented with each step.












