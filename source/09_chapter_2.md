# Implementation

## Introduction

In this chapter I will first outline the flow of information through Victor's services in it is most general use case. Then, working from the bottom up, I will detail the implementation process including how working parts of the services are tied together and how each of the four services, the garden, the database, the mediator, and the dashboard, interact.

## Flow Control

![Full Flow Diagram \label{flow}](source/figures/FullFlow.png){ width=30% }


Victor uses a role based access control system in which only two types of users are considered to exist. The vast majority of users that might access the application are uncredentialed, outside users. This group makes up the people who wish to view the data, but have not been given access to make any changes. These users will almost always be accessing the site remotely, meaning requests to the dashboard will not come from the same network that the garden is connected to. The other group is much smaller and is made up of garden maintainers who want to and have the access to make changes to the garden remotely. These credentialed admin users have access to all of the same functions as the outside users; however, once their access has been properly vetted, they gain the additional power of manipulating data via PUT and DELETE requests to the `Gardeners-log` and issuing commands through `Gardeners-shed` to be evaluated by the garden machines.

Outside users benefit from being able to consume data about the garden's environment through Victor. Outside users can use this a point of reference or comparison for their own gardens, so they want an easy way to consume recent relevant data. To do this the user must access the URL of the dashboard. Access to the dashboard is made available through a link on the project's Github repository. When the user accesses the main page, the dashboard service immediately realizes that the user's request is unauthorized, so a call to `Gardeners-log` is necessary to identify roles. `Gardeners-log` seeing a request coming from the user, knows that read requests from an uncredentialed user are allowed, so it gathers the most recent set of data from the garden and sends it back as a JSON object to the dashboard. Once the dashboard gets the data it cleans it and constructs the appropriate graphs and widgets. Knowing that more relevant data is saved and stored with `Gardeners-log` every few minutes, the dashboard makes sure to check with the database service periodically for new data to maintain relevance.

An outside user has no direct communication with the garden network itself, but rather the data that is sent from the garden's sensors is summoned and displayed by the dashboard on request. Communication between the garden and the `Gardeners-log` occurs only through one head device. The garden can be constructed using any number of machines, but communication is limited to being sent and received by a single designated proxy. Each machine that is a member of the garden's network hosts sensors contained by Docker containers. These contained processes continuously, generally based on a time increment though there is no enforced standard, take measurements about the garden environment and relay them to garden's head communicator device. The communicator maintains a service for relaying data points to `Gardeners-log` to be stored. Data points are sent in the same standardized JSON format regardless of which sensor they came from. This is an implementation decision meant to allow for the addition of any number of arbitrary sensors and controls. Doing so made the load a bit heavier for the dashboard service because data needs to be sorted and accounted for, but because there are large extensibility gains and the data is purely textual and relatively light weight it seems to be worth it.

When the user is credentialed, reading logged data is still expected to be the most common operation. Sensor data is sent to the `Gardeners-log` which is sent to dashboard after being asked for by the user. The control is augmented, however, by being able to send messages through `Gardeners-shed` directly to the garden. As an admin user after accessing the garden's dashboard page I have the option of logging into the service. Logging in requires only a username and password. Submitting credentials sends a message to the `Gardeners-shed`, which handles identification and authorization. If the user exists and the password is correct a token is sent back to the dashboard and access is granted. Credentialed access allows the user to view another page that facilitates additional control interfaces. For instance, if the user wants to turn on the water pump manually for some amount of time they can elect to send a command to `Gardeners-shed` that is then relayed to garden's communicator and executed. Sending this message requires only two things aside from using the sending the proper message. First the token value that was received previously after signing in must match one of those that is currently valid and dispatched. Secondly, to prevent sniffing token values, `Gardeners-shed` must also be sent a One Time Password from an authorized two factor authentication key. Ultimately this means, to control the garden you need both a username and password as well as a physical device like a Yubikey to command the garden components. Once `Gardeners-log` verifies that your request is valid it then sends the appropriate request to the communicator, which is then parsed and dispatched to the proper process.

These two roles and the parties that are allowed to communicate maintain a very robust and secure service despite the number of moving parts. In the following sections I will identify how the tools outlined in the previous chapter were used to build the components of Victor's ecosystem and how they can be customized to remain relevant and deliberate for any garden configuration.

