#!/bin/bash

# required Travis-ci secret variables (all other variables to be set in .travis.yml)
# DOCKER_PASS, DOCKER_USER

# login to docker
echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin &> /dev/null || exit 1

# push dev image (only latest)
if [ "$TRAVIS_BRANCH" = "dev" -a "$UBUNTU_VERSION" = "latest" ]; then
  echo "build and push docker image(s) for version $IMAGE:dev"
  docker build --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
    -t $IMAGE:dev .
  docker push $IMAGE:dev
fi

# push master images (not when it's a pull request)
if [ "$TRAVIS_BRANCH" = "master" -a "$TRAVIS_PULL_REQUEST" = "false" ]; then
  # tag including ALPINE version
  if [ "$UBUNTU_VERSION" = "latest" ]; then
    echo "build and push docker image(s) for version $IMAGE:latest"
    docker build --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
      -t $IMAGE:latest .
    docker push $IMAGE:latest
  else
    # build and load it into local docker repository, so we can launch it and determine version
    docker build --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
      -t $IMAGE .
    export VERSION=$(eval $(docker run --rm $IMAGE grep ^version= linuxgsm.sh); echo $version)

    # build again and push with correct version tag
    echo "build and push docker image(s) for version $IMAGE:$VERSION-$UBUNTU_VERSION"
    docker build --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
      -t $IMAGE:$VERSION-$UBUNTU_VERSION .
    docker push $IMAGE:$VERSION-$UBUNTU_VERSION
  fi
fi
