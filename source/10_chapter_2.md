# Implementation

## Introduction

In this chapter I will first outline the flow of information through Victor's services in it's most general use case. Then, working from the bottom up, I'll detail the implementation process including how working parts of the services are tied together and how each of the three services, the garden, the api, and the dashboard, interact.

## Flow Control

![Flow \label{flow}](source/figures/FullFlow.png)

Victor uses a role based access control system in which only two types of users are considered to exist. The vast majority of users that might access the application are uncredentialed, outside users. This group makes up person who wishes to view the data, but has not been given access to make any changes. These users will almost always be accessing the site remotely, meaning requests to the dashboard will not come from the same network that the garden is connected to. The other group is much smaller and is made up of garden maintainers who want to and have the access to make changes to the garden remotely. These credentialed admin users have access to all of the same functions as the outside users; however, once their access has been properly vetted, they gain the additional power of manipulating data via PUT and DELETE requests to the API and issuing commands to be evaluated by the garden machines.

As a outside user, the benefits made available by Victor are in consuming data about the garden's environment. Outside user's can use this a point of reference or comparison for their own gardens, so they want an easy way to consume recent relevant data. To do this the user must access the URL of the dashboard. Though no means of collaboration is included in the framework, access to the dashboard is made available through the projects Github repository. Upon accessing the main page, the dashboard service immediately realizes that the user's request is unauthorized, so a call to the API is necessary to identify roles. The The API seeing a request coming from the user, knows that read requests from an uncredentialed user are allowed, so it gathers the most recent set of data from the garden and sends it back as a JSON object to the dashboard. Once the dashboard gets the data it cleans it and constructs the appropriate graphs and widgets. Knowing that more relevant data is saved and stored with the API service every few minutes, the dashboard makes sure the check back in periodically to maintain relevance.

An outside user has no direct communication with the garden network itself, but rather the data that is sent from the garden's sensors is summoned and displayed by the dashboard on request. Communication between the garden and the API occurs only through one head device. The garden can be constructed using any number of machines, but communication is limited to being sent and received by a single elected proxy. Each machine that is a member of the garden's network hosts sensors contained by Docker containers. These contained processes continuously, generally based on a time increment though there is no enforced standard, take measurements about the garden environment and relay them to garden's head communicator device. The communicator maintains a service for relaying data points to the API to be stored. Data points are sent in the same manner regardless of which sensor they came from. This is a implementation decision meant to allow for the addition of any number of arbitrary sensors and controls. Doing so made the load a bit heavier for the dashboard service because data needs to be sorted and accounted for, but because there are large extensibility gains and the data is purely textual and relatively light weight it seems to be worth it.

As a credentialed user this is still the most commonly used flow of data. Sensor data is sent to the API which is sent to dashboard after being asked for by the user. The control is augmented, however, by being able to send messages through the api directly to the garden. As an admin user after accessing the garden's dashboard page I have the option of logging into the service. Logging in requires only a username and password. Submitting credentials sends a message to the api, which handles identification and authorization. If the user exists and the password is correct a token is sent back to the dashboard and access is granted. credentialed access allows the user to view another page that facilitates additional control interfaces. For instance, if the user wants to turn on the water pump manually for some amount of time they can elect to send a command to the API that is then relayed to garden's communicator and executed. Sending this message requires only two things aside from using the dashboards UI to send the proper message. First the token value that was received previously after signing in must match one of those that is currently valid and dispatched. Secondly, to prevent sniffing token values, the API must also be sent a One Time Password from an authorized two factor authentication key. Ultimately this means, to control the garden you need both a username and password as well as a physical device like a Yubikey to command the garden components. Once the API verifies that your request is valid it then sends the appropriate request to the communicator, which is then parsed and dispatched to the proper process.

These two roles and the parties that are allowed to communicate maintain a very robust and secure service despite the number of moving parts. In the following sections I'll identify how the tools outlined in the previous chapter were used to build the components of Victor's ecosystem and how they can be customized to remain relevant and deliberate for any garden configuration.

