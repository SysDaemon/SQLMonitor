FROM mcr.microsoft.com/mssql/server:2019-latest

# Define enviorment variables
ENV ACCEPT_EULA=Y
ENV MSSQL_SA_PASSWORD=SQLMonitor2019

# Create a config directory
#RUN mkdir -p /usr/config
WORKDIR /usr/config

# Bundle config source
COPY . /usr/config/

# Grant execute permissions to the Shell Scripts
#RUN chmod +x /usr/config/entrypoint.sh
#RUN chmod +x /usr/config/configure-db.sh

ENTRYPOINT [ "sh", "entrypoint.sh"]
