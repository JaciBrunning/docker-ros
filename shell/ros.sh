#!/bin/bash

ROS_DOCKER_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
ROS_DOCKER_DEFAULT_IMG=jaci/ros

ROS_DOCKER_HOME=${ROS_DOCKER_HOME:-$HOME}

ROS_DOCKER_XSOCK=/tmp/.X11-unix
ROS_DOCKER_XAUTH=/tmp/.docker.xauth

ROS_DOCKER_VERS_FILE=".docker-ros-version"

ros-xauth() {
  touch $1
  xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $1 nmerge -
}

ros-version() {
  LOCAL_FILE="./$ROS_DOCKER_VERS_FILE"
  USER_FILE="$ROS_DOCKER_PATH/$ROS_DOCKER_VERS_FILE"

  if [[ $# -gt 0 ]]; then
    action="$1"
    if [[ "$action" == "get" ]]; then
      if [[ -f $LOCAL_FILE ]]; then
        cat $LOCAL_FILE
      elif [[ -f $USER_FILE ]]; then
        cat $USER_FILE
      else
        echo $ROS_DOCKER_DEFAULT_IMG:melodic
      fi
    elif [[ "$action" == "set" ]]; then
      if [[ $# -eq 2 ]]; then
        echo $ROS_DOCKER_DEFAULT_IMG:$2 > $USER_FILE
      elif [[ $# -eq 3 ]] && [[ "$2" == "-i" ]]; then
        echo $3 > $USER_FILE
      else
        echo "Usage: ros-version set [-i image] [version]"
      fi
    elif [[ "$action" == "set-local" ]]; then
      if [[ $# -eq 2 ]]; then
        echo $ROS_DOCKER_DEFAULT_IMG:$2 > $LOCAL_FILE
      elif [[ $# -eq 3 ]] && [[ "$2" == "-i" ]]; then
        echo $3 > $LOCAL_FILE
      else
        echo "Usage: ros-version set [-i image] [version]"
      fi
    fi
  else
    echo "Usage: ros-version <action>"
    echo "  actions:"
    echo "    get: Get the current active ros version"
    echo "    set: Set the user default ros version"
    echo "    set-local: Set the directory default ros version"
  fi
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
  local image="$(ros-version get)"

  # Try to detect nvidia support
  if command -v nvidia-smi > /dev/null; then
    nvidia=y
  fi

  while [[ $# -gt 0 ]]
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
      -i|--image)
        image="$2"
        shift
        shift
        ;;
      -v|--version)
        image="$ROS_DOCKER_DEFAULT_IMG:$2"
        shift
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  echo "Starting ROS Docker Container with image $image"

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