### Container-Gardening

![Garden \label{containers}](source/figures/Gardener.png)

Container-Gardening is the name I've given to the repository for all of the resources and processes to be run on the microcomputer that lives physically connected to the garden.

In the case of my specific test build I've chosen to use three separate boards, each of which are produced and sold by RaspberryPi. The three microcomputers are the RaspberryPi 3, RaspberryPi Zero, and RaspberryPi 2 rev b.

![Model B \label{model_b}](source/figures/modelb.jpg)

![Zero \label{zero}](source/figures/zero.jpg)

![3 \label{3}](source/figures/pi3.jpg)

Each board has drastically different cost, IO limitations, and power requirements. For instance, the RaspberryPi Zero, a $5 microcomputer, has a power rating of 160ma and a 1 Ghz single core processor, whereas the RaspberryPi model 3 costs $37.95 for a 1.2 Ghz quad-core processor and an 800ma power rating.

Though the total power usage of the build and the computational power required to host the required sensors will ultimately impact the choice in platform -- there are a small set of requirements. First the garden's computer needs to run some variant of linux in order to leverage the Docker ecosystem. I've chosen Ubuntu ARM, but any modern Linux OS would reliably and comfortably facilitate using Docker. The chosen board also needs a GPIO interface. A strong majority of sensors sold today interface over GPIO. I2C and SPI communication protocols are relatively efficient, so the total number of external components per board can be much greater than alternatives using input like USB. Lastly, the board needs some means of networking. At least one board needs access to the internet, but all need some way to communicate whether over the wire, HTTP, or some other short range mesh networking.

Every sensor thats attached to a garden's computer is liable to interface in a different way; however, in order to exist in the context of Victor they're all handled in a very similar way. First, every component needs to establish a physical hardware connection with their respective board. In most cases this entail three or four wired connections -- two of which provide power and ground.

Assuming the connection is successful, the sensor needs a respective program to intermittently collect a measurement and forward it on. Each sensor has it's own directory in the container-gardening repository. Sensors are categorized by parameter, and subdivided if two similar measurements are being taken. For instance the directory for the DS18B20 temperature sensor can be found at `container-gardening/temperature/1wire`. There is more than one temperature sensor being used in my build so I chose to designate this particular one by the protocol it uses. This directory houses the code that schedules measurement and any additionally required libraries. Whereas many sensors have provided open-source libraries, some sensors require low-level calibration and communication code. The flow for measurement scheduling is loosely standardized.

A job function is designated to be run on a predetermined interval. The job in most cases has three responsibilities. For the components it's responsible for, the job gathers measurements, formats the data in API digestible messages, and sends the readings to the `Gardener`, the container tasked with handling communication to and from the garden.

```python
import w1thermsensor
import schedule
import requests
import json
import time
import os

def job():
    for sensor in w1thermsensor.W1ThermSensor.get_available_sensors():
        send_data(sensor.get_temperature())

def send_data(temperature):
    entry = json.dumps({'parameter': 'temperature', 'value': str(temperature)})
    url = (os.environ['API'] + '/dev/datum')
    requests.post(url, data=entry)

schedule.every(15).minutes.do(job)

while True:
    schedule.run_pending()
    time.sleep(1)
```

In this example, we're gathering temperature data from the DS18B20\. This particular sensor has an API, which we include using `import w1thermsensor`. This sensors job() function is simply iterate through every DS18B20 attached -- there are multiple because this sensor interfaces using the 1wire protocol -- package each measurement into a simple JSOn message, and send it along. The jobs initialization is handled by a library called `schedule`, which is a single-process program level implementation of chron. Using schedule we can determine how frequently to gather measurement.

Once we can interface with our sensor programmatically on a timed interval, it's time to define a Dockerfile to containerize the sensor in question. In doing so, we isolate the sensor's dependencies, define a local network by which the containers can communicate, and prevent unwanted access between processes. Each Dockerfile, which defines the process of building the sensor's environment, is defined a directory in the `container-gardening` repository called `dockerfiles`. The directory mirrors the sensor's organization exactly for the sake of simplicity.