### Container-Gardening

![Garden Flow Diagram \label{containers}](source/figures/Gardener.png){ width=30% }

`container-gardening` is the name I have given to the repository for all of the resources and processes to be run on the microcomputer that lives physically connected to the garden.

In the case of my specific test build I have chosen to use three separate boards, each of which are produced and sold by Raspberry Pi. The three microcomputers are the Raspberry Pi 3, Raspberry Pi Zero, and Raspberry Pi 2 rev b.

![Raspberry Pi Model B \label{model_b}](source/figures/modelb.jpg){ width=40% }

![Raspberry Pi Zero \label{zero}](source/figures/zero.jpg){ width=40% }

![Raspberry Pi 3 \label{3}](source/figures/pi3.jpg){ width=40% }

Each board has drastically different cost, I/O limitations, and power requirements. For instance, the Raspberry Pi Zero, a $5 microcomputer, has a power rating of 160ma and a 1 Ghz single core processor, whereas the Raspberry Pi model 3 costs $37.95 for a 1.2 Ghz quad-core processor and an 800ma power rating.

Though the total power usage of the build and the computational power required to host the required sensors will ultimately impact the choice in platform -- there are a small set of requirements. First the garden's computer needs to run some variant of Linux in order to leverage the Docker ecosystem. I have chosen Ubuntu ARM, but any modern Linux OS would reliably and comfortably facilitate using Docker. The chosen board also needs a GPIO interface. A strong majority of sensors sold today interface over GPIO. I2C and SPI communication protocols are relatively efficient, so the total number of external components per board can be much greater than alternatives using input like USB. Second, the board needs some means of networking. At least one board needs access to the internet, but all need some way to communicate over the wire, HTTP, or some other short range mesh networking.

Every sensor that is attached to a garden's computer is liable to interface in a different way; however, in order to exist in the context of Victor they are all handled in a very similar way. First, every component needs to establish a physical hardware connection with its board. In most cases this entail three or four wired connections -- two of which provide power and ground.

Assuming the connection is successful, the sensor needs a program, or "job", to collect measurements and forward them on. Each sensor has its own directory in the `container-gardening` GitHub repository. Sensors are categorized by parameter, and subdivided if two similar measurements are being taken. For instance the directory for the DS18B20 temperature sensor can be found at `container-gardening/temperature/1wire`. There is more than one temperature sensor being used in my build so I chose to designate this particular one by the protocol it uses. This directory houses the code that schedules measurement and any additionally required libraries. Whereas many sensors have provided open-source libraries, some sensors require low-level calibration and communication code. The flow for measurement scheduling is loosely standardized.

Each job is run at predetermined intervals. The job in most cases has three responsibilities. For the components it is responsible for, the job gathers measurements, formats the data into messages digestible by `Gardeners-shed`, and sends the readings to the `Gardener`, the container tasked with handling communication to and from the garden.

The following sample of code gathers temperature data from the DS18B20\. This particular sensor has an API, which we include using `import w1thermsensor`. This sensor's job() function simply iterates through every DS18B20 attached -- there are multiple because this sensor interfaces using the 1wire protocol -- package each measurement into a simple JSON message, and send it along. The job initialization is handled by a library called `schedule`, which is a single-process program level implementation of `cron`. We can configure `schedule` to gather measurements at any desired frequency.

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

Once we have programmed our sensor we can define a Dockerfile to containerize the it. By doing so, we isolate the sensor's dependencies, define a local network by which the containers can communicate, and prevent unwanted access between processes. Each Dockerfile, which defines the process of building the sensor's environment, is defined a directory in the `container-gardening` repository called `dockerfiles`. The directory mirrors the sensor's organization exactly for the sake of simplicity.

This is the Dockerfile that runs and manages the code from the previous example (`container-gardening/dockerfiles/temperature/1wire/Dockerfile`):

