FROM tjhei/dealii:v8.4.1

MAINTAINER timo.heister@gmail.com

ARG VER=master

# now build and install
RUN cd deal.II && \
    mkdir build && cd build && \
    cmake -D DEAL_II_WITH_MPI=ON \
    	  -D CMAKE_C_COMPILER=clang \
          -D CMAKE_CXX_COMPILER=clang++ \
          -D DEAL_II_COMPONENT_EXAMPLES=OFF \
          -D CMAKE_INSTALL_PREFIX=~/deal.II/installed-$VER-clang \
          -D CMAKE_BUILD_TYPE=Debug \
          ../dealii && \
    make -j4 && \
    make install && \
    make test && \
    cd .. && rm -rf build

# ENV DEAL_II_DIR ~/deal.II/installed-$VER-clang