This is the Dockerfile that runs and manages the code from the previous example (`container-gardening/dockerfiles/temperature/1wire/Dockerfile`):

```
FROM resin/rpi-raspbian:jessie

RUN apt-get update && apt-get install -y \
    git-core \
    build-essential \
    gcc \
    python \
    python-dev \
    python-pip \
    python-virtualenv \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN pip install w1thermsensor
RUN pip install schedule

RUN git clone https://github.com/btcrs/container-gardening.git /data/container-gardening

# Define working directory
WORKDIR /data
VOLUME /data

CMD ["python", "/data/container-gardening/temperature/1wire/simple_temperature.py"]
```

Every Dockerfile begins with a `FROM` directive. This defines the base image that our image will ultimately be built up from. I've chosen `resin/rpi-raspbian:jessie` for the majority of my RaspberryPi containers. This is a bare-bones version of Raspian, which is a Debian based Linux OS optimized for the Raspberry Pi hardware, it has most of the tools I've needed and for the most part has just worked.

The next three RUN directives define all of the OS and program dependencies necessary to run the program. Here I define which `apt-get install` and `pip install` commands need to be run to provision the container.

The next command clones the entire container-gardening repository to the container. This step is somewhat wasteful because it's very redundant, but I opted to grab the entire repository for simplicity. Some of the sensors have multi-file directories and includes, and I've abstracted some utility functions to their own module. If the number of sensor declarations and resources dramatically hindered storage and build time it might make sense to define the container-gardening repository as a collection of sensor submodules.

The `VOLUME` directive defines a directory to be made accessible from the host machine and `WORKDIR` sets the context from which the following `CMD` command should be runs

Lastly, the build process executes the defined `CMD` command which is programmed to run indefinitely.

At this point we could build the container manually and run it, which would begin to show sensor output and send newly acquired entries. One further step is required to include this newly defined container into the Victor framework.

Each machine that exists as a part of the garden's configuration has what's called a `docker-compose.yml` file. Docker-compose, which is one of the tools provided in the Docker ecosystem that's used to define and run multi-container applications. It's assumed that different machines in the garden's configuration will have unique sets of sensors, sol docker-compose is used to define which collection programs we want to run on any given machine.

The DS18B20 is hosted on the RaspberryPi 3 in my build along with a handful of other sensors. The docker-compose.yml file used for the RaspberryPi 3 provides a canonical name, build instructions, and run parameters for each of theses sensors, so that they can be run in conjunction using a single command.

```
version: '2'
services:
  temperature:
    build: ./dockerfiles/temperature/1wire/
    privileged: true
    devices:
     - /dev/ttyAMA0:/dev/ttyAMA0
     - /dev/mem:/dev/mem
    volumes:
     - /data
  uv:
    build: ./dockerfiles/uv/lux/
    privileged: true
    devices:
     - /dev/ttyAMA0:/dev/ttyAMA0
     - /dev/mem:/dev/mem
    volumes:
     - /data
  flow:
    build: ./dockerfiles/flow/
    privileged: true
    devices:
     - /dev/ttyAMA0:/dev/ttyAMA0
     - /dev/mem:/dev/mem
    volumes:
     - /data
  multi:
    build: ./dockerfiles/multi/
    privileged: true
    devices:
     - /dev/ttyAMA0:/dev/ttyAMA0
     - /dev/mem:/dev/mem
    volumes:
     - /data
  depth:
    build: ./dockerfiles/depth/
    privileged: true
    devices:
     - /dev/ttyAMA0:/dev/ttyAMA0
     - /dev/mem:/dev/mem
    volumes:
     - /data
  depth:
    build: ./dockerfiles/pressure/5803
    privileged: true
    devices:
     - /dev/ttyAMA0:/dev/ttyAMA0
     - /dev/mem:/dev/mem
    volumes:
     - /data
```

