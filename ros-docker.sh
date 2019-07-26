#!/bin/bash

ROS_NVIDIA_DOCKER_IMAGE=${ROS_NVIDIA_DOCKER_IMAGE:-jaci/ros-nvidia}
ROS_NVIDIA_DOCKER_HOME=${ROS_NVIDIA_DOCKER_HOME:-/home}
ROS_NVIDIA_DOCKER_ARGS=${ROS_NVIDIA_DOCKER_ARGS:-}

ros-nvidia-launch() {
  docker run \
      --env="DISPLAY" \
      --volume="/etc/group:/etc/group:ro" \
      --volume="/etc/passwd:/etc/passwd:ro" \
      --volume="/etc/shadow:/etc/shadow:ro" \
      --volume="/etc/sudoers.d:/etc/sudoers.d:ro" \
      --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
      --volume="$ROS_NVIDIA_DOCKER_HOME:/home" \
      --volume="$(pwd):/work" \
      --runtime=nvidia \
      --privileged \
      --net=host \
      --user=$(id -u) \
      --env HOME=/home/$(id -un) \
      $ROS_NVIDIA_DOCKER_ARGS \
      $@
}

ros-nvidia() {
  local image=$ROS_NVIDIA_DOCKER_IMAGE:$1
  if [[ $1 == "i:"* ]]; then
    # Arg provided is an image
    image=${1:2}
    echo "Using Image: ${image}"
  fi
  ros-nvidia-launch --rm -it $image ${@:2}
}
