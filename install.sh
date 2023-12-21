#!/bin/bash
source config.sh
ABSOLUTE_DIR=$PWD

function check() {
    ping github.com -c 1
    if [ $? -ne 0 ]; then
        echo "ping github.com fail"
        exit 1
    fi
    echo "ping github.com check success"

    return 0
}

function exec() {
    local cmd=$1
    $cmd
    if [ $? -ne 0 ]; then
        echo "exec $cmd fail"
        exit 1
    fi
    return 0 
}

function docker_pull_image() {
    docker pull $PYTHON_IMAGE
    docker pull $NGINX_IMAGE
}

function install_getaway() {
    local nginx_conf_file=$ABSOLUTE_DIR"/nginx/conf/conf.d/default.conf"
    sed -i "s/authauth_address/$AUTH_ADDRESS/g" $nginx_conf_file
    sed -i "s/llm_address/$LLM_ADDRESS/g" $nginx_conf_file

    docker run -p 443:443 --name nginx \
    -v $ABSOLUTE_DIR/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
    -v $ABSOLUTE_DIR/nginx/conf/conf.d:/etc/nginx/conf.d \
    -v $ABSOLUTE_DIR/nginx/log:/var/log/nginx \
    -v $ABSOLUTE_DIR/nginx/html:/usr/share/nginx/html \ 
    -v $ABSOLUTE_DIR/ssl/server.pem:/etc/ssl/server.pem \ 
    -v $ABSOLUTE_DIR/ssl/server.key:/etc/ssl/server.key \
    -d $NGINX_IMAGE
}

function install_auth() {
    git clone $GIT_AUTH
    cd palantiri-auth
    docker build -t palantiri-auth .
    cd - 
    mkdir -p $AUTH_FILE_DIR
    docker run -p 9999:9999 --name palantiri-auth  -v $AUTH_FILE_DIR:$AUTH_FILE_DIR -d palantiri-auth
}

check
docker_pull_image
install_getaway
install_auth