```yaml
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

Every Dockerfile begins with a `FROM` directive. This defines the base image that our image will ultimately be built up from. I have chosen `resin/rpi-raspbian:jessie` for the majority of my Raspberry Pi containers. This is a bare-bones version of Raspian, which is a Debian based Linux OS optimized for the Raspberry Pi hardware, it has most of the tools I have needed and for the most part has just worked.

The next three RUN directives define all of the OS and program dependencies necessary to run the program. Here I define which `apt-get install` and `pip install` commands need to be run to provision the container.

The next command clones the entire container-gardening repository to the container. This step is somewhat wasteful because it is very redundant, but I opted to grab the entire repository for simplicity. Some of the sensors have multi-file directories and includes, and I have abstracted some utility functions to their own module. If the number of sensor declarations and resources dramatically hindered storage and build time it might make sense to define the `container-gardening` repository as a collection of sensor submodules.

The `VOLUME` directive defines a directory to be made accessible from the host machine and `WORKDIR` sets the context from which the following `CMD` command should be runs

Lastly, the build process executes the defined `CMD` command which is programmed to run indefinitely.

At this point we could build the container manually and run it, which would begin to show sensor output and send newly acquired entries. One further step is required to include this newly defined container into the Victor framework.

Each machine that exists as a part of the garden's configuration has what is called a `docker-compose.yml` file. Docker-compose is one of the tools provided in the Docker ecosystem for defining and running multi-container applications. We use docker-compose to define which collection programs we want to run on any given machine. (It is assumed that different machines in the garden's configuration will have unique sets of sensors.)

The DS18B20 is hosted on the Raspberry Pi 3 in my build along with a handful of other sensors. The docker-compose.yml file used for the Raspberry Pi 3 provides a canonical name, build instructions, and run parameters for each of these sensors, so that they can be run in conjunction using a single command.

```yaml
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

Each service defined under the services tag defines a separate docker container. In this case the requirements are all very similar. The `temperature` tag defines the name to be given to the container. `build` defines the directory containing the dockerfile associated with this container. `privileged` specifies whether the container needs sudo access. `volumes` declares any volumes to be defined in the dockerfile. The `devices` tag specifies runtime parameters used by the container to interface directly with the hardware. This last tag is especially important in our system, because it gives each container access to its own devices.

The powerful implication of this Docker configuration is that a single command `docker-compose up` issued from within the proper directory builds every defined container and starts collecting data immediately in a secure, manageable way. Furthermore, the containers are ephemeral, so changes can be deployed with ease and downtime can be strongly mitigated because of the speed and ease of start up. Lastly, though each sensor requires a few important pieces, this architecture keeps the deployment of a system nearly identical regardless of the complexity and size of the configuration, which is a massive gain for extensibility.

### Gardeners-log

![Gardeners-log Flow Diagram\label{log}](source/figures/Api.png){ width=30% }

At this point each of the sensors is capable of measuring and reporting data, but we have not defined a location where the data should be sent. `Gardeners-log` is the service that handles the manipulation of data, authentication, and communication between the dashboard and the processes in `container-gardening` . `Gardeners-log` presents a simple RESTful API to its clients, the `Gardener` container and the dashboard. The `Gardeners-log` architecture and security implementations allow for a scalable, protected channel of information transfer.

Victor uses Amazon's serverless architecture to host `Gardeners-log`. This hands off the responsibility of managing, scaling, and provisioning servers to Amazon. I was already maintaining a complex deployment of IOT devices. Minimizing the complexity and cost of the other services helped keep everything manageable. `Gardeners-log` is currently hosted on AWS Lambda, Amazon's serverless platform. Architecturally, `Gardeners-log` is consists of a few of Amazon's cloud services interacting with Lambda's compute platform. The entry point for any application wishing to interact with garden data is an Amazon API Gateway. This gateway is an HTTP listener configured to initiate a certain function correlated to the path used to access it. The gateway also provides an interface for using custom authorizer functions and API key authorization. Behind the API Gateway sit some number of "Lambda functions". Functions are stand alone module exports exposing a single method. Though lambda supports a few languages, I chose to write my functions in Node. The functions used for `Gardeners-log` define CRUD operations for the Garden's database. These functions interact with the last Amazon cloud service involved in this architecture, DynamoDB. The data is light and relatively consistent in shape, so most storage implementations would be suitable, but DynamoDB was an easy choice because it is managed, pretty simple, and exists within the Amazon ecosystem.

The serverless nature of Lambda also makes it cheap to run our services. Though the API Gateway is constantly listening for new requests, the Lambda functions spin up on demand and are metered by ticks of 100ms. In contrast with a service running on standard "always-on" servers, the runtime costs of the `Gardeners-log` RESTful API should be very minor.

