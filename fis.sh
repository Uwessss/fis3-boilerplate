#!/bin/bash

# consts
CONFIG_FILE="fis-conf.js"
SOURCE_FOLDER="src"
SERVER_TYPE="browsersync"
SERVER_PORT="3000"
SERVER_CONFIG="bs-config.js"
DIST_FOLDER="dist"
ARCHIVE_FOLDER="archive"
ARCHIVE_FILETYPE="zip" # zip,tar.gz  ; tar.gz do NOT support chinese filename
LOG_FILE=`node -e "console.log(require('./project.config.js').build.log)"`
TEMP_RESOURCE_FOLDER=`node -e "console.log(require('./project.config.js').build.temp)"`
PLATFORM=`node -e "console.log(process.platform)"`
ENV_PATH_SEP=":"
if [ "$PLATFORM" = "win32" ]; then
  ENV_PATH_SEP=";"
fi
PROJECT_NAME=`node -e "console.log(require('./project.config.js').project.name)"`
PWD=`pwd`

# env
export NODE_PATH=$NODE_PATH$ENV_PATH_SEP`npm -g root`

function main() {
  clear
  echo ""
  echo "                       fis3 debug & distribute script"
  echo ""
  echo "                            see http://fis.baidu.com"
  echo "                      by fisker Cheung lionkay@gmail.com"
  echo ""
  echo ""
  echo "==============================================================================="
  echo ""
  echo ""
  echo "                  1. debug (default)"
  echo ""
  echo "                  2. distribute"
  echo ""
  echo "                  3. distribute & archive"
  echo ""
  echo "                  Q. quit"
  echo ""
  echo ""

  # chose operation
  read -t 5 -n1 -p "Please choose an option:" choice
  case "$choice" in
    2)
      export NODE_ENV="production"
      clear
      release
      end
      ;;
    3)
      export NODE_ENV="production"
      clear
      release
      archive
      end
      ;;
    q|Q)
      quit
      ;;
    *)
      export NODE_ENV="development"
      clear
      debug
      pause
      ;;
  esac
}

function release() {
  # remove release file and log file
  if [ -d "./$DIST_FOLDER" ]; then
    rm -r "./$DIST_FOLDER"
  fi
  if [ -f "./$LOG_FILE" ]; then
    rm "./$LOG_FILE"
  fi

  # release file
  echo "..............................................................................."
  echo "releasing files"
  fis3 release $NODE_ENV --dest "./$DIST_FOLDER" --root "./$SOURCE_FOLDER" --file "./$CONFIG_FILE" --clean --unique --lint --verbose --no-color > "./$LOG_FILE" || error

  if [ -d "./$DIST_FOLDER/$TEMP_RESOURCE_FOLDER" ]; then
    rm -r "./$DIST_FOLDER/$TEMP_RESOURCE_FOLDER"
  fi

  echo "..........................................................................done."
  echo ""
}

# archive
function archive() {
  echo "archive"

  # make distribute folder ready
  if [ ! -d "./$ARCHIVE_FOLDER" ]; then
    mkdir "./$ARCHIVE_FOLDER"
  fi

  # set distribute file name
  DATE=`date "+%y%m%d-%H%M%S"`
  DIST_FILENAME="$PROJECT_NAME.$DATE"

  # archive files to distribute folder
  echo "..............................................................................."
  echo "packing files"
  if [ "$ARCHIVE_FILETYPE" = "tar.gz" ]; then
    targz -l 9 -m 9 -c "./$DIST_FOLDER" "./$ARCHIVE_FOLDER/$DIST_FILENAME.tar.gz" || pause
  else
    winzip zip "./$DIST_FOLDER" "./$ARCHIVE_FOLDER/$DIST_FILENAME" || pause
  fi

  if [ "$PLATFORM" = "win32" ]; then
    explorer "$ARCHIVE_FOLDER"
  fi

  echo "..........................................................................done."
}

#debug
function debug() {
  # stop server
  echo "..............................................................................."
  echo "stop server"
  fis3 server stop || pause
  # if errorlevel 1 ( pause )
  echo "..........................................................................done."
  echo ""

  # clean up
  echo "..............................................................................."
  echo "clean up server folder"
  fis3 server clean || pause
  # if errorlevel 1 ( pause )
  echo "..........................................................................done."
  echo ""

  # start server
  echo "..............................................................................."
  echo "start server"
  fis3 server start --type $SERVER_TYPE --port $SERVER_PORT || pause
  echo "..........................................................................done."
  echo ""

  # start watch
  echo "..............................................................................."
  echo "watching files"
  fis3 release $NODE_ENV --root "./$SOURCE_FOLDER" --file "./$CONFIG_FILE" --clean --verbose --watch
}

function pause() {
  echo "press any key to continue."
  read -n 1
}

function error() {
  echo "..............................................................................."
  echo "                                error occurred"
  echo "..............................................................................."
  echo ""
  cat "./$LOG_FILE"
  pause
  end
}

function end() {
  echo "exit in 5 seconds"
  sleep 5
  exit
}

main

