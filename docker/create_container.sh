docker run \
 --name sfnetworks \
 -e DISABLE_AUTH=TRUE \
 -e USERID=$UID \
 -p 8786:8787 \
 -v $PWD:/home/rstudio/workdir \
 sfnetworks