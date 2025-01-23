FROM python:3.8

# set a directory for the app
WORKDIR /usr/src/app

# copy all the files to the container
COPY . .

# install dependencies
RUN pip install -r requirements.txt

# Install AWS CLI and jq
RUN apt-get update && apt-get install -y \
    awscli jq \
    && rm -rf /var/lib/apt/lists/*
    
# tell the port number the container should expose
EXPOSE 5000

# run the command
CMD ["/bin/bash", "-c", "source ./fetch-secrets.sh && python app.py"]
