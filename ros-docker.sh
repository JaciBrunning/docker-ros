#!/bin/bash

ROS_DOCKER_IMAGE=${ROS_DOCKER_IMAGE:-jaci/ros}
ROS_DOCKER_HOME=${ROS_DOCKER_HOME:-$HOME}
ROS_DOCKER_UNCONFINED=${ROS_DOCKER_UNCONFINED:-true}
ROS_DOCKER_NVIDIA=${ROS_DOCKER_NVIDIA:-true}

ROS_DOCKER_XSOCK=/tmp/.X11-unix
ROS_DOCKER_XAUTH=/tmp/.docker.xauth

ros-xauth() {
  touch $XAUTH
  xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
}

ros-launch() {
  local args=( 
    --env="DISPLAY" 
    --env HOME=$HOME 
    --env UID=$UID
    --env GID=$GID
    --net=host 
    --volume="$ROS_DOCKER_HOME:$HOME" 
    --volume="$(pwd):/work"
  )

  # XOrg
  local XSOCK=$ROS_DOCKER_XSOCK
  local XAUTH=$ROS_DOCKER_XAUTH
  args=( 
    "${args[@]}" 
    --volume="${XSOCK}:${XSOCK}:rw" 
    --volume="${XAUTH}:${XAUTH}:rw" 
    --env="XAUTHORITY=${XAUTH}"
  )

  # NVIDIA
  if [[ "$ROS_DOCKER_NVIDIA" == "true" ]]; then
    args=( "${args[@]}" --runtime=nvidia )
  fi

  # Security
  if [[ "$ROS_DOCKER_UNCONFINED" == "true" ]]; then
    # Required for melodic (ubuntu 18.04 container).
    # Really, it boils down to this: https://github.com/moby/moby/issues/38442
    # To avoid having to add new apparmor profiles, we can run unconfined. The ROS installation
    # should be fairly trusted, but it can be avoided by setting ROS_DOCKER_UNCONFINED to false
    args=( "${args[@]}" --security-opt apparmor:unconfined )
  fi

  docker run ${args[@]} $@
}

ros() {
  local image=$ROS_DOCKER_IMAGE:$1
  if [[ $1 == "i:"* ]]; then
    # Arg provided is an image
    image=${1:2}
    echo "Using Image: ${image}"
  fi
  ros-launch --rm -it $image ${@:2}
}
