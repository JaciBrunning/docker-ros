ARG FROM
FROM $FROM

ARG USER=dev
ARG UID=1000
ARG GID=$UID 

ENV HOME /home/$USER
ENV UID $UID
ENV GID $GID
ENV USER $USER

RUN groupadd --gid $GID $USER && \
    useradd --uid $UID --gid $GID -m -d $HOME $USER && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER && \
    chmod 0440 /etc/sudoers.d/$USER

USER $USER