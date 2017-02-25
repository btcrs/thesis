# Implementation

## Introduction

In this chapter I will first outline the flow of information through Victor's services in it's most general use case. Then, working from the bottom up, I'll detail the implementation process including how working parts of the services are tied together and how each of the three services, the garden, the api, and the dashboard, interact.

## Flow Control

Victor uses a role based access control system in which only two types of users are considered to exist. The vast majority of users that might access the application are uncredentialed, outside users. This group makes up person who wishes to view the data, but has not been given access to make any changes. These users will almost always be accessing the site remotely, meaning requests to the dashboard will not come from the same network that the garden is connected to. The other group is much smaller and is made up of garden maintainers who want to and have the access to make changes to the garden remotely. These credentialed admin users have access to all of the same functions as the outside users; however, once their access has been properly vetted, they gain the additional power of manipulating data via PUT and DELETE requests to the API and issuing commands to be evaluated by the garden machines.

As a outside user, the benefits made available by Victor are in consuming data about the garden's environment. Outside user's can use this a point of reference or comparison for their own gardens, so they want an easy way to consume recent relevant data. To do this the user must access the URL of the dashboard. Though no means of collaboration is included in the framework, access to the dashboard is made available through the projects Github repository. Upon accessing the main page, the dashboard service immediately realizes that the user's request is unauthorized, so a call to the API is necessary to identify roles. The The API seeing a request coming from the user, knows that read requests from an uncredentialed user are allowed, so it gathers the most recent set of data from the garden and sends it back as a JSON object to the dashboard. Once the dashboard gets the data it cleans it and constructs the appropriate graphs and widgets. Knowing that more relevant data is saved and stored with the API service every few minutes, the dashboard makes sure the check back in periodically to maintain relevance.

An outside user has no direct communication with the garden network itself, but rather the data that is sent from the garden's sensors is summoned and displayed by the dashboard on request. Communication between the garden and the API occurs only through one head device. The garden can be constructed using any number of machines, but communication is limited to being sent and received by a single elected proxy. Each machine that is a member of the garden's network hosts sensors contained by Docker containers. These contained processes continuously, generally based on a time increment though there is no enforced standard, take measurements about the garden environment and relay them to garden's head communicator device. The communicator maintains a service for relaying data points to the API to be stored. Data points are sent in the same manner regardless of which sensor they came from. This is a implementation decision meant to allow for the addition of any number of arbitrary sensors and controls. Doing so made the load a bit heavier for the dashboard service because data needs to be sorted and accounted for, but because there are large extensibility gains and the data is purely textual and relatively light weight it seems to be worth it.

As a credentialed user this is still the most commonly used flow of data. Sensor data is sent to the API which is sent to dashboard after being asked for by the user. The control is augmented, however, by being able to send messages through the api directly to the garden. As an admin user after accessing the garden's dashboard page I have the option of logging into the service. Logging in requires only a username and password. Submitting credentials sends a message to the api, which handles identification and authorization. If the user exists and the password is correct a token is sent back to the dashboard and access is granted. credentialed access allows the user to view another page that facilitates additional control interfaces. For instance, if the user wants to turn on the water pump manually for some amount of time they can elect to send a command to the API that is then relayed to garden's communicator and executed. Sending this message requires only two things aside from using the dashboards UI to send the proper message. First the token value that was received previously after signing in must match one of those that is currently valid and dispatched. Secondly, to prevent sniffing token values, the API must also be sent a One Time Password from an authorized two factor authentication key. Ultimately this means, to control the garden you need both a username and password as well as a physical device like a Yubikey to command the garden components. Once the API verifies that your request is valid it then sends the appropriate request to the communicator, which is then parsed and dispatched to the proper process.

These two roles and the parties that are allowed to communicate maintain a very robust and secure service despite the number of moving parts. In the following sections I'll identify how the tools outlined in the previous chapter were used to build the components of Victor's ecosystem and how they can be customized to remain relevant and deliberate for any garden configuration.

### Container-Gardening

Container-Gardening is the name I've given to the repository for all of the resources and processes to be run on the microcomputer that lives physically connected to the garden.

In the case of my specific test build I've chosen to use three separate boards, each of which are produced and sold by RaspberryPi. The three microcomputers are the RaspberryPi 3, RaspberryPi Zero, and RaspberryPi 2 rev b. Each board has drastically different cost, IO limitations, and power requirements. For instance, the RaspberryPi Zero, a $5 microcomputer, has a power rating of 160ma and a 1Ghz single core processor, whereas the RaspberryPi model 3 costs $37.95 for a 1.2Ghz quad-core processor and an 800ma power rating.

![Model B \label{model_b}](source/figures/modelb.jpg){ width=50% }

![Zero \label{zero}](source/figures/zero.jpg){ width=50% }

![3 \label{3}](source/figures/pi3.jpg){ width=50% }

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
