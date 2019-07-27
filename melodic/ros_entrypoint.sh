#!/bin/bash
set -e

# setup user
if [[ -n "$UID" ]]; then
  useradd -m dev
  echo "dev:dev" | chpasswd
  usermod --shell /bin/bash dev
  usermod -aG sudo dev
  echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
  chmod 0440 /etc/sudoers.d/dev
  usermod --uid $UID dev
  usermod --gid $GID dev

  # switch into new user
  exec su -- dev
  . ~/.profile
fi

# setup ros environment
source "/opt/ros/$ROS_DISTRO/setup.bash"
exec "$@"