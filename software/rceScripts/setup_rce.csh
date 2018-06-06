
# Setup environment
source /mnt/host/rogue/setup_env.csh

# Python Package directories
setenv SURF_DIR /mnt/host/atlas-rd53-daq/firmware/submodules/surf/python
setenv PCIE_DIR /mnt/host/atlas-rd53-daq/firmware/submodules/axi-pcie-core/python
setenv RCE_DIR  /mnt/host/atlas-rd53-daq/firmware/submodules/rce-gen3-fw-lib/python

# Setup python path
setenv PYTHONPATH ${PWD}/python:${SURF_DIR}:${PCIE_DIR}:${RCE_DIR}:${PYTHONPATH}