As mentioned in the section detailing Flow Control there are two primary users, credentialed and uncredentialed. However, another communicating party is the `Gardener` container hosted on one of the Garden's computers. Unlike, the aforementioned user types, the `Gardener` is not able to navigate through a multi-step authentication process. The data being sent to `Gardeners-log` is the most valuable resource provided by Victor, so naturally I wanted to put some measures in place to preserve data integrity. The API Gateway service has a concept of protected paths with which I implemented relatively simple, secret-based authentication. Through AWS management I created an API key for each of the garden's microcomputers. In the configuration of the POST function (the function used to upload measurements to the database) I designated the function as protected and allowed any of the three keys to authenticate. In the configuration for `docker-compose` I define the keys as environment variables accessible to the job code for each sensor. This way I have a log of which machine accessed the POST method of the API Gateway and the data that it submitted.

Credentialed users may need to update or delete data (using the REST command PUT or DELETE). I was not comfortable with secret-based authentication for administrative operations, so I exposed another set of Lambda functions on separate API Gateway to be used as an authorizer function. When a user requests to authorize to the `Gardeners-log` they are redirected to the Facebook or Google authentication page depending on the user's choice of provider. The authentication page asks the user to grant Victor read access on their account. If the user grants read access, the provider (Facebook or Google) sends an authorization code to the `Gardeners-log`. With this code the `Gardeners-log` sends an authorization request back to the provider and in turn receives an access token.

This flow represents standard OAuth authentication. The authorizer functions of both the PUT and DELETE entry points of the API Gateway are set to the functions just described. This means that any PUT or DELETE request sent to `Gardeners-log` must also pass the authorization function.

After a user authenticates they receive an access token that is in turn sent with every subsequent request. This token is passed to the authorizer. The authorizer constructs and sends a request to the correct provider with the access key. If the access token is valid, the API Gateway will process the request according to its API specifications. If the access token is expired or otherwise invalid, the API Gateway will return an "invalid_request" error. If the authorizer passes successfully then the originally requested operation is performed; otherwise, an error message is returned.

The resulting API is simple, but exposes all necessary operations in a careful manner to preserve security. Creation of data entries is handled by POST requests to `/dev/datum` and authorized via the API keys. Manipulation of data is handled by PUT and DELETE requests to `/dev/datum/{id}` and authorized via the separate serverless Oauth service. Obtaining a list of every entry is handled by a get request to `/dev/datum/` and getting a single entry by a GET request to `/dev/datum/{id}`. Neither of the read requests require authorization, so anyone can view the garden's data. In the following subsection I will outline the construction of one of the serverless functions.

### Gardeners-shed

In many ways `Gardeners-shed` is a component of `Gardeners-log`, however, their functions are quite different. `Gardeners-shed` uses almost the exact same architecture and authorization as `Gardeners-log` except that there is no need for a connection to the cloud hosted DynamoDB. This service, instead of storing and manipulating data, acts as a mediator of messages sent from the user to the Gardener. This service requires only one true endpoint where the front-end service, `Victor`, can post commands.

Messages are sent as simple JSON commands. I have two active components in my garden that respond to user control, both of which are pumps. In the case that I want to turn the fresh water pump on, `Victor` sends `{ 'function': 'turnFreshWaterPumpsOn', 'parameter': '5'}`. This tells the `Gardener` that I want to turn the pump on for five minutes. This is sent as a POST request to `Gardeners-shed`. `Gardeners-shed` looks over the message for the proper parameter values, and it decides to send the message on if it finds them and the user was authenticated.

Then because my home network does not have a dedicated IP address, `Gardeners-shed` does a look up on a dynamic DNS hostname. This hostname resolves to the dynamic IP address of my home address. A script running constantly on a garden machine continually updates the IP with the dynamic DNS provider to ensure connectivity.

If `Gardeners-shed` manages to connect to the IP address it forwards the exact JSON command to the `Gardener` to be vetted and dispatched to the proper controller.

#### Serverless

All of AWS Lambda development was done using a framework named `Serverless`. Each collection of functions is called a service. Every service is contained within its own directory and defined by a file name `serverless.yml`.

The first portion of this file details AWS configuration metadata.

