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
  - [1.Considerations before you deploy](#1considerations-before-you-deploy)
  - [2. Initializing `fly.io`-related files](#2-initializing-flyio-related-files)
  - [3. Changing config files](#3-changing-config-files)
    - [3.1 `Dockerfile`](#31-dockerfile)
      - [3.1.1 Installing `wget` so `ESLA` can be properly downloaded](#311-installing-wget-so-esla-can-be-properly-downloaded)
      - [3.1.2 Setting the local directory where `Bumblebee` models will load from](#312-setting-the-local-directory-where-bumblebee-models-will-load-from)
      - [3.1.3 Fixing `nonexistent` directory error](#313-fixing-nonexistent-directory-error)
    - [3.2 Changing `EXLA` settings](#32-changing-exla-settings)
- [4. Deploy again!](#4-deploy-again)



## 1.Considerations before you deploy

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


## 2. Initializing `fly.io`-related files

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


## 3. Changing config files

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

### 3.1 `Dockerfile`

Let's make some changes to the `Dockerfile`.
This is the bulk of the changes we need to make,
so let's go over them.


#### 3.1.1 Installing `wget` so `ESLA` can be properly downloaded

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


#### 3.1.2 Setting the local directory where `Bumblebee` models will load from

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

Therefore, change the `Dockerfile` so it looks like this
(look for the `# ADD THIS` comments):

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
# ADD THIS
ENV EXS_DRY_RUN="true"  
# ADD THIS
ENV BUMBLEBEE_CACHE_DIR="/app/.bumblebee"

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

# ADD THIS
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
# ADD THIS
ENV EXS_DRY_RUN="true"
# ADD THIS
ENV BUMBLEBEE_CACHE_DIR="/app/.bumblebee"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/app ./
# ADD THIS
COPY --from=builder --chown=nobody:root /app/.bumblebee/ ./.bumblebee

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]

CMD ["/app/bin/server"]

```


#### 3.1.3 Fixing `nonexistent` directory error

After making these changes,
the deployment whilst running `fly launch`
will probably succeed 🥳.

However, 
you may notice that the instance errors out when trying to use it.

This is because `Bumblebee` needs a cache directory
in order to download the models.

To fix this,
you simply need to add one line to the Dockerfile.

```dockerfile
ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26.0.2
ARG DEBIAN_VERSION=bullseye-20231009-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*


WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"
ENV EXS_DRY_RUN="true"
ENV BUMBLEBEE_CACHE_DIR="/app/.bumblebee"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

COPY .bumblebee/ .bumblebee

RUN mix assets.deploy

RUN mix compile

COPY config/runtime.exs config/

COPY rel rel
RUN mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

ENV MIX_ENV="prod"
ENV EXS_DRY_RUN="true"
ENV BUMBLEBEE_CACHE_DIR="/app/.bumblebee"

# ADD THIS
RUN mkdir -p /nonexistent 

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/app ./
COPY --from=builder --chown=nobody:root /app/.bumblebee/ ./.bumblebee

USER nobody

CMD ["/app/bin/server"]
```

That's it! 
We just needed to create the directory! 😅


### 3.2 Changing `EXLA` settings

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
> d`efn_options: [compiler: EXLA, lazy_transfers: :always]` - 
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



# 4. Deploy again!

Now that we've made the needed changes,
we can deploy the application again! <br />
Simply run `fly launch`
and re-use the same configuration
(we've already run `fly launch` prior,
so the configuration files are there already).

If you walk through the steps,
the deployment should run smoothly
and your site should be up and running.

Great job! 
Give yourself a pat on the back! 👏