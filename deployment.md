<div align="center">

# Deploying a `Bumblebee` app to `Fly.io`

</div>

Now that our `Bumblebee` app is working,
it's time to **deploy it**,
so everyone can see it!

Although you can check this repo's code yourself
to aid your own app deployment,
this small guide will explain some details
that you ought to take into account 
when shipping your `Bumblebee` app to production.

Let's start 🏃‍♂️.

- [Deploying a `Bumblebee` app to `Fly.io`](#deploying-a-bumblebee-app-to-flyio)
- [Considerations before you deploy](#considerations-before-you-deploy)
  - [1. Initializing `fly.io`-related files](#1-initializing-flyio-related-files)
  - [2. Changing config files](#2-changing-config-files)
    - [2.1 `Dockerfile`](#21-dockerfile)
      - [2.1.1 Installing `wget` so `ESLA` can be properly downloaded](#211-installing-wget-so-esla-can-be-properly-downloaded)
      - [2.1.2 Setting the local directory where `Bumblebee` models will load from](#212-setting-the-local-directory-where-bumblebee-models-will-load-from)
    - [2.2 Changing `EXLA` settings](#22-changing-exla-settings)
  - [3. Deploy again!](#3-deploy-again)
  - [4. Adding volumes to our machine instances](#4-adding-volumes-to-our-machine-instances)
    - [4.1 Deleting existing instances](#41-deleting-existing-instances)
    - [4.2 Create brand new instances with volumes](#42-create-brand-new-instances-with-volumes)
    - [4.3 Confirm that the volume is attached to the machine](#43-confirm-that-the-volume-is-attached-to-the-machine)
    - [4.4 Extending the size of the volume](#44-extending-the-size-of-the-volume)
    - [4.5 Running the application and checking new volume size and its usage](#45-running-the-application-and-checking-new-volume-size-and-its-usage)
  - [5. Forcing re-download](#5-forcing-re-download)
- [Scaling up `fly` machines](#scaling-up-fly-machines)
  - [1. Creating another `machine` and `volume` pair](#1-creating-another-machine-and-volume-pair)
  - [2. Scaling machine `CPU` and `RAM`](#2-scaling-machine-cpu-and-ram)


# Considerations before you deploy

When you run your app on `localhost`, 
you'll see that the model data is downloaded
directly from [HuggingFace](https://huggingface.co/)
the first time the application starts.
 
To avoid downloading the model data during deployments,
we have two options:

- **Explicit local versioning**: 
you download the model from HuggingFace
and use it in your repository locally.
After this, you just need to change how you load the model differently.
Instead of `Bumblebee.load_xyz({:hf, "microsoft/resnet"})`, you do
`Bumblebee.load_xyz({:local, "/path/to/model"})`.

- **Cache models from `HuggingFace`**: 
`Bumblebee` can download and cache data from `HuggingFace` repos.
We can control the cache directory
by setting the `BUMBLEBEE_CACHE_DIR` env variable.
We can *set it* 
and `Bumblebee` will look for it in the set directory.

> [!NOTE]
> `Bumblebee` also recommends you set the `BUMBLEBEE_OFFLINE`
> to `true` in the final image,
> to make sure all the models are always loaded from the cache.
>
> See: 
> https://github.com/elixir-nx/bumblebee/tree/main/examples/phoenix#2-cached-from-hugging-face.

We're going to follow the *second option*.


## 1. Initializing `fly.io`-related files

If you haven't installed the `flyctl`,
install it.
Follow the instructions at 
[fly.io/docs/elixir/getting-started](https://fly.io/docs/elixir/getting-started) <br />
This command is needed to deploy our `Phoenix` application
to `fly.io`.

After this,
in the root of your directory,
you run `fly launch`.
The command will ask you for information incrementally.
Answer each question and at the end,
the deploy should be complete.

```sh
Creating app in /Users/me/hello_elixir
Scanning source code
Detected a Phoenix app
? App Name (leave blank to use an auto-generated name): hello_elixir
? Select organization: flyio (flyio)
? Select region: mad (Madrid, Spain)
Created app hello_elixir in organization soupedup
Set secrets on hello_elixir: SECRET_KEY_BASE
Installing dependencies
Running Docker release generator
Wrote config file fly.toml
? Would you like to setup a Postgres database now? Yes
Postgres cluster hello_elixir-db created
  Username:    postgres
  Password:    <password>
  Hostname:    hello_elixir-db.internal
  Proxy Port:  5432
  PG Port: 5433
Save your credentials in a secure place, you will not be able to see them again!

Monitoring Deployment

1 desired, 1 placed, 1 healthy, 0 unhealthy [health checks: 2 total, 2 passing]
--> v0 deployed successfully

Connect to postgres
Any app within the flyio organization can connect to postgres using the above credentials and the hostname "hello_elixir-db.internal."
For example: postgres://postgres:password@hello_elixir-db.internal:5432

See the postgres docs for more information on next steps, managing postgres, connecting from outside fly:  https://fly.io/docs/reference/postgres/
Postgres cluster hello_elixir-db is now attached to hello_elixir

Would you like to deploy now? Yes
Deploying hello_elixir

==> Validating app configuration
--> Validating app configuration done
Services
TCP 80/443 ⇢ 8080
Remote builder fly-builder-little-glitter-8329 ready
...
```

> [!NOTE]
> The command will ask you to choose 
> which server resources you want your app to run in.
> If you run large models, you probably will have to scale up
> so the instance doesn't run out of memory whilst executing
> and/or downloading on startup.
>
> This is why we recommend starting out with a `ResNet-50` model,
> because it is highly lightweight.


> [!WARNING]
> Your deployment may have failed.
> Don't worry, this is normal. 
> This is because we haven't configured some files
> so `Bumblebee` is properly supported 
> for the app's execution on `fly.io`.


## 2. Changing config files

After the command has executed,
you may have realized a few files have been created:

- a [`fly.toml`](https://fly.io/docs/reference/configuration/) file.
- a [`Dockerfile`](https://docs.docker.com/engine/reference/builder/).
- a `.dockerignore` file.
- a directory called `rel` with scripts for server execution.

You may have run into some errors while trying to deploy.
Don't worry, that's normal.
We need to make a few changes to our application files
and to the `Dockerfile` 
so the `Docker` instance on `fly.io` has everything
it needs to have to run our `Phoenix + Bumblebee` application.

To proceed, 
you need to create a directory where your models will load from.
In our case,
it's the `.bumblebee` directory
(you can inclusively find it in this repo 😊).

Let's start!

### 2.1 `Dockerfile`

Let's make some changes to the `Dockerfile`.
This is the bulk of the changes we need to make,
so let's go over them.


#### 2.1.1 Installing `wget` so `ESLA` can be properly downloaded

Chances are you ran into this error 
while running `fly launch`.

```
#0 22.93 could not compile dependency :exla, "mix compile" failed. Errors may have been logged above. 
  You can recompile this dependency with "mix deps.compile exla --force", 
  update it with "mix deps.update exla" or clean it with "mix deps.clean exla"
#0 22.93 ** (RuntimeError) expected either curl or wget to be available in your system, but neither was found
```

This means `wget` or `curl` wasn't found in the `Docker` instance,
which are needed for the `ESLA` dependency.
In the `Dockerfile`,
find the following line:

```dockerfile
# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*
```

Change it to the following:

```dockerfile
# install build dependencies (and curl for EXLA)
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*
```


#### 2.1.2 Setting the local directory where `Bumblebee` models will load from

As mentioned earlier, 
we are going to set the 
`BUMBLEBEE_CACHE_DIR` so `Bumblebee` loads the models
from a local directory.

We are going to change the 
`Dockerfile` to reflect these changes.
We want to:

- set the `BUMBLEBEE_CACHE_DIR` env variable.
- copy the `.bumblebee` directory (or any other name you defined)
into the `Docker` instance.

We want to **download the model during the build stage of the `Dockerfile`**.
This is because we want to make our `fly.io` instance
*sleep after one hour of inactivity* to save resources/reduce costs.
In order to not make the app re-download the model,
we want to **preemptively download it**
and make the application fetch the model locally.
This is why we set the `BUMBLEBEE_CACHE_DIR` directory.

To force the application to fetch the model locally,
we can either set the `BUMBLEBEE_OFFLINE` to `true`
**only after the model has been downloaded**
or do it [programmatically](https://hexdocs.pm/bumblebee/Bumblebee.html#t:repository/0).
By forcing this env variable to `true`,
this will force `Bumblebee` to look for the model locally 
(it disables any outgoing traffic connections,
so it doesn't download any model from the web).

> [!NOTE]
>
> You may have seen there's an option
> to load the model locally
> when calling [`load_model/2`](https://hexdocs.pm/bumblebee/Bumblebee.html#t:repository/0).
>
> However, there's a distinction to be made.
> **`:local` should only be used when you've downloaded the model *yourself* and placed it on your repository manually**.
>
> The files that are downloaded when you use `:hf` 
> **are not the same as downloading the model from HuggingFace's repo**.
>
> This is why we'll continue to use `:hf`.
> By setting `BUMBLEBEE_OFFLINE` to `true`, 
> it will load the files locally 
> that were previously downloaded during the building stage.

Therefore, change the `Dockerfile` so it looks like this.

```dockerfile
# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20231009-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.15.7-erlang-26.0.2-debian-bullseye-20231009-slim
#
ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26.0.2
ARG DEBIAN_VERSION=bullseye-20231009-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies (and curl for EXLA)
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"
ENV BUMBLEBEE_CACHE_DIR="/app/.bumblebee/"


# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

COPY .bumblebee/ .bumblebee

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/app /app
COPY --from=builder --chown=nobody:root /app/.bumblebee/ /app/.bumblebee

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]

# Set the runtime ENV
ENV ECTO_IPV6="true"
ENV ERL_AFLAGS="-proto_dist inet6_tcp"
ENV BUMBLEBEE_CACHE_DIR="/app/.bumblebee/"


CMD ["/app/bin/server"]
```


As you can see,
this `Dockerfile` focuses on bundling the application
and creating the `/app/.bumblebee` directory
wherein the models will be downloaded into.

In order to download the models
so they can later be reused
whenever the app is restarted
without downloading the model again,
we need to make a couple of changes to `lib/app/application.ex`.

```elixir
defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    # Checking if the models have been downloaded
    models_folder_path = Path.join(System.get_env("BUMBLEBEE_CACHE_DIR"), "huggingface")
    if not File.exists?(models_folder_path) or File.ls!(models_folder_path) == [] do
      load_models()
    end


    children = [
      # Start the Telemetry supervisor
      AppWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Nx serving for image classifier
      {Nx.Serving, serving: serving(), name: ImageClassifier},
      # Adding a supervisor
      {Task.Supervisor, name: App.TaskSupervisor},
      # Start the Endpoint (http/https)
      AppWeb.Endpoint
      # Start a worker by calling: App.Worker.start_link(arg)
      # {App.Worker, arg}
    ]

    # Check if the models have been downloaded

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def load_models do
    # ResNet-50 -----
    {:ok, _} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
    {:ok, _} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})
  end

  def serving do
    # ResNet-50 -----
    {:ok, model_info} = Bumblebee.load_model({:hf, "microsoft/resnet-50", offline: true})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50", offline: true})

    Bumblebee.Vision.image_classification(model_info, featurizer,
      top_k: 1,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],
      preallocate_params: true        # needed to run on `Fly.io`
    )

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

Inside `load_models/0`, 
we are fetching all the models that are needed in the application.
This will download the models into our `BUMBLEBEE_CACHE_DIR`
on application startup.
The model will only be downloaded when no models are found.
Therefore, only the first boot will be affected.
Subsequent ones won't.

Our `serving/0` function now fetches the models locally,
because we're passing the `:offline` option 
and setting it to `true`.


### 2.2 Changing `EXLA` settings

`Bumblebee` recommends using `EXLA` to compile the numerical computations.
That's what we have used to do those.

`EXLA` allows only a single computation per device to run at the same time, 
so if a GPU is available,
we want it to only run large computations like one of the neural network models.

In order to do this,
we can configure our default backend to use the CPU by default
*and then*  pass the `:compile` and `defn_options: [compiler: EXLA]`
when creating the serving.
This guarantees we're optimally using the GPU to run neural network models
and using the CPU for one-off operations used in data processing for the model.

Head over to `lib/app/application.ex`,
to the `serving/0` function we've created 
and make sure these options are passed into the model that the function returns.

```elixir
    Bumblebee.Vision.image_classification(model_info, featurizer,
      top_k: 1,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],   # make sure `:compiler` is set to `EXLA`
      preallocate_params: true          # makes sure the parameters of the model are loaded to the GPU and not CPU (since we're setting it to default)
    )
```

Make sure to define `preallocate_params` to `true`.
This ensures that the parameters are loaded to the same device
as the GPU.
Because we are going to default to run one-off operations into the CPU,
we need to set this property to `true`.

> [!NOTE]
>
> If you want to learn which combination of settings 
> is ideal for each scenario, 
> there are a couple combinations of options related to parameters, 
> trading off memory usage for speed:
> 
> `defn_options: [compiler: EXLA], preallocate_params: true` - 
> move and keep all parameters to the GPU upfront. 
> This requires the most memory, but should provide the fastest inference time.
> 
> `defn_options: [compiler: EXLA]` - 
> copy all parameters to the GPU before each computation and discard afterwards. 
> This requires less memory, but the copying increases the inference time.
> 
> `defn_options: [compiler: EXLA, lazy_transfers: :always]` - 
> lazily copy parameters to the GPU during the computation as needed. 
> This requires the least memory, at the cost of inference time.

Now, let's make our one-off operations device the CPU as default!
Luckily for us,
we just need to change our `EXLA` configuration line
in the `lib/config/application.ex`.

Change it to the following:

```elixir
config :nx, :default_backend, {EXLA.Backend, client: :host} 
```

We set the `client` parameter
to `:host` in order 
**for one-off operations to run on the CPU.**
which ensures that initially we load the parameters onto CPU. 
Again,
this is important, 
because as the parameters are loaded `Bumblebee` may need to apply certain operations to them 
and we don't want to bother the GPU at that point, 
risking an out-of-memory error.

And that's it!

For more information about all of this,
check the `Bumblebee` repo
at https://github.com/elixir-nx/bumblebee/tree/main/examples/phoenix#configuring-nx.



## 3. Deploy again!

Now that we've made the needed changes,
we can deploy the application again!

You should run `fly launch`
and re-use the same configuration
(we've already run `fly launch` prior,
so the configuration files are there already).

If you walk through the steps,
the deployment should run smoothly
and your site should be up and running.

Great job! 
Give yourself a pat on the back! 👏


## 4. Adding volumes to our machine instances

We're now downloading the models on the first bootup
into the path that we've defined in `BUMBLEBEE_CACHE_DIR`
(we've personally set this to `/app/.bumblebee`).

Because we want to persist these models in-between sessions
(and because [according to `fly.io`](https://fly.io/docs/reference/volumes/), 
"a machine's file system gets rebuilt from scratch every time we deploy our app/
is restarted"),
we ought to use **volumes**
so we can place our models there to be persisted.

Now we have two options:

- if we have machines runnings,
we probably have *two instances*,
as this is the default of `fly.io`.
If you wish to keep the same instances,
you can follow https://fly.io/docs/apps/volume-storage/#add-volumes-to-an-existing-app
to add a volume to the existing instances.

- delete and create instances with volumes right off the bat.
We'll use this approach because it's simpler
and will show you how to create instances from the get-go.


### 4.1 Deleting existing instances

Before creating new instances, let's delete our current ones.

Type `fly status` on your terminal.
You should see something like this:

```sh
App
  Name     = XXX                                        
  Owner    = XXXXX                              
  Hostname = xxx.fly.dev                                
  Image    = xxxx:deployment-0O8U12JNDASOIU0H192YZXDH  
  Platform = machines                                     

Machines
PROCESS ID              VERSION REGION  STATE   ROLE    CHECKS  LAST UPDATED         
app     1857705f701e08  16      mad     started                 2023-11-14T22:03:22Z
app     683d529c575228  16      mad     started                 2023-11-14T22:03:31Z
```

Let's delete both of these instances.
Type:

```sh
fly m destroy <ID> --force  
```

Do this for both instances.
If you run `fly status` now,
you should not see any more instances.

Let's also make sure we don't have any volumes.
Run `fly volumes list` 
and make sure if you don't have any volumes.


### 4.2 Create brand new instances with volumes

Awesome! 
Now let's create some new shiny instances!

Head over to `fly.toml`
and add the following text to it.

```toml
[mounts]
  source="models"
  destination="/app/.bumblebee"
```

- **`source`** pertains to the *name of the volume*.
You can name it whatever you want.
- **`destination`** is the destination path of the volume 
inside the `fly.io` instance.
In this case,
we want it to be the same as the one defined in 
`BUMBLEBEE_CACHE_DIR`, 
as it is the path we wish to persist.

Now let's deploy the app!

Run `fly deploy`.


### 4.3 Confirm that the volume is attached to the machine

To check our machines and volumes,
let's run:

```sh
fly machine list
```

It should yield something like so.

```
ID                 NAME                    STATE   REGION  IMAGE                                           IP ADDRESS                      VOLUME                  CREATED                 LAST UPDATED            APP PLATFORM    PROCESS GROUP   SIZE                
ID_OF_THE_MACHINE  dark-shadow-9681        started mad     XXXXX:deployment-01HF7YHSWEN8C3VTMSPYBMWRQB     IP_ADDRESS                      vol_24odk25k51wmn9xr    2023-11-14T22:17:20Z    2023-11-14T22:17:42Z    v2              app             shared-cpu-1x:256MB
```

As we can see, 
a volume with ID `vol_24odk25k51wmn9xr`
has been created and attached to the machine.

You can see the volume 
if you list `fly volumes list`.

```
ID                      STATE   NAME    SIZE    REGION  ZONE    ENCRYPTED       ATTACHED VM     CREATED AT    
vol_24odk25k51wmn9xr    created models  1GB     mad     20a7    true            d891394fee9318  4 minutes ago
```

Awesome!


### 4.4 Extending the size of the volume

We want our volume to comfortably accommodate our models.
Depending on the model *you choose*,
you may need a bigger or smaller volume size.

`fly.io` offers up to 
`3GB` of free volume space.
You can see the pricing in https://fly.io/docs/about/pricing/#persistent-storage-volumes.

Let's [extend our volume](https://fly.io/docs/apps/volume-manage/#extend-a-volume) 
to from `1GB` to `3GB`!

For this, simply run the following command.

```sh
fly vol extend <volume id> -s <new size in GB>
```

And you're sorted! 🎉

You will need to restart the instance for the changes
to take effect.


### 4.5 Running the application and checking new volume size and its usage

Now let's see our handiwork in action!
Start your application
(you do this by visiting the URL of your application,
it will boot up the instance).

After it's up and running,
we can **access it through an `SSH` connection**.

First, let's see the new volume size in the machine's file system.
Run `fly ssh console -s -C df`.
You will see something like so:

```
Filesystem     1K-blocks    Used Available Use% Mounted on
devtmpfs           98380       0     98380   0% /dev
/dev/vda         8154588 1130176   6588600  15% /
shm               111340       0    111340   0% /dev/shm
tmpfs             111340       0    111340   0% /sys/fs/cgroup
/dev/vdb         3061336  100284   2809836   4% /app/.bumblebee
```

As you can see, our `/app/.bumblebee` storage volume
has roughly `3GB` available.
`1GB` is being used by the models that have been downloaded
when we initiated our machine instance.

Oh, you don't believe it?
Let's check the files ourselves! 🔍

Let's connect to the machine instance.
Run `fly ssh console`.

After running the command,
you'll be able to execute commands inside the machine instance!
Run `ls -a` to see the directories.

```sh
root@f2453124fee9318:/app# ls -a
```

The terminal should yield the list of directories under `/app`.

```
.  ..  bin  .bumblebee  erts-14.0.2  lib  releases
```

There's `.bumblebee`!
If you run `ls .bumblebee/huggingface/`,
you'll see the models that have been downloaded
when the application first initiated!

```sh
root@d891394fee9318:/app# ls .bumblebee/huggingface/
45jmafnchxcbm43dsoretzry4i.eiztamryhfrtsnzzgjstmnrymq3tgyzzheytqmrzmm4dqnbshe3tozjsmi4tanjthera                                        7p34k3zbgum6n3sspclx3dv3aq.json
45jmafnchxcbm43dsoretzry4i.json                                                                                                        7p34k3zbgum6n3sspclx3dv3aq.k4xsenbtguwtmuclmfdgum3enjuwosljkrbuc42govrhcudqlbde6ujc
6scgvbvxgc6kagvthh26fzl53a.ejtgmobrgyzwcmjtgiztgmztgezdmnzqgzsdmnbzmnstom3fmnsdontfgq2wimrugfrdimtegyzdgzdfme3ggnzsgm3dsmddmftgkmbxei  sw75gnfcnl7bhl6e5urvb65r6i.ei4wcnbwmnrwcobrgeztqy3fgq4tanrzmq3dgzrwha4gczjvg42taobygjsgmmbxmura
6scgvbvxgc6kagvthh26fzl53a.json                                                                                                        sw75gnfcnl7bhl6e5urvb65r6i.json
```

Hurray! 🥳

Now we know our models are being correctly downloaded
and persisted to a volume.
So we know we won't lose this data in-between app restarts!


## 5. Forcing re-download

Sometimes we make change to the code 
and we want to use other models.
As it stands, if the models cache directory is populated,
it won't download any new models.

We can allow the person to **force re-downloading the models**.
While we're at it, 
we can move all of this logic to a different module so it's easier for us to manage it!

Let's do it!

In `lib/app`, create a file called `models.ex`.

```elixir
defmodule App.Models do
  @moduledoc """
  Manages loading the modules and their location according to env.
  """
  require Logger

  # IMPORTANT: This should be the same directory as defined in the `Dockerfile`.
  @models_folder_path Path.join(
                        System.get_env("BUMBLEBEE_CACHE_DIR") ||
                          Application.compile_env!(:app, :models_cache_dir),
                        "huggingface"
                      )

  @doc """
  Verifies if downloaded models folder is populated or not.
  We re-download the models if:
  - the directory is empty.
  - `force_download` in `config.ex` is set to `true`.
  - we're in a testing environment

  If it is not populated, downloads the models according to env.
  If it is populated, does nothing.
  """
  def verify_and_download_models() do
    # If `force_models_download` is enabled, we delete the files in the folder.
    force_download =
      case Application.fetch_env(:app, :force_models_download) do
        {:ok, true} ->
          Logger.info("Deleting models...")
          File.rm_rf!(@models_folder_path)
          true

        _ ->
          false
      end

    # Re-download the models
    if not File.exists?(@models_folder_path) or File.ls!(@models_folder_path) == [] or
         force_download == true or Mix.env() == :test do
      Logger.info(
        "The downloaded models folder is empty or does not exist. Downloading the models..."
      )

      case Mix.env() do
        :test ->
          download_models_test()

        _ ->
          dbg("wtf")
          download_models()
      end
    end
  end

  @doc """
  Serving function that serves the `Bumblebee` models used throughout the app.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def serving do
    # ResNet-50 -----
    {:ok, model_info} = Bumblebee.load_model({:hf, "microsoft/resnet-50", offline: true})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50", offline: true})

    Bumblebee.Vision.image_classification(model_info, featurizer,
      top_k: 1,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],
      # needed to run on `Fly.io`
      preallocate_params: true
    )
  end

  @doc """
  Serving function for tests only.
  Downloads `ResNet-50`, since it's lightweight.
  """
  def serving_test do
    # ResNet-50 -----
    {:ok, model_info} = Bumblebee.load_model({:hf, "microsoft/resnet-50", offline: true})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50", offline: true})

    Bumblebee.Vision.image_classification(model_info, featurizer,
      top_k: 1,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],
      # needed to run on `Fly.io`
      preallocate_params: true
    )
  end

  # Downloads the models for the test environment.
  # Downloads `ResNet-50`, which is fairly lightweight
  # (if you change the model, make sure to change `handle_info/3` in `page_live.ex`
  # so extracting the output from the model works properly with the one you've chosen).
  defp download_models_test do
    # ResNet-50 -----
    {:ok, _} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
    {:ok, _} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})
  end

  # Downloads the models used in the production environment.
  # They must download the same models that are used in the `serving/0` function for this to work.
  defp download_models do
    # ResNet-50 -----
    {:ok, _} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
    {:ok, _} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})
  end
end
```

There's a lot to unpack here!

- we've created a module constant called **`@models_folder_path`**,
pertaining to the path where the models will be downloaded to.
This path is the same as the one defined in `BUMBLEBEE_CACHE_DIR`,
with `huggingface` appended to it.
Optionally, you can define a configuration variable in `config/test.exs`
to define the location where the tests will be downloaded during tests.

```elixir
config :app,
  models_cache_dir: ".bumblebee"
```

- **`verify_and_download_models/0`**, as the name entails,
checks if the model cache directory is empty or not.
If it's empty, it downloads the models 
by calling `download_models_test/0` (if it's a `:test` env)
or by calling `download_models_prod/0` (if it's not a `:test` env).

We can override this behaviour by setting `force_models_download`
in `config/config.ex`.
This will download the models regardless.

```elixir
# App configuration (general)
config :app,
  force_models_download: true
```

- the **`serving/0`** function is the same as the one found in `application.ex`.
We've just created one for a `production` env 
and another for `test` env.
Think of `serving` and `load_models` as pairs.
You have a `serving/0` and `load_models/0` pair
(pertaining to production env)
and `serving_test/0` and `load_models_test/0`
(pertaining to testing env).

This is done like so testing can use a lightweight model
to execute much faster.

> [!WARNING]
>
> Don't forget that if you are using different model for production,
> you will probably need to change how the output of the model is destructured.
>
> Inside `lib/app_web/live/page_live.ex`,
> you can change the `handle_info/3` to something like so:
>
> ```elixir
>   def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket) do
>   # This is called everytime an Async Task is created.
>   # We flush it here.
>   Process.demonitor(ref, [:flush])
>
>   # And then destructure the result from the classifier.
>   # (when testing, we are using `ResNet-50` because it's lightweight.
>   # You need to change how you destructure the output of the model depending
>   # on the model you've chosen for `prod` and `test` envs on `models.ex`.)
>   label =
>     case Mix.env() do
>       :test ->
>         %{predictions: [%{label: label}]} = result
>         label
>
>       _ ->
>         %{results: [%{text: label}]} = result
>         label
>     end
>
>   # Update the socket assigns with result and stopping spinner.
>   {:noreply, assign(socket, label: label, running: false)}
> end
> ```


Now all we need to do is change `lib/app/application.ex`
to make use of our newly-created module!

```elixir
defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    App.Models.verify_and_download_models()

    children = [
      # Start the Telemetry supervisor
      AppWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Nx serving for image classifier
      {Nx.Serving,
       serving:
         if Mix.env() == :test do
           App.Models.serving_test()
         else
           App.Models.serving()
         end,
       name: ImageClassifier},
      # Adding a supervisor
      {Task.Supervisor, name: App.TaskSupervisor},
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

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

As you can see,
we've made `application.ex` much more readable!
Take note that we're now conditionally
serving the correct `serving` function
according to the environment.

And you're done! 👏

Now you can:
- conditionally set the model cache directory
for tests and for production.
- define which models are loaded according to the env.


# Scaling up `fly` machines

Working with LLMs takes up CPU/GPU and RAM power to execute inference.

If you've followed the previous guide, 
you'll already have a simple, 
free-tier'd `fly.io` machine instance up and running.
However, you may run into some memory problems.
You run out of memory.
You may have come across log messages from `fly.io`
stating `Out of memory: Killed progress XXX`.

To fix these problems,
we need to [*scale up*](https://microservices.io/articles/scalecube.html)
our machine instance. 
That is, we need to give it more resources,
such as `RAM` and processing power.


> [!WARNING]
>
> This incurs a *cost*.
> Scaling up `fly.io` machines is **not free**.
> Check their [pricing list ](https://fly.io/docs/about/pricing/#fly-machines)
> for more information.


In order to scale our solution, we'll do two things:

- we'll **create another instance**
with **its own volume**,
leaving us with two instances with a volume each.

- give each instance more resources 
(essentially more CPU power).


## 1. Creating another `machine` and `volume` pair

Let's scale our application
so it has two instances.
Luckily for us, 
because we have a clean slate 
(one machine instance and one volume),
we just need to run the following command.

```sh
fly scale count 2
```

Your terminal will be shown the following information,
and ask you how it will scale.

```sh
App 'XXX' is going to be scaled according to this plan:
  +1 machines for group 'app' on region 'mad' of size 'shared-cpu-1x'
  +1 volumes  for group 'app' in region 'mad'
? Scale app XXX? (y/N) 
```

Type `y` and press `Enter`.
Wait for the volumes and instances to be created.

And that should be it!
If you run `fly volume list`
and `fly machine list`,
you should see the newly created volume 
and it being attached to the newly created machine instance.


> [!NOTE]
>
> You may find yourself in different scenarios.
> For example, you have `2` machine instances
> and `1` volume.
> In this case, you can still run `fly scale count 2`.
> It will prompt you to create a new volume,
> which you will need to attach yourself to the instance you desire.
>
> In other scenarios, you may want to explicitly clone or destroy
> existing machines on your application.
> You can use a combination of the `fly machine clone`/`fly machine destroy`
> and `fly volume destroy` to achieve what you want.
>
> For more information about this,
> check the official documentation in 
> https://fly.io/docs/apps/scale-count/#scale-an-app-with-volumes.


## 2. Scaling machine `CPU` and `RAM`

Now it's time to add more resources to our machines.
To simplify, 
we are assuming you only have one machine and one volume deployed.
You can surely scale up later if you want to
(just follow the steps above).

> [!NOTE]
>
> For the official documentation
> about scaling machine's `CPU` and `RAM`,
> you can find more information 
> in the official documentation at 
> https://fly.io/docs/apps/scale-machine/#select-a-preset-cpu-ram-combination.

If you are happy with the provisioned `CPU` resources
and simply want more memory, 
you can use the `fly scale memory` to increase the `RAM`.

In our case, we will use of the 
[`CPU`/`RAM` presets that `fly.io` provides](https://fly.io/docs/about/pricing/#fly-machines)
to scale our machines.
You can see the presets by running `fly platform vm-sizes`.

```
NAME            CPU CORES       MEMORY   
shared-cpu-1x   1               256 MB
shared-cpu-2x   2               512 MB
shared-cpu-4x   4               1 GB  
shared-cpu-8x   8               2 GB  

NAME            CPU CORES       MEMORY   
performance-1x  1               2 GB  
performance-2x  2               4 GB  
performance-4x  4               8 GB  
performance-8x  8               16 GB 
performance-16x 16              32 GB 

NAME            CPU CORES       MEMORY  GPU MODEL      
a100-40gb       8               32 GB   a100-pcie-40gb
a100-80gb       8               32 GB   a100-sxm4-80gb
```

In our case, we'll use the **`performance-1x`** preset.

> [!WARNING]
>
> Your are billed according to your provisioned resources.
> Meaning that if you aren't using `CPU` or `RAM`, 
> you're not being billed 
> (though you are charged if you use more than the free `3GB` of volume size - 
> see https://fly.io/docs/about/pricing/#persistent-storage-volumes).
>
> This means that you are **not being billed while the machine is stopped**.
> You can define for the machine to auto-stop after a period of inactivity
> [on your `fly.toml` file](https://fly.io/docs/reference/configuration/#the-http_service-section)
> (it's turned on by default).
>
> You can find more information on billing 
> in https://community.fly.io/t/how-does-billing-work/13613.

To scale our machine to a preset,
we need to run:

```sh
fly scale vm <preset-name>
```

Wait while your machine is being updated.

```
Updating machine d82301294fee9256
No health checks found
Machine d82301294fee9256 updated successfully!
Scaled VM Type to 'performance-1x'
      CPU Cores: 1
         Memory: 2048 MB
```

And that's it! 🎉

We've successfully scaled our `fly.io` machine instances!
We should now be able to run larger models
that should yield better results 🙂.
