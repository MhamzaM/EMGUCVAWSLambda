# Start from official Ubuntu base
FROM ubuntu:22.04

# Set required ENV variables
ENV DOTNET_ROOT=/opt/dotnet \
    PATH=/opt/dotnet:$PATH \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \
    LAMBDA_RUNTIME_DIR=/var/runtime \
    LAMBDA_TASK_ROOT=/var/task

# Install prerequisites
RUN apt-get update && \
    apt-get install -y wget curl apt-transport-https software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 8 Runtime
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    mkdir -p /opt/dotnet && \
    ln -s /usr/share/dotnet /opt/dotnet

#Install EMGU CV Dependencies
RUN curl -o /tmp/apt_install_dependency \
    https://raw.githubusercontent.com/emgucv/emgucv/4.10.0/platforms/ubuntu/24.04/apt_install_dependency && \
    chmod +x /tmp/apt_install_dependency && \
    /tmp/apt_install_dependency && \
    rm /tmp/apt_install_dependency

# Install AWS Lambda Runtime Interface Emulator (for local testing)
RUN curl -Lo /usr/local/bin/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
    chmod +x /usr/local/bin/aws-lambda-rie

# Set working directory
WORKDIR /src

# Copy source and build
COPY . .
RUN dotnet publish -c Release -o /var/task

# Provide custom bootstrap
RUN echo '#!/bin/sh\nexec dotnet /var/task/bootstrap.dll' > /var/task/bootstrap && \
    chmod +x /var/task/bootstrap

# Set bootstrap as entrypoint (this makes it a custom runtime image)
ENTRYPOINT ["/var/task/bootstrap"]
