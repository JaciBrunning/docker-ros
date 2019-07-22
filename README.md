ROS NVIDIA Docker Images
=====

This project provides docker images for ROS with NVIDIA acceleration, allowing graphical applications like rviz to be run in an isolated environment, or on a system that doesn't match ROS version requirements, 

Example use cases:
  - Testing a ROS network in a containerized environment
  - Running ROS melodic on Ubuntu 19.04, or on any unsupported platform

Docker Hub: https://hub.docker.com/r/jaci/ros-nvidia

## Images:
- `jaci/ros-nvidia:kinetic-*` - based on Ubuntu 16.04
  - `ros-core`, `ros-base`
  - `robot`, `perception`
  - `desktop`
  - `desktop-full` (default)

- `jaci/ros-nvidia:melodic-*` - based on Ubuntu 18.04
  - `ros-core`, `ros-base`
  - `robot`, `perception`
  - `desktop`
  - `desktop-full` (default)

## Setting up
1. Install [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker)
2. Put `ros-docker.sh` somewhere on your system, and make it executable
3. Add `ros-docker.sh` as a source in your `.zshrc` / `.bashrc` / etc file, optionally adding environment variables to customize the installation
```bash
# Recommended. By default, this is /home, which means the container has access to your entire homedir.
# It's recommended to set it somewhere isolated. Note that you'll have to manually create the user dir
# (/some/isolated/home/YOURNAME)
ROS_NVIDIA_DOCKER_HOME=/some/isolated/home

# Add some docker args. Default is blank
ROS_NVIDIA_DOCKER_ARGS=--env CUSTOM_ENV=CUSTOM_VAL

# Change the image being used, in case you've made your own derivation of the image in order to add
# certain packages or other data.
ROS_NVIDIA_DOCKER_IMAGE=yourname/my-ros-nvidia-image

source /path/to/ros-docker.sh
```

## Running
The `ros-docker.sh` script provides some basic features to help start the docker containers.  
By default, it will:
- Setup X11 display and NVIDIA runtime
- Setup user forwarding (docker container will have your current user and its permissions)
- Use host networking, so multiple containers may talk to each other through `localhost`
- Bind container `/home` to the hosts' `ROS_NVIDIA_DOCKER_HOME` (by default, `/home`)
- Bind container `/work` (working directory) to the current directory

Get a shell
```bash
$ ros-nvidia melodic
user@host:/work$
```

Provide a command line option
```bash
$ ros-nvidia melodic rosrun rviz rviz
```

Change the image type
```bash
$ ros-nvidia melodic-ros-core
user@host:/work$
```

Use your own image by prepending `i:`
```bash
$ ros-nvidia i:yourname/myimg:version
```

### I don't want the default docker setup
You don't need to use `ros-docker.sh` if you don't need it. You can run it with `docker run` like any container.  

Example: isolated ros-core with nvidia passthrough  
`docker run --runtime=nvidia --rm -it jaci/ros-nvidia:melodic roscore`

Note: even though these images provide nvidia acceleration, you don't require `--runtime=nvidia` if you don't need CUDA and/or GUI applications.  

## Building your own images
If you require your own packages or ROS plugins, it can be advantageous to build your own images so you don't have to reinstall them with every new container.

```Dockerfile
# Dockerfile
FROM jaci/ros-nvidia:melodic

# .... Your stuff here ....
```

You can continue to run `docker build -t yourname/yourimage:melodic .`, pushing to Docker Hub if you so desire.  

