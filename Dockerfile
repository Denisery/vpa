FROM ubuntu:20.04

# Set environment variables
ENV ANDROID_SDK_ROOT=/root/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    wget \
    unzip \
    libqt5widgets5 \
    libgl1-mesa-dev \
    libpulse0 \
    x11vnc \
    xvfb \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download and install Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d $ANDROID_SDK_ROOT && \
    mv $ANDROID_SDK_ROOT/cmdline-tools $ANDROID_SDK_ROOT/tools && \
    rm /tmp/cmdline-tools.zip

# Install required packages and emulator system images
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT "platform-tools" "emulator" "platforms;android-30" "system-images;android-30;google_apis;x86"

# Create and start the emulator
RUN echo "no" | avdmanager create avd -n test -k "system-images;android-30;google_apis;x86" --device "pixel"

# Set up a display using Xvfb
ENV DISPLAY=:0
RUN Xvfb :0 -screen 0 1024x768x16 &

# Start the VNC server
RUN x11vnc -display :0 -forever -nopw -rfbport 5900 &

# Install noVNC (browser-based VNC viewer)
RUN mkdir -p /novnc && \
    wget https://github.com/novnc/noVNC/archive/refs/heads/master.zip -O /tmp/novnc.zip && \
    unzip /tmp/novnc.zip -d / && \
    mv /noVNC-master/* /novnc && \
    rm -rf /tmp/novnc.zip

# Expose VNC server port
EXPOSE 5900

# Expose noVNC server port
EXPOSE 6080

# Start the emulator and noVNC server
CMD emulator -avd test -no-audio -no-window -gpu swiftshader & \
    /novnc/utils/launch.sh --vnc localhost:5900 --listen 6080
