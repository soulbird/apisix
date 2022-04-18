#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

. ./ci/common.sh

before_install() {
    sudo cpanm --notest Test::Nginx >build.log 2>&1 || (cat build.log && exit 1)

    # launch deps env
    make ci-env-up
    ./ci/linux-ci-init-service.sh
}

do_install() {
    export_or_prefix

    export OPENRESTY_VERSION=source
    ./utils/linux-install-openresty.sh

    ./utils/linux-install-luarocks.sh

    wget https://github.com/etcd-io/etcd/releases/download/v3.4.18/etcd-v3.4.18-linux-arm64.tar.gz
    tar xf etcd-v3.4.18-linux-arm64.tar.gz
    sudo cp etcd-v3.4.18-linux-arm64/etcdctl /usr/local/bin/
    rm -rf etcd-v3.4.18-linux-arm64

    create_lua_deps

    # sudo apt-get install tree -y
    # tree deps

    git clone https://github.com/openresty/test-nginx.git test-nginx
    make utils

    mkdir -p build-cache

    # install grpcurl
    install_grpcurl

    # install nodejs
    install_nodejs

    # install vault cli capabilities
    install_vault_cli
}

script() {
    export_or_prefix
    openresty -V

    # APISIX_ENABLE_LUACOV=1 PERL5LIB=.:$PERL5LIB prove -Itest-nginx/lib -r t
    FLUSH_ETCD=1 prove -Itest-nginx/lib -I./ -r $TEST_FILE_SUB_DIR | tee /tmp/test.result
    rerun_flaky_tests /tmp/test.result
}

after_success() {
    # cat luacov.stats.out
    # luacov-coveralls
    echo "done"
}

case_opt=$1
shift

case ${case_opt} in
before_install)
    before_install "$@"
    ;;
do_install)
    do_install "$@"
    ;;
script)
    script "$@"
    ;;
after_success)
    after_success "$@"
    ;;
esac
