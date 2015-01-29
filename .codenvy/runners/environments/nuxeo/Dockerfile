FROM       nuxeo/nuxeo-codenvy-docker:latest

# Prepare application binded folder and Nuxeo plugins folder
ENV CODENVY_APP_BIND_DIR	/tmp/application
ENV NUXEO_PLUGIN_DIR			$NUXEO_HOME/nxserver/plugins

RUN mkdir $CODENVY_APP_BIND_DIR && \
    mkdir $NUXEO_PLUGIN_DIR


# Add instance.clid
ADD $src$/src/main/resources/instance.clid $NUXEO_HOME/nxserver/data/instance.clid

# Copy the app
CMD cp $CODENVY_APP_BIND_DIR/application.jar $NUXEO_PLUGIN_DIR && \
    /var/lib/nuxeo/server/bin/nuxeoctl console