Each of service defined under the services tag defines a separate docker container. In this case the requirements are all very similar. The `temperature` tag defines the name to be given to the container. `build` delineates where to find the dockerfile associated with this container. `privileged` defines that the contianer may need sudo access to run appropriately. `volumes` explicitly states any of the volumes, which may be defined in the dockerfile. One of the most important declarations is `devices` which specifies a runtime parameter allowing the container to directly interface with the hardware.

The incredibly powerful implication of this tool is that a single command `docker-compose up` from within the proper directory builds every defined container and starts collecting data rapidly in a secure, manageable way. Furthermore, the containers are ephemeral, so changes can be deployed with ease and downtime can be strongly mitigated because of the speed and ease of start up. Lastly, though each sensor requires a few important pieces, this architecture keeps the deployment of a system nearly identical regardless of the complexity and size of the configuration, which is a massive gain for extensibility.

### Gardeners-Log

![API \label{log}](source/figures/Api.png)

At this point each of the sensors is capable of measuring and reporting data, but we haven't defined a location where the data should be sent. `Gardeners-Log` is the service that handles the manipulation of data, authentication, and communication between the dashboard and `container-gardening` level processes. At its core `Gardeners-Log` is a simple RESTful API; however, the architecture on which it's built and the security implementations associated allow for a scalable, protected channel of information transfer.

Victor uses a serverless architecture for it's API because it hands off the responsibility of managing, scaling, and provisioning servers to the serverless provider. We're already maintaining a semi-complex deployment of IOT devices, so minimizing the complexity and cost of the other services helped keep everything as manageable as possible. Victor's API is currently hosted on AWS Lambda, Amazon's serverless platform. Architecturally, the API is made up of a composition of a few of Amazon's cloud services interacting with Lambda's compute platform. The entry point for any application wishing to interact with garden data is an Amazon API Gateway. This gateway is an HTTP listener configured to initiate a certain function correlated to the path used to access it. The gateway also provides an interface for using custom authorizer functions and API key authorization. Behind the API gateway sits some number of Lambda functions. Functions are stand alone module exports exposing a single method. Though lambda supports a few languages, I chose to write my functions in Node. The functions used for Victor's API define CRUD operations for the Garden's database. These functions interact with the last Amazon cloud service involved in this architecture, DynamoDb. The data is light and relatively consistent in shape, so most storage implementations would be suitable, but DynamoDb was an easy choice because it is managed, pretty simple, and exists within the Amazon ecosystem. Though the API gateway is constantly listening for new requests, the Lambda functions spin up on demand and are metered by ticks of 100ms. Unlike a standard always on servers the runtime costs should be very minor for a REST API.

As mentioned in the section detailing Flow Control there are two primary users, credentialed and uncredentialed. However, another communicating party is the `Gardener` container hosted on one of the Garden's computers. Unlike, the aforementioned user types, the `Gardener` isn't able to navigate through a multi-step authentication process. The data being sent to the API is the most valuable resource provided by Victor, so naturally I wanted to put some measures in place to preserve data integrity. The API Gateway service has a concept of protected paths with which I implemented relatively simple, secret based authentication. Through AWS management I created an API key for each of the garden's microcomputers. In the configuration of the POST function I designated the function as protected and allowed any of the three keys to authenticate. In the docker-compose configuration I define the respective keys as environmental variables which are accessed by the sensors code. In doing so, I have a log of which machine accessed the POST method of the API gateway and the data that it submitted.

Credentialed users, however, may need to update or delete data. I wasn't comfortable with secret based authentication for admin level operations, so I exposed another set of Lambda functions on the separate API gateway to be used as authorizer function. When a user requests to authorize to the API they're redirected based on a chosen provider to either Facebook's or Google's authentication page. The provider asks the user if they authorize Victor read access of their account. If the user allows authorization of Victor then the provider sends an authorization code to the API. With this code the API sends an authorization request back to the provider and in turn receives an access token.

