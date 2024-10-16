# Use the same base image version as the clams-python python library version
# FROM ghcr.io/clamsproject/clams-python-ffmpeg-tf2:1.2.3
# FROM tensorflow/tensorflow:latest-gpu
FROM tensorflow/tensorflow:2.14.0-gpu

# FROM tensorflow/tensorflow:2.3.3-gpu
# RUN rm /etc/apt/sources.list.d/cuda.list
# RUN rm /etc/apt/sources.list.d/nvidia-ml.list

# install python3.10
ENV DEBIAN_FRONTEND=noninteractive 


# See https://github.com/orgs/clamsproject/packages?tab=packages&q=clams-python for more base images
# IF you want to automatically publish this image to the clamsproject organization, 
# 1. you should have generated this template without --no-github-actions flag
# 1. to add arm64 support, change relevant line in .github/workflows/container.yml 
#     * NOTE that a lots of software doesn't install/compile or run on arm64 architecture out of the box 
#     * make sure you locally test the compatibility of all software dependencies before using arm64 support 
# 1. use a git tag to trigger the github action. You need to use git tag to properly set app version anyway

################################################################################
# DO NOT EDIT THIS SECTION
ARG CLAMS_APP_VERSION
ENV CLAMS_APP_VERSION ${CLAMS_APP_VERSION}
################################################################################

################################################################################
# clams-python base images are based on debian distro
# install more system packages as needed using the apt manager
RUN apt-get update && apt-get install -y git curl ffmpeg

# RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
#   && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
#     sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
#     tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
# RUN apt-get update
# RUN apt-get install -y nvidia-container-toolkit

################################################################################

################################################################################
# main app installation
COPY ./ /app
WORKDIR /app
RUN pip3 install --ignore-installed -r requirements.txt
RUN pip3 install ffmpeg-python
# default command to run the CLAMS app in a production server 
CMD ["python3", "app.py", "--production"]
################################################################################
