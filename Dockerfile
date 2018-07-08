
FROM ubuntu:16.04

MAINTAINER Craig Citro <craigcitro@google.com>

RUN apt-get update && apt-get install -y --no-install-recommends && \
        apt-get -y install software-properties-common python-software-properties \
        build-essential \
        curl \
        git \
        
        make \
        sudo \
        wget \
        libcurl3-dev \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \    
        libibverbs-dev \
        libibverbs1 \
        librdmacm1 \
        librdmacm-dev \
        rdmacm-utils \
        libibmad-dev \
        libibmad5 \
        byacc \
        libibumad-dev \
        libibumad3 \
        flex \
        
        pkg-config \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        && \    
    apt-get install -y python3.4 && \
    apt-get install -y python3-pip && \
    apt-get install -y python-qt4 && \ 
    apt-get install -y nodejs-legacy && \
    apt-get install -y npm && \
        
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        scipy \
        sklearn \
        pandas \
        && \
    python -m ipykernel.kernelspec

# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /

# Set up Bazel.

# We need to add a custom PPA to pick up JDK8, since trusty doesn't
# have an openjdk8 backport.  openjdk-r is maintained by a reliable contributor:
# Matthias Klose (https://launchpad.net/~doko).  It will do until
# we either update the base image beyond 14.04 or openjdk-8 is
# finally backported to trusty; see e.g.
#   https://bugs.launchpad.net/trusty-backports/+bug/1368094
#RUN add-apt-repository -y ppa:openjdk-r/ppa && \
#    apt-get update && \
#    apt-get install -y --no-install-recommends openjdk-8-jdk openjdk-8-jre-headless && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/*

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
#RUN echo "startup --batch" >>/etc/bazel.bazelrc
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
#RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
#    >>/etc/bazel.bazelrc
# Install the most recent bazel release.
#ENV BAZEL_VERSION 0.10.0
#WORKDIR /
#RUN mkdir /bazel && \
#    cd /bazel && \
#    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
#    curl -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
#    chmod +x bazel-*.sh && \
#    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
#    cd / && \
#    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.

#ARG version=master
#RUN git clone https://github.com/tensorflow/tensorflow.git && \
#    cd tensorflow && \
#    git reset --hard $version && git submodule update
#WORKDIR /tensorflow

# TODO(craigcitro): Don't install the pip package, since it makes it
# more difficult to experiment with local changes. Instead, just add
# the built directory to the path.

#ENV CI_BUILD_PYTHON python

#RUN tensorflow/tools/ci_build/builds/configured CPU && \
#    bazel build --config=opt -c opt tensorflow/tools/pip_package:build_pip_package && \
#    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/pip && \
#    pip --no-cache-dir install --upgrade /tmp/pip/tensorflow-*.whl && \
#    rm -rf /tmp/pip && \
#    rm -rf /root/.cache
# Clean up pip wheel and Bazel cache when done.

COPY yb-sw-config.NIMBIX.x8664.turbotensor.sh /tmp/
RUN /bin/bash -x /tmp/yb-sw-config.NIMBIX.x8664.turbotensor.sh 

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

WORKDIR /root
CMD ["/bin/bash"]
