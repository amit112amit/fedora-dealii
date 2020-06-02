# Bash Script to install deal.II on Fedora WorkStation

### How to use it?

 1. Download the `install_deal.sh` file on your Fedora WorkStation device.
 2. Create a new container to install deal.II: `toolbox create -c dealii`.
 3. Enter the container: `toolbox enter -c dealii`.
 4. Load functions from the installation script file: `source ./install_deal.sh`/
 5. Run the installation function: `install_dealii_full`.

### Details

The script is brokend down into separate functions:

 1. `install_dependencies`: Installs required packages from Fedora Repository.
 2. `install_petsc`: We build PETSc from source because it is hard to install SLEPc with the PETSc installed from Fedora Repository.
 3. `install_sundials`: Deal.II does not support SUNDIALS version newer than 3.2.1. So we have to build from source.
 4. `install_p4est`: Installs `p4est` mesh partitioner instead of METIS or PARMETIS.
 5. `install_symengine`: Install `symengine` from the Github repo.

If for any reason one of the steps fails, you can edit the script and call only the required functions.
