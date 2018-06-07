if ( ! $?PYTHONPATH ) then
   setenv PYTHONPATH ""
endif

if ( ! $?LD_LIBRARY_PATH ) then
   setenv LD_LIBRARY_PATH ""
endif

# Python Package directories
setenv ROGUE_DIR /mnt/host/rogue
setenv LOCAL_DIR /mnt/host/atlas-rd53-daq/software/python
setenv SURF_DIR  /mnt/host/atlas-rd53-daq/firmware/submodules/surf/python
setenv PCIE_DIR  /mnt/host/atlas-rd53-daq/firmware/submodules/axi-pcie-core/python
setenv RCE_DIR   /mnt/host/atlas-rd53-daq/firmware/submodules/rce-gen3-fw-lib/python

# Setup python path
setenv PYTHONPATH ${LOCAL_DIR}:${SURF_DIR}:${PCIE_DIR}:${RCE_DIR}:${ROGUE_DIR}/python:${PYTHONPATH}

# Setup library path
setenv LD_LIBRARY_PATH ${ROGUE_DIR}/lib:${LD_LIBRARY_PATH}
