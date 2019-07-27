#!/bin/bash

ROS_DOCKER_IMAGE=${ROS_DOCKER_IMAGE:-jaci/ros}
ROS_DOCKER_HOME=${ROS_DOCKER_HOME:-$HOME}
ROS_USE_NVIDIA=true

# TODO: User remap on linux

ROS_DOCKER_ARGS=(
  --env="DISPLAY"
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw"
  # --volume="/etc/group:/etc/group:ro"
  # --volume="/etc/passwd:/etc/passwd:ro"
  # --volume="/etc/shadow:/etc/shadow:ro"
  # --volume="/etc/sudoers.d:/etc/sudoers.d:ro"
  # --user=$(id -u)
  --env HOME=$HOME
  --privileged
  --net=host
)

ros-launch() {
  local args=( "${ROS_DOCKER_ARGS[@]}" --volume="$ROS_DOCKER_HOME:$HOME" --volume="$(pwd):/work" )
  if [ "$ROS_USE_NVIDIA" == "true" ]; then
    args=( "${args[@]}" --runtime=nvidia )
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
