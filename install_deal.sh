#!/bin/bash

function sudocall(){
    FUNC="$(declare -f $1)"
    sudo bash -c "$FUNC; $1"
}

function install_dependencies(){
    BUILD_DEPS=(autoconf automake make cmake gcc-g++ gcc gcc-gfortran stow)
    PETSC_DEPS=(openmpi-devel openblas-devel valgrind-devel)
    SLEPC_DEPS=(python-unversioned-command)
    P4EST_DEPS=(splint)
    DEALII_DEPS=(doxygen perl graphviz gdb)
    DEALII_EXTRA_DEPS=(assimp-devel arpack-devel hdf5-openmpi-devel \
	gsl-devel)
    SYMENGINE_DEPS=(gmp-devel)
    SUNDIALS_DEPS=(lapack-devel)
    dnf install -y "${BUILD_DEPS[@]}" "${PETSC_DEPS[@]}" "${SLEPC_DEPS}" \
	    "${P4EST_DEPS[@]}" "${DEALII_DEPS[@]}" "${SYMENGINE_DEPS[@]}" \
	    "${DEALII_EXTRA_DEPS[@]}"
}


function install_petsc(){
    PETSC_VERSION="3.13.1"
    echo "To set PETSC_VERSION edit the 'install_deal.sh' file."
    if [[ ! -d "petsc-$PETSC_VERSION" ]]
    then
	echo "Downloading petsc-lite-$PETSC_VERSION.tar.gz..."
	URL="http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/\
             petsc-lite-$PETSC_VERSION.tar.gz" && \
	wget -c "${URL//[[:space:]]/}" && \
	tar xf "petsc-lite-$PETSC_VERSION.tar.gz"
    fi
    source /etc/profile.d/modules.sh && \
    module load mpi/openmpi-x86_64 && \
    cd "petsc-$PETSC_VERSION" && \
    ./configure \
	--prefix="/usr/local/stow/petsc" \
	PETSC_DIR=`pwd` \
	PETSC_ARCH="linux-gcc-opt" \
	COPTFLAGS="'-O3 -march=native -mtune=native'" \
	CXXOPTFLAGS="'-O3 -march=native -mtune=native'" \
	FOPTFLAGS="'-O3 -march=native -mtune=native'" \
	--with-debugging=no \
	--download-slepc \
	--download-scalapack && \
    make PETSC_DIR="`pwd`" PETSC_ARCH="linux-gcc-opt" && \
    make PETSC_DIR="`pwd`" PETSC_ARCH="linux-gcc-opt" install && \
    stow -d "/usr/local/stow" -S "petsc" && \
    make PETSC_DIR="/usr/local" PETSC_ARCH="" \
	OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 check && \
    cd ../ && \
    module unload mpi/openmpi-x86_64
}

function install_sundials(){
    SUNDIALS_VERSION="3.2.1"
    echo "To set the SUNDIALS version to download edit 'install_deal.sh' file."
    if [[ ! -d "sundials-$SUNDIALS_VERSION" ]]
    then
	URL="https://computing.llnl.gov/projects/sundials/download/sundials-\
	    $SUNDIALS_VERSION.tar.gz"
	wget -c "${URL//[[:space:]]/}" && \
	tar xf "sundials-$SUNDIALS_VERSION.tar.gz"
    fi
    if [[ ! -d "sundials-$SUNDIALS_VERSION/build" ]]
    then
	mkdir "sundials-$SUNDIALS_VERSION/build"
    else
	rm -rf "sundials-$SUNDIALS_VERSION/build/*"
    fi
    cd "sundials-$SUNDIALS_VERSION/build" && \
    source /etc/profile.d/modules.sh && \
    module load mpi/openmpi-x86_64 && \
    cmake \
	-DCMAKE_INSTALL_PREFIX="/usr/local/stow/sundials" \
	-DCMAKE_BUILD_TYPE="Release" \
	-DMPI_ENABLE="ON" \
	-DSUNDIALS_INDEX_SIZE="32" \
	-DPETSC_ENABLE="ON" \
	-DPETSC_DIR="/usr/local" \
    ../ && \
    make -j4 && \
    make install && \
    stow -d "/usr/local/stow" -S sundials && \
    module unload mpi/openmpi-x86_64
}

