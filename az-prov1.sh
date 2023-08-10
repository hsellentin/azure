#!/bin/bash

# prepare for bashttle
set -e

 # let's do all logging to a file on the VM, and print it from the build pipeline (where we can actually see output...)
 # this ensures our builds have the provisioning debug log recorded in the build pipeline on DevOps
logFile="/var/log/debug"
currentUser=$(whoami)
sudo touch $logFile
sudo chown "$currentUser" $logFile

# if provisioning fails, print log to the terminal that's running the `az` command
cleanup() {
  ret=$?
  if [ $ret -ne 0 ]; then
    echo "Debug log:"
    cat $logFile
  fi

  exit $ret
}
trap cleanup EXIT

# make `apt` great again
cat <<EOF > /etc/apt/sources.list
###### Ubuntu Main Repos
deb http://no.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse

###### Ubuntu Update Repos
deb http://no.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb http://no.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://no.archive.ubuntu.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://no.archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse
EOF

# install java and unzip
sudo apt update >>$logFile
sudo apt -y install openjdk-11-jdk-headless unzip >>$logFile

# env vars
export java_dir=/usr/lib/jvm/java-11-openjdk-amd64
export android_dir=/home/AzDevOps/android-sdk
export PATH=$PATH:$android_dir/cmdline-tools/latest
export PATH=$PATH:$android_dir/cmdline-tools/latest/bin

echo "android dir: $android_dir" >>$logFile

# get and extract android command line tools
wget -O tools.zip https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip
mkdir -p $android_dir/cmdline-tools
unzip tools.zip -d $android_dir/cmdline-tools >>$logFile

# https://stackoverflow.com/questions/60440509/android-command-line-tools-sdkmanager-always-shows-warning-could-not-create-se
rm -rf $android_dir/cmdline-tools/latest
mv $android_dir/cmdline-tools/cmdline-tools $android_dir/cmdline-tools/latest

# install android SDK
yes | sdkmanager --licenses >>$logFile

sdkmanager "emulator" "tools" "platform-tools"
yes | sdkmanager \
  "build-tools;31.0.0" >>$logFile

yes | sdkmanager \
  "extras;android;m2repository" \
  "extras;google;m2repository" \
  "extras;google;google_play_services" >>$logFile

yes | sdkmanager \
  "platforms;android-31" >>$logFile

echo "All is well." >>$logFile