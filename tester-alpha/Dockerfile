FROM tjhei/dealii-full-deps

MAINTAINER timo.heister@gmail.com

USER root
ADD script.sh script.sh
RUN chown bob:bob *.sh
USER bob

RUN chmod u+x *.sh
CMD ./script.sh