function install_p4est(){
    P4EST_VERSION="2.2"
    echo "To set P4EST_VERSION to download edit 'install_deal.sh' file."
    if [[ ! -d "p4est-$P4EST_VERSION" ]]
    then
	echo "Downloading p4est-$P4EST_VERSION..."
	URL="http://p4est.github.io/release/p4est-$P4EST_VERSION.tar.gz"
	wget -c "${URL}" && \
	tar xf "p4est-$P4EST_VERSION.tar.gz"
    fi
    cp "p4est-$P4EST_VERSION/doc/p4est-setup.sh" . && \
    source /etc/profile.d/modules.sh && \
    module load mpi/openmpi-x86_64
    ./p4est-setup.sh "./p4est-$P4EST_VERSION.tar.gz" "/usr/local/stow/p4est" && \
    stow -d "/usr/local/stow" -S "p4est" && \
    module unload mpi/openmpi-x86_64
}

function install_symengine(){
    if [[ ! -d symengine ]]
    then
	git clone https://github.com/symengine/symengine.git
    fi
    cd symengine && \
    git checkout $(git describe --abbrev=0 --tags) && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX="/usr/local/stow/symengine" .. && \
    make -j4 && \
    make install && \
    stow -d "/usr/local/stow" -S "symengine"
}

function install_dealii(){
    DEALII_VERSION="9.2.0"
    echo "To set the deal.II version to download edit 'install_deal.sh' file."
    if [[ ! -d "dealii-$DEALII_VERSION" ]]
    then
	echo "Downloading dealii-$DEALII_VERSION..."
	URL="https://github.com/dealii/dealii/releases/download/\
	    v$DEALII_VERSION/dealii-$DEALII_VERSION.tar.gz" 
	wget -c "${URL//[[:space:]]/}" && \
	tar xf "dealii-$DEALII_VERSION.tar.gz"
    fi

    DEALII_DIR="`pwd`/dealii-$DEALII_VERSION"

    if [[ ! -d "$DEALII_DIR/build" ]]
    then
	mkdir "$DEALII_DIR/build"
    else
	rm -rf "$DEALII_DIR/build/*"
    fi

    cd "dealii-$DEALII_VERSION/build" && \
    source /etc/profile.d/modules.sh && \
    module load mpi/openmpi-x86_64 && \
    cmake -DCMAKE_INSTALL_PREFIX="/usr/local/stow/dealii" \
	  -DDEAL_II_COMPONENT_DOCUMENTATION=ON \
	  -DDEAL_II_DOXYGEN_USE_MATHJAX=ON \
	  -DDEAL_II_WITH_MPI=ON \
	  -DDEAL_II_WITH_ARPACK=ON \
	  -DDEAL_II_WITH_ASSIMP=ON \
	  -DDEAL_II_WITH_HDF5=ON \
	  -DHDF5_DIR="/usr/lib64/openmpi" \
	  -DHDF5_INCLUDE_DIR="/usr/include/openmpi-x86_64" \
	  -DDEAL_II_WITH_P4EST=ON \
	  -DP4EST_DIR="/usr/local/stow/p4est" \
	  -DDEAL_II_WITH_GSL=ON \
	  -DDEAL_II_WITH_SCALAPACK=ON \
	  -DDEAL_II_WITH_SUNDIALS=ON \
	  -DDEAL_II_WITH_SYMENGINE=ON \
	  -DDEAL_II_WITH_SLEPC=ON \
	  -DDEAL_II_WITH_PETSC=ON \
	  -DDEAL_II_HAVE_FLAG_Og=false \
	  -DPETSC_ARCH="" \
    ../ && \
    make -j4 && \
    make -j4 documentation && \
    make install && \
    cd "/usr/local/stow/dealii/doc/doxygen/deal.II" && \
    source "$DEALII_DIR/contrib/utilities/makeofflinedoc.sh" && \
    stow -d "/usr/local/stow" -S "dealii" && \
    module unload mpi/openmpi-x86_64
}

function install_dealii_full(){
    sudocall install_dependencies && \
    sudocall install_petsc && \
    sudocall install_sundials && \
    sudocall install_p4est && \
    sudocall install_symengine && \
    sudocall install_dealii
}
