#!/bin/bash

# Put this in your local machine's' ~/.ssh/config
#
# Host *
#     User sdunlap
#     StrictHostKeyChecking no
#     UserKnownHostsFile /dev/null
#     ForwardX11 yes
#     ForwardX11Trusted yes
#     LogLevel quiet
#
# Host lc-atl-344
#     Hostname lc-atl-344.ash.broadcom.net
#     Compression yes
#     Ciphers blowfish-cbc,arcfour

echo -e "\nRsync files from local clone to remote build server..."
rsync -aP --filter=':- ~/.gitignore' ../../../RLS_BFC5.7.1mp1_B1 sdunlap@lc-atl-344:/projects/bfc_work1/sdunlap

if [ "$?" -eq "0" ]
then
    echo -e "\nCalling makeapp on build server using SSH command..."
    ssh -tq rbbswbld "cd /projects/bfc_work1/sdunlap/RLS_BFC5.7.1mp1_B1/rbb_cm_src/CmDocsisSystem/ecos;makeapp "$@""
    rsync rbbswbld:/projects/bfc_work1/sdunlap/RLS_BFC5.7.1mp1_B1/rbb_cm_src/CmDocsisSystem/ecos/bcm93384wvg_ipv6/ecram.shortmap .

else
  echo "\nFailed to rsync files!"
fi