#!/bin/bash

ROS_DOCKER_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

ROS_DOCKER_IMAGE=${ROS_DOCKER_IMAGE:-jaci/ros}
ROS_DOCKER_HOME=${ROS_DOCKER_HOME:-$HOME}

ROS_DOCKER_XSOCK=/tmp/.X11-unix
ROS_DOCKER_XAUTH=/tmp/.docker.xauth

ros-xauth() {
  touch $1
  xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $1 nmerge -
}

ros-launch() {
  local args=(
    --net=host 
    --volume="$(pwd):/work"
  )

  local dockerargs=()
  local withx=y
  local nvidia=
  local root=
  local confined=
  local image=

  # Try to detect nvidia support
  if command -v nvidia-smi > /dev/null; then
    nvidia=y
  fi

  while [[ $# -gt 0 && -z $image ]]
  do
    key="$1"
    case $key in 
      --confine)
        confined=y
        shift
        ;;
      --unconfine)
        confined=
        shift
        ;;
      --nvidia)
        nvidia=y
        shift
        ;;
      --no-nvidia)
        nvidia=
        shift
        ;;
      --no-x)
        withx=
        shift
        ;;
      --root)
        root=y
        shift
        ;;
      --rm)
        dockerargs=( "${dockerargs[@]}" --rm )
        shift
        ;;
      -it|--interactive)
        dockerargs=( "${dockerargs[@]}" -it )
        shift
        ;;
      -d|--docker)
        dockerargs=( "${dockerargs[@]}" $2 )
        shift
        shift
        ;;
      --image)
        image="$2"
        shift
        shift
        ;;
      *)
        image="$ROS_DOCKER_IMAGE:$1"
        shift
        ;;
    esac
  done

  if [[ -n "$withx" ]]; then
    # X Forwarding Enabled
    local XSOCK=$ROS_DOCKER_XSOCK
    local XAUTH=$ROS_DOCKER_XAUTH

    ros-xauth $XAUTH

    args=( 
      "${args[@]}"
      --env="DISPLAY"
      --volume="${XSOCK}:${XSOCK}:rw" 
      --volume="${XAUTH}:${XAUTH}:rw" 
      --env="XAUTHORITY=${XAUTH}"
    )
  fi

  if [[ -n "$nvidia" ]]; then
    # NVIDIA Runtime Enabled
    args=( "${args[@]}" --runtime=nvidia )
  fi

  if [[ -z "$root" ]]; then
    # Build new container with appropriate user
    args=(
      "${args[@]}"
      --env HOME=$HOME
      --env UID=$UID
      --env GID=$GID
      --volume $ROS_DOCKER_HOME:$HOME
    )

    image=$(docker build -q --build-arg FROM=$image --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$GID $ROS_DOCKER_PATH)
  fi

  if [[ -z "$confined" ]]; then
    # Unconfined
    # Required for melodic (ubuntu 18.04 container).
    # Really, it boils down to this: https://github.com/moby/moby/issues/38442
    # To avoid having to add new apparmor profiles, we can run unconfined. The ROS installation
    # should be fairly trusted, but it can be avoided by setting ROS_DOCKER_UNCONFINED to false
    args=( "${args[@]}" --security-opt apparmor:unconfined )
  fi

  args=( "${args[@]}" "${dockerargs[@]}" $image )

  docker run ${args[@]} $@
}

ros() {
  ros-launch --rm -it $@
}