This flow represents standard Oauth authentication. The authorizer function of both the PUT and DELETE entry points of the API's gateway is set to the authorization function of the of my second Lambda based authentication service. This means that for any PUT or DELETE request sent to the API must also pass the authorization function.

After a user authenticates they receive an access token that is in turn sent with every subsequent request. This token is passed to the authorizer. The authorized constructs and sends a request to the correct provider with the access key. If the access token is valid, the API will process the request according to its API specifications. If the access token is expired or otherwise invalid, the API will return an "invalid_request" error. If the Authorizer passes successfully then the originally requested operation is performed otherwise an error message is returned.

The resulting API is simple, but exposes all necessary operations in a very deliberate manner. Creation of data entries is handled by POST requests to `/dev/datum` and authorized via the API keys. Manipulation of data is handled by PUT and DELETE requests to `/dev/datum/{id}` and authorized via the separate serverless Oauth service. Obtaining a list of every entry is handled by a get request to `/dev/datum/` and getting a single entry by a GET request to `/dev/datum/{id}`. Neither of the read requests are credentialed so that unauthorized users are still able to view the garden's data. In the following subsection I'll outline the construction of one of the serverless function.

#### Serverless

All of AWS Lambda development was done using a framework aptly named `Serverless`. Each collection of functions is called a service. Every service is contained within its own directory and defined by a file name `serverless.yml`.

The first portion of this file details AWS configuration metadata.

```
service: victors-api

frameworkVersion: ">=1.1.0 <2.0.0"

provider:
  name: aws
  runtime: nodejs4.3
  environment:
    DYNAMODB_TABLE: ${self:service}-${opt:stage, self:provider.stage}
  iamRoleStatements:
    - Effect: Allow
      Action:
        - dynamodb:Query
        - dynamodb:Scan
        - dynamodb:GetItem
        - dynamodb:PutItem
        - dynamodb:UpdateItem
        - dynamodb:DeleteItem
      Resource: "arn:aws:dynamodb:${opt:region, self:provider.region}:*:table/${self:provider.environment.DYNAMODB_TABLE}"
  apiKeys:
   - DataLogger
```

This snippet defines the language the functions are written in, environmental variables and api keys, and identity management configuration for the defined resources.

The next section provides a declaration for each function contained in the service.

```
functions:
  create:
    handler: datum/create.create
    events:
      - http:
          path: datum
          method: post
          private: true
          cors: true
          integration: lambda
```

Here I define the create function, whcih is located at the path `datum/create`. The `events` tag defines the API gateway path that will trigger this function. `integration`, `path`, and `method` declare that it will be triggered by a POST to an API gateway at the path datum. `private` indicates the request will require a key defined in the previous snippet called `DataLogger`. `cors` allows the request to be called by another resource rather than directly by a user.

Finally, a DynamoDB instance is defined in the resources section declaring the database and table that the functions will interact with:

```
resources:
  Resources:
    DataDynamoDbTable:
      Type: 'AWS::DynamoDB::Table'
      DeletionPolicy: Retain
      Properties:
        AttributeDefinitions:
          -
            AttributeName: id
            AttributeType: S
        KeySchema:
          -
            AttributeName: id
            KeyType: HASH
        ProvisionedThroughput:
          ReadCapacityUnits: 1
          WriteCapacityUnits: 1
        TableName: ${self:provider.environment.DYNAMODB_TABLE}
```

The function itself is a small, but not by necessity, Node file.