```yaml
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

This snippet defines the language the functions are written in, environment variables and API keys, and identity management configuration for the defined resources.

The next section provides a declaration for each function contained in the service.

```yaml
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

Here I define the create function, which is located at the path `datum/create`. The `events` tag defines the API gateway path that will trigger this function. `integration`, `path`, and `method` declare that it will be triggered by a POST to an API gateway at the path datum. `private` indicates the request will require a key defined in the previous snippet called `DataLogger`. `cors` allows the request to be called by another resource rather than directly by a user.

Finally, a DynamoDB instance is defined in the resources section declaring the database and table that the functions will interact with:

```yaml
resources:
  Resources:
    DataDynamoDBTable:
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

The function itself is a small Node file. (Node was my choice; AWS supports many languages.)

```javascript
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

The file defines an anonymous function that takes the parameters event, context, and callback. These define event data, runtime information of the Lambda function, and a function used to return information to the caller.

This anonymous function takes the data posted in the event's request body and the current time and then constructs an object to be stored in the dynamoDB database defined in the resources section. The function passes a 200 response back to the caller as long as the database call did not error out.

Once every other function is defined `serverless deploy` translates `serverless.yml` to a single AWS CloudFormation template, zips the functions, and publishes a new version for each function in the service.

With its emphasis on extensibility, this architecture allows for a modular, secure, and highly modifiable API that implements and exposes every necessary action safely.

### Victor

![Victor Flow Diagram \label{Victor}](source/figures/Victor.png){ width=30% }  

With `container-gardening` consistently gathering sensor data and `Gardeners-log` providing a means of both storage and access, a single service stands in the way Victor being a transparent and pleasant user experience. Simply named `Victor`, the framework's front end is the view of the application in totality to most users. Though `Victor` the web application, is the simplest component of Victor the framework, it is responsible for presenting a beautiful and useful interface to the user that masks the existence of separate services performing different duties on different machines.

I chose to build this application using Angular, and I have hosted it using GitHub pages. All of the data garden's data is accessible via a single HTTP call, so the application is composed of entirely static resources. This proved incredibly useful because Github pages, though limited to only static pages, is hosted completely for free. Furthermore, any changes made to the page, on the `gh-pages` branch of the repository, are immediately deployed to the site.

`Victor` is a web application with two primary views. When a user makes a request for any page on the site, the base authentication service looks in the request's cookies for an access token. If no token is found, the page request is  redirected to the login page. The login view is relatively bare. The user can choose to login via either Facebook or Google. If they are not interested in authenticating they have the option of accessing a read only view of the garden.

If the request does contain an access token, the user successfully authenticates, or they choose to view the read-only data then they are routed to the garden dashboard view. This view's controller immediately makes a request to `Gardeners-log` to gather the most recent data. The data is received as a large JSON array, which makes manipulation and sorting quick and easy.

From the received array, the controller constructs an object matching each parameter's name to an array of objects representing that parameter's measurements. Each element of the array takes the form `{'value': XX, 'dateCreated': mm/dd/yyyy}`. The view uses an Angular directive `ng-repeat` to iterate through the object of parameters and constructs a time series graph for each.

Though collecting and sorting all of the data adds some complexity to the client-side service, doing so allows for any configuration of sensors. Designation of data is handled via the parameters, and the data representation is agnostic to the choice of parameters. Parameter-specific view configuration can be handled and defined within the controller's view if necessary.

For credentialed users a small icon button is added to the parameters with configuration or manual controls. Clicking the button opens a window with the appropriate inputs and a form mapped to the API endpoint. Submitting the form sends a simple HTTP request in the same exact format as submitting or manipulating data. User's controls are never multi-step, so submission fully hands off responsibility to the `Gardeners-log`. Furthermore, any command that invalidates the controller's current data initializes a subsequent request for a data update. Neither call requires the page to reload, but because of Angular's two way data-binding any change in data is immediately reflected in the view resulting in a near real-time display. If no change occurs on the page, the data is refreshed based on the time since the last call to the API Gateway.

As previously mentioned, this service is very simple, which is largely due to the architecture of the other components. I chose to develop a web application for the widest availability, but there is very little preventing the front end being replaced or duplicated. The data is fully abstracted from the application, so a mobile application, native client, or something more novel like a skill for Amazon's Alexa.
