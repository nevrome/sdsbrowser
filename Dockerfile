FROM rocker/shiny:latest

MAINTAINER Clemens Schmid <clemens@nevrome.de>

# install necessary system packages
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    htop \
    nano \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/ \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# install necessary R packages
RUN R -e "install.packages('devtools')"
RUN R -e "devtools::install_github('nevrome/sdsanalysis')"
RUN R -e "devtools::install_github('nevrome/sdsbrowser')"

RUN mkdir /srv/shiny-server/sdsbrowser
RUN echo "sdsbrowser::sdsbrowser(run_app = FALSE)" >  /srv/shiny-server/sdsbrowser/app.R

# create config 
RUN echo "run_as shiny; \
          disable_protocols websocket xhr-streaming xhr-polling iframe-xhr-polling; \
          disable_websockets true; \
		      server { \
  		       listen 3838; \
  		       location / { \
    		         app_dir /srv/shiny-server/sdsbrowser; \
    		         directory_index off; \
    		         log_dir /var/log/shiny-server; \
  		       } \
		     }" > /etc/shiny-server/shiny-server.conf

# if this shiny server configuration setup causes problems related to websockets and/or
# a proxy server, then try to add the following lines after "run_as shiny; \" 
# and before "server { \":
#          disable_protocols websocket xhr-streaming xhr-polling iframe-xhr-polling; \
#          disable_websockets true; \

# start it
CMD exec shiny-server >> /var/log/shiny-server.log 2>&1
