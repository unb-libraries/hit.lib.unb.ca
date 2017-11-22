FROM unblibraries/drupal:alpine-nginx-php7-8.x-composer
MAINTAINER UNB Libraries <libsupport@unb.ca>

LABEL name="hit.lib.unb.ca"
LABEL vcs-ref=""
LABEL vcs-url="https://github.com/unb-libraries/hit.lib.unb.ca"

# Universal environment variables.
ENV DEPLOY_ENV prod
ENV DRUPAL_DEPLOY_CONFIGURATION TRUE
ENV DRUPAL_SITE_ID hit
ENV DRUPAL_SITE_URI hit.lib.unb.ca
ENV DRUPAL_SITE_UUID d5f8f4e2-fb53-42e5-a71e-c6b48f4a766f
ENV DRUPAL_CONFIGURATION_EXPORT_SKIP devel

# Add scripts, remove delete upstream drupal build.
COPY ./scripts/container /scripts
RUN /scripts/DeployUpstreamContainerScripts.sh && \
  /scripts/deleteUpstreamTree.sh

# Add LDAP, Mail Sending, rsyslog
RUN apk update && apk --update add rsyslog postfix php7-ldap php7-redis && \
  rm -f /var/cache/apk/* && \
  echo "TLS_REQCERT never" > /etc/openldap/ldap.conf && \
  touch /var/log/nginx/access.log && touch /var/log/nginx/error.log

# Tests.
COPY ./tests ${DRUPAL_TESTING_ROOT}

# Add package conf.
COPY ./package-conf /package-conf
RUN mv /package-conf/postfix/main.cf /etc/postfix/main.cf && \
  mkdir -p /etc/rsyslog.d && \
  mv /package-conf/rsyslog/21-logzio-nginx.conf /etc/rsyslog.d/21-logzio-nginx.conf && \
  mv /package-conf/nginx/app.conf /etc/nginx/conf.d/app.conf && \
  mv /package-conf/php/app-php.ini /etc/php7/conf.d/zz_app.ini && \
  mv /package-conf/php/app-php-fpm.conf /etc/php7/php-fpm.d/zz_app.conf && \
  rm -rf /package-conf

# Deploy the generalized profile and makefile into our specific one.
COPY build/ ${TMP_DRUPAL_BUILD_DIR}
ENV DRUPAL_BUILD_TMPROOT ${TMP_DRUPAL_BUILD_DIR}/webroot
RUN /scripts/deployGeneralizedProfile.sh && \
  /scripts/installNewRelic.sh

# Build the drupal tree.
ARG COMPOSER_DEPLOY_DEV=no-dev
RUN /scripts/buildDrupalTree.sh ${COMPOSER_DEPLOY_DEV} && \
  /scripts/installDevTools.sh ${COMPOSER_DEPLOY_DEV} && \
  /scripts/clearComposerCache.sh

# Copy configuration.
COPY ./config-yml ${TMP_DRUPAL_BUILD_DIR}/config-yml

# Custom modules not tracked in github.
COPY ./custom/modules ${TMP_DRUPAL_BUILD_DIR}/custom_modules
COPY ./custom/themes ${TMP_DRUPAL_BUILD_DIR}/custom_themes
