FROM ubuntu:24.04

# 1. Install system prerequisites
RUN apt-get update && apt-get install -y software-properties-common wget gnupg2 && rm -rf /var/lib/apt/lists/*

# 2. Add the official applications PPA that contains the REAL, non-snap Chromium binary
RUN add-apt-repository ppa:xtradeb/apps -y

# 3. Install Java, X11, graphics dependencies, AND the OS Chromium package
RUN apt-get update && apt-get install -y \
    openjdk-21-jre libxext6 libxrender1 libxtst6 libxi6 \
    libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2t64 \
    libx11-xcb1 libxcb-dri3-0 libxshmfence1 libxss1 \
    git chromium \
  && rm -rf /var/lib/apt/lists/*

# Place any cloned extension repos here, right after "RUN," and make sure it goes within the /home/ubuntu directory.
# Each time you want to add one to the list, place a "\" after the git command and then put the new addition on the next line with an indent as seen above.
RUN git clone https://github.com/mrknow001/RSC_Detector.git /home/ubuntu/RSC_Detector

WORKDIR /home/ubuntu
USER 1000
