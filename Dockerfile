FROM ubuntu:focal
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Options::="--force-confdef" graphite-web graphite-carbon gunicorn nginx uuid && apt clean
RUN cp /usr/share/zoneinfo/America/Winnipeg /etc/localtime
# As of 2020-02-09, the graphite-web package for Ubuntu Focal doesn't, for wahtever reason actually work.
# graphite-manage spits back errors related to this missing INSTALLED_APPS item.
# This line inserts it in a rather uncultured, unapologetic way, and is going to break eventually.
RUN sed -i "s/^INSTALLED_APPS = (/INSTALLED_APPS = ('django.contrib.messages',/" \
    /usr/lib/python3/dist-packages/graphite/app_settings.py
RUN sed -i "s/#SECRET_KEY = 'UNSAFE_DEFAULT'/SECRET_KEY = '`uuid -v 4`'/" \
    /etc/graphite/local_settings.py
# Pulled from the official docker container's service run script for graphite
# Ref: https://github.com/graphite-project/docker-graphite-statsd/blob/43ddbd5219dd3917b754425c9177fdce6778c18c/conf/etc/service/graphite/run#L24
RUN graphite-manage makemigrations && \
    graphite-manage migrate && \
    graphite-manage migrate auth && \
    graphite-manage migrate --run-syncdb
RUN echo "CARBON_CACHE_ENABLED=true" > /etc/default/graphite-carbon
RUN sed -i "s/^MAX_CREATES_PER_MINUTE .*$/MAX_CREATES_PER_MINUTE = inf/" \
    /etc/carbon/carbon.conf
COPY nginx.conf /etc/nginx/sites-available/default
COPY storage-schemas.conf /etc/carbon/

ENTRYPOINT [ "/bin/bash", "-c", "service nginx start && service carbon-cache start && cd /usr/share/graphite-web && gunicorn -b 127.0.0.1:8000 graphite.wsgi"]