```
const uuid = require('uuid');
const AWS = require('aws-sdk');

const dynamoDb = new AWS.DynamoDB.DocumentClient();

module.exports.create = (event, context, callback) => {
  const timestamp = new Date().getTime();
  const data = JSON.parse(event.body);
  if (typeof data.value !== 'string' || typeof data.parameter !== 'string') {
    console.error('Validation Failed');
    callback(new Error('Couldn\'t create the data value.'));
    return;
  }

  const params = {
    TableName: process.env.DYNAMODB_TABLE,
    Item: {
      id: uuid.v1(),
      parameter: data.parameter,
      value: data.value,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
  };

  dynamoDb.put(params, (error, result) => {
    if (error) {
      console.error(error);
      callback(new Error('Couldn\'t create the data entry.'));
      return;
    }

    const response = {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin" : "*" // Required for CORS support to work
      },
      body: JSON.stringify(result.Item),
    };
    callback(null, response);
  });
};
```

The file defines a single function that takes the parameters event, context, and callback. These define event data, runtime information of the Lambda function, and a function used to return information to the caller.

This particular function takes the data posted in the event's request body and the current time and then constructs an object to be stored in the dynamoDB database defined in the resources section. The function passes a 200 response back to the caller as long as the database call did not error out.

Once every other function is defined `serverless deploy` translates `serverless.yml` to a single AWS CloudFormation template, zips the functions, and publishes a new version for each function in the service.

In line with the emphasis on extensibility this architecture allows for a modular, secure, and highly modifiable API that implements and exposes every necessary action safely.

### Victor

![Victor \label{Victor}](source/figures/Victor.png)

With `container-gardening` consistently gathering sensor data and `gardeners-log` providing a means of both storage and access, a single service stands in the way Victor being a transparent and pleasant user experience. Simply named `victor`, the framework's front end is the view of the application in totality to most users. Though `victor` the web application, is the simplest component of victor, the framework, the front end is responsible for masking the fact that there exists any separation of duties among services while also offering a beautiful and useful interface.

I chose to build this application using Angular, and I've hosted it using GitHub pages. All of the data garden's data is accessible via a single HTTP call, so the application is composed of entirely static resources. This proved incredibly useful because Github pages, though limited to only static pages, is hosted completely for free. Furthermore, any changes made to the page, on the `gh-pages` branch of the repository, are immediately deployed to the site.

`victor` is a web application with two primary views. As a user makes a request for any of the site's page, the base authentication service examines the request's cookies looking for an access token. If no token is found, the page request is immediately redirected to the login page. The login view is relatively bare. The user can choose to login via either Facebook or Google or if they aren't interested in authenticating they have the option of accessing a read only view of the garden.

If the request does contain an access token, the user successfully authenticates, or they choose to view the read-only data then they're routed to the garden dashboard view. This view's controller immediately makes a request to the API to gather the most recent data. The data is received as a large JSON array, which makes manipulation and sorting quick and easy.

From the received array, the controller constructs an objects matching each parameter's name to an array of objects representing that parameter's measurements. Each element of the array takes the form `{'value': XX, 'dateCreated': mm/dd/yyyy}`. The view uses an Angular directive `ng-repeat` to iterate through the object of parameters and constructs a time series graph for each.

Though collecting and sorting all of the data adds some complexity to the client-side service, doing so allows for any configuration of sensors. Designation of data is handled via the parameter, and the datas representation is parameter agnostic. Parameter specific view configuration can be handled and defined within the controller's view if necessary.

For credentialed users a small icon button is added to the parameters with configuration or manual controls. Clicking the button opens a window with the appropriate inputs and a form mapped to the API endpoint. Submitting the form sends a simple HTTP request in the same exact format as submitting or manipulating data. User's controls are never multi-step, so submission fully hands off responsibility to the API. Furthermore, any command that invalidates the controller's current data initializes a subsequent request for a data update. Neither call requires the page to reload, but because of Angular's two way data-binding any change in data is immediately reflected in the view resulting in a near real-time display. If no change occurs on the page, the data is refreshed based on the time since the last API call.

As previously mentioned, this service is very simple, which is largely due to the architecture of the other components. I chose to develop a web application for the widest availability, but there's very little preventing the front end being replaced or duplicated. The data is fully abstracted from the application, so a mobile application, native client, or something more novel like a skill for Amazon's Alexa.
