# Start from official Ubuntu base
FROM ubuntu:24.04

# Set required ENV variables
ENV DOTNET_ROOT=/opt/dotnet \
    PATH=/opt/dotnet:$PATH \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \
    LAMBDA_RUNTIME_DIR=/var/runtime \
    LAMBDA_TASK_ROOT=/var/task

ENV LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
# Install prerequisites
RUN apt-get update && \
    apt-get install -y wget curl apt-transport-https software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 8 Runtime
RUN wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \

    mkdir -p /opt/dotnet && \
    ln -s /usr/share/dotnet /opt/dotnet

# Dockerfile snippet for Ubuntu 24.04 + EmguCV dependencies

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tzdata ca-certificates curl wget \
    && ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \ 
    apt-get install -y --no-install-recommends build-essential libgtk-3-dev libgstreamer1.0-dev \
    libavcodec-dev libswscale-dev libavformat-dev libdc1394-dev libv4l-dev \
    cmake-curses-gui ocl-icd-dev freeglut3-dev libgeotiff-dev libusb-1.0-0-dev \
    libvtk9-dev libfreetype-dev libharfbuzz-dev qtbase5-dev libeigen3-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgflags-dev \
    libgoogle-glog-dev liblapacke-dev libva-dev 

RUN apt-get install -y mono-complete

# Install AWS Lambda Runtime Interface Emulator (for local testing)
RUN curl -Lo /usr/local/bin/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
    chmod +x /usr/local/bin/aws-lambda-rie

# Set working directory
WORKDIR /src

# Copy source and build
COPY ./ImageFilteringEmguCV ./Tolthawk/ImageFilteringEmguCV
COPY ./Tolthawk.Common ./Tolthawk/Tolthawk.Common
COPY ./Tolthawk.Core ./Tolthawk/Tolthawk.Core


WORKDIR /src/Tolthawk/ImageFilteringEmguCV/src/ImageFilteringEmguCV
RUN dotnet restore
RUN find /src
RUN dotnet build -c Release
#RUN find /src


RUN dotnet publish -c Release -o /var/task

RUN find /var/task


# Provide custom bootstrap
RUN echo '#!/bin/sh\nexec dotnet /var/task/bootstrap.dll' > /var/task/bootstrap && \
    chmod +x /var/task/bootstrap

RUN ldconfig -p | grep libgeotiff
RUN ldd /var/task/libcvextern.so


# Set bootstrap as entrypoint (this makes it a custom runtime image)
ENTRYPOINT ["/var/task/bootstrap"]
