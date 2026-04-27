# Docker ONBUILD supply chain attack POC

This repo contains two dockerfiles, which combine to show how a compromised layer in the docker dependency chain can gain access to build-time secrets and build-arguments, and can modify build artifacts in dangerous ways, via the ONBUILD directive. These capabilities are normally only available to processes specified by the developer in their own dockerfile. Defenses are available, but not widespread, and the attack surface seems to not be well explored in the literature

## Preface

ONBUILD allows upstream docker images to specify instructions to be ran by the final image at build-time. This is intended to be for library code to autmagically handle repetitive work that all downstream images would have to implement, such as installing dependencies

However, ONBUILD is allowed access to the build-process just as if it was regular build instructions. This means that build-secrets, build-arguments, and env-vars are available for extraction, and the build-context is available for both exfiltration and modification.

## How the POC works

The POC is split in multiple attacks that abuse this design:

1. Secret and argument "exfil":
   - The first ONBUILD layer of the parent dockerfile contains instructions that take informed guesses at possible secret values given to the build. It then persists these to /app/secrets and /app/build-args. This is just to demonstrate the capacity, the secrets still stay in the container, but you could easily imagine how this would work with a curl script extracting them

2. Output modification:
   - Second ONBUILD shows a step where the build container swaps out a dependency in a go.mod file, making the app run a known-vulnerable dependency. Also here, you could imagine much worse scenarios where the app gets injected with a backdoor for example

3. Remote build control:
   - Third shows a script being downloaded and piped into sh, a common install pattern. This is probably the worst one, as the instructions on the remote server can change the behaviour of the script without changing the hash of the base image. This means that even if the url is deemed safe at audit-time, it may later become compromised, at which point the build can be completely remote controlled by the threat actor
