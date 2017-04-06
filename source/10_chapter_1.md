# Processes

## Introduction

The test garden being monitored is a mobile Nutrient Film Technique (NFT) hydroponic garden consisting of four channels each of which are four feet in length. The channels are mounted on a tabletop in a staggered configuration in which the two middle channels are a few inches above the outer ones to regulate temperature and sun exposure. (See Figure X.) A 30 gallon reservoir is affixed on a shelf underneath the channels in which a small pond pump feeds water to the higher end of the channels. On top of the reservoir sits a small water-tight enclosure that houses a Raspberry Pi 3 -- a credit card sized microcomputer. This computer controls a handful of sensors constantly measuring health indicators and pushes the data to cloud hosted database. The operator of the garden can manage the computer by accessing it directly or through a remote provisioning tool. To display the data collected by the garden's computer, or any collection of garden's computers, another cloud hosted site provides a dashboard with real time graphics and analytics that are generated from the most recent data stored in the database.

After the initial setup, by accessing the dashboard site we can gather a quick and comprehensive view of the current state of the garden.

## Hardware

### Sensors

#### Temperature

The build includes three separate sensors that gather measures of temperature -- a sensor each for ambient, reservoir, and channel temperature. The ambient and reservoir temperatures are measured via a waterproofed DS18B20 sensor. The DS18B0 is reasonably accurate and IO efficient.

Using the 1-Wire protocol it's possible to gather separate measurements from multiple, identifiable devices using only a single pin of input.

![The yellow jumper cable in this image is the only wire attached to any input pin. Each other wire deals with supplying power.\label{one_wire_image}](source/figures/one_wire_image.jpg)

This is incredibly beneficial because each of the garden computers can incorporate more devices without the need for a hardware extension that includes additional general-purpose input/output pins. Furthermore, each sensor can be identified programmatically, because each sensor has a unique serial number, which means that a single process can interface with all of the sensors.

One additional sensor is used to measure the temperature inside one of the top-side growing channels. Instead of the DS18B20 the internal channel temperature is measured using an AM2315\. This sensor includes a waterproof housing that includes an identical DS18B20 temperature sensor, a capacitive humidity sensor, and a small microcontroller to provide a simple I2C communication interface. Though interfacing via I2C adds some complexity, having a measure of humidity inside the channels provides insight into the roots' growing conditions as well as propensity for harmful algae blooms.

It is assumed that monitoring of a single channel is sufficient because the channels exist in close proximity; however, barring monetary constraints additional sensors could be added very easily. Adding additional DS18B20's to each of the remaining channels for instance would only require mapping each of their serial ids to their respective locations.

#### Ph

Coupled with temperature, pH is a very descriptive health indicator for a hydroponic garden. I've chosen to use Atlas Scientific's EZO pH circuit and silver electrode pH probe. After the initial calibration this sensor is expected to provide accurate measurements of pH between 0 and 14 for two years. This circuit is capable of communicating asynchronously via serial with the universal asynchronous receiver/transmitter (UART) on the Raspberry Pi. Because communication is handled via serial, the sensor occupies the RX and TX pins on the RaspberryPi 2 rev b.

#### Flow

A flow sensor is attached to the tubing that runs from the pond pump located inside the main reservoir to the entry point of each of the four channels. Although it's unlikely that each of the four entry tubes will be blocked at any given point, any blockage should impact the flow rate because of increased resistance. A sudden, or even gradual, decrease in flow should be a warning sign that urges garden maintainers to check for plumbing issues. The sensor includes a pinwheel with a magnet attached that turns as the water flows through it. A hall effect magnetic sensor on the other side of the plastic tube measures how many spins the pinwheel has made over a certain amount of time. This particular sensor requires only a single pin of digital input to read the pulse output.

#### Wind

An anemometer is included on the table top to gather the wind speed. This measurement is ancillary, but because NFT is a medium-less method of growing plants, windspeed can affect structural health. High wind speed may provide early warning for hazardous conditions allowing the garden's maintainer to provide some sort of cover. The anemometer included in this build provides an analog voltage between 0.4 and 2.0 volts corresponding to a 0 and 32.4m/s wind speed respectively.

The component is designed to interface with microcontrollers primarily. The required voltage is much higher than that which can be comfortably provided by a Raspberry Pi, so an external power source is required. Furthermore, Raspberry Pi's have no onboard analog to digital converter, meaning an external chip had to be included in the circuit.

In this build I decided to use an MCP3008\. The Raspberry Pi, like most other modern microcomputers, is capable of reading 17 digital GPIO pins. As a 5V device, it's able to determine whether input is on (5V) or off (0V). This isn't especially useful when the device outputs voltages between those two values. The MCP3008 provides 8 channels of 10 bit conversion at serviceable precision. This allows for an explicitly digital device to interface with analog inputs like the anemometer.

#### Depth

Routine maintenance of the reservoir is largely unavoidable. Monitoring pH and temperature helps mitigate harmful algae growth and promotes plant growth, but bimonthly water cycling is one of the most efficient ways to maintain a healthy garden. A depth sensor is included in nutrient reservoir to help plan appropriate cycles. The rates of absorption and evaporation can differ depending on the temperature, state of the plumbing, and health of the plants. Once a predetermined amount of water has been expended it's likely a reasonable time to cycle the water. This build uses an eTape liquid level sensor that uses a resistive output that varies depending on immersion to determine depth. The resistive output of the sensor is inversely proportional to the height of the liquid because as more tape is submerged the sensor's resistance decreases. This sensor is also analog, so much like the anemometer it requires a single channel of the external analog to digital converter.

#### Light

A small, cheap visible light sensor was added to determine the amount light reaching the plants each day. Because the table is mobile, it's possible to determine the optimal position for the current crops by monitoring sun exposure. The SI1145 is a small breakout board that measures visible light and IR to approximate UV index. The sensor is digital and communicates via I2C.

## Software

### Angular

Angular is a Javascript framework developed and maintained by Google that is built around the idea that by extending HTML, web application developers can construct modular, declarative components that fit together to build dynamic web pages. Database operations are largely abstracted and the results of any AJAX calls can be bound to, and thus automatically update, the previously constructed, reusable DOM elements. Angular adds the ability to extend HTML and create Directives, which are encapsulations of HTML and client-side Javascript that allow developers to create and reuse custom elements. This leads to declarative markup, and means that reading the HTML alone is usually enough to get a quick idea of an application's purpose. Furthermore, by defining options that can be passed into directives, it's possible to create multiple similar components without an egregious reuse of code.

The web application, aptly called Victor, has two primary functions -- gathering data and displaying data. All of the information is time series data, so displaying the garden's data via graphs is a very repeatable process. This is one way in which I leveraged Angular to create an extensible dashboard to consume garden data.

Loading the dashboard initiates a request to the API that grabs a list of the most recent database entries.

```
$http.get('https://aadrsu3hne.execute-api.us-east-1.amazonaws.com/dev/datum').then(function(data) {
```

This function retrieves an array of entries asynchronously, so the the following `.then()` calls a function to manipulate the data once it is received.

The resulting array is a bag of unsorted measurements from each of the sensors, so I do a bit of manipulation before assigning it to a variable that is visible to the HTML Directives.

```
[{"parameter":"light","createdAt":1491252532082,"value":"352.000",
"id":"f1f4d520-18ae-11e7-b313-5d5b225fc2b6","updatedAt":1491252532082},
{"parameter":"pressure","createdAt":1491252725837,"value":"1013.061",
"id":"65717fd0-18af-11e7-b313-5d5b225fc2b6","updatedAt":1491252725837},
{"parameter":"temperature","createdAt":1491254237495,"value":"29.723",
"id":"ea763470-18b2-11e7-b313-5d5b225fc2b6","updatedAt":1491254237495},
{"parameter":"pressure","createdAt":1491253037765,"value":"1013.145",
"id":"1f5def50-18b0-11e7-b313-5d5b225fc2b6","updatedAt":1491253037765},
{"parameter":"pressure","createdAt":1491253204313,"value":"101477.794",
"id":"82a32490-18b0-11e7-b313-5d5b225fc2b6","updatedAt":1491253204313},
{"parameter":"temperature","createdAt":1491253022715,"value":"30.408",
"id":"16657cb0-18b0-11e7-b313-5d5b225fc2b6","updatedAt":1491253022715},
{"parameter":"depth","createdAt":1491253267173,"value":"2.8",
"id":"a81ad150-18b0-11e7-b313-5d5b225fc2b6","updatedAt":1491253267173},
{"parameter":"Luminosity","createdAt":1491253948475,"value":"2",
"id":"3e3140b0-18b2-11e7-b313-5d5b225fc2b6","updatedAt":1491253948475},
{"parameter":"depth","createdAt":1491252841556,"value":"2.6",
"id":"aa6ad140-18af-11e7-b313-5d5b225fc2b6","updatedAt":1491252841556},
```

Each of these entries is transformed into key value pairs of the form `{"value": XXX, "date": XXX}` and collected into separate arrays for each measurement. Now this collection of parameters and their massaged values are assigned to a $Scope variable, another Angular construct that makes the data visible and modifiable via the HTML, so that I'm able to cycle through and create a data dashboard programmatically.

```
<div class="dash-page">
 <div class="dash col-md-12" ng-controller="DashboardController as ctrl">
  <div class="row" ng-repeat='row in ctrl.charts | groupBy:2'>
    <div ng-repeat="item in row" class="col-md-6">
      <chart data="item.data"
        options="item"
        ng-if="item.data"
        convert-date-field="{{date}}">
      </chart>
    </div>
  </div>
 </div>
</div>
```

This small snippet of code is able to create a full dashboard of approximately eight time series graphs featuring real-time, updatable data.

`ng-repeat='row in ctrl.charts | groupBy:2` cycles through every element in the previously created object of measurement arrays by groups of two. Then, while looping through each group of two, I'm able to create a row of two charts by using the `<chart>` directive to render `metrics-graphics` time series charts. Under the hood, the `<chart>` directive is constructing an object consisting of the necessary Javascript and HTML to create and render a chart with the given parameters, but this is abstracted to make the HTML page's components encapsulated and expressive. Modification of the data exposed by `item.data` through the web page is reflected in the Javascript and updates to the data in the Javascript are made visible immediately by the HTML, which is called two-way databinding.

![\label{Victor}](source/figures/victorweb.png)

Though this is a small example of the benefit provided by using Angular as the underlying structure of the application, it demonstrates two of the key mechanisms that made Angular an appealing option.

The web framework space is heavily flooded and also incredibly opinionated. My main criteria were that I wanted a structure that was both pluggable and maintainable, meaning I wanted every file to encapsulate only one module of logic, I needed the act of updating previously stored data to be transparent and fast, and I wanted a framework that was well maintained.

During my research I was immediately confident that Angular would provide a stable base considering the fact that it's backed by Google and has over 50,000 stars on GitHub; however, Angular's directives and two-way data binding are what drove me to ultimately believe Angular would work well within the structure I had devised for Victor.

### REST

Victor is a built using the basic principles of service oriented architecture, which is a style of software design where self-contained modules of functionality are composed and interconnected. The framework consists of a composition of three services, namely Victor, Gardners-log, and Container-gardening, each of which have a single function.

In the previous section I showed how through a top-level, front-end service, Angular helps load and display all of the data collected from the garden. However, in order to view and manipulate data, the front-end service needs to gather information in a parseable format. Historically, the dashboard and garden would have been heavily coupled. As hardware components collected measurements they would write them to a relational or flat file database, which the dashboard would then use to gather and display information. Also, any commands to be executed by user input would likely entail direct access of the data collection process.

This monolithic architectural style presented a few problems. In order to access the data you need to be able to access the machine running the program, know the format of data storage, and have a direct connection to the data. Furthermore, when any portion breaks or is scheduled to be updated or modified then then entire application goes down. Lastly, gaining access through the use of any vulnerability present in the application opens the door to any and all other services involved, which means that if you find a client-side vulnerability in the user-facing dashboard then you likely have full access to the data collection process.

Each of these issues is serious, but by implementing a service based application I was able to mitigate some of these operational issues.

The central, facilitating service of Victor's composition is the service called `Gardners-log`. This service consists of a cloud hosted database, a list of functions that read and update that database, and listener service that sits waiting for users requests to initiate one of those functions. `Gardeners-log` provides a RESTful API that the other services can interact with to create and consume data. An API, or Application Programming Interface, is a list of functions and a designation of how they can be executed and with what parameters. What makes an API RESTful is that a RESTful API provides interoperability between web based services by allowing requesting services to access and manipulate textual representations of data using a uniform and predefined set of stateless HTTP based operations.

In terms of technology, this means a database hosted in the cloud sits behind a small bit of marshalling code that reads and writes JSON represented garden measurements based on standard HTTP requests it receives. For instance, if the API receives a POST request a function is initiated that grabs the data in the body of the HTTP POST and writes that data to the database. If it receives a GET request a function queries the database records and responds with a textual representation of what it found.

This service is incredibly valuable because it makes Victor much more robust, secure, and accessible. For instance, the data coming from my garden is valuable and should be made available to any number of clients to read. In the future I may want to create different an application that reads data from gardens that exist all over the country and compare their yield based on weather and other health indicators. It could also be the case that I want to create a native application that can send updates straight to my desktop. By creating an API using standard RESTful practices the clients that intend to read in my data don't need any previous knowledge aside from the URL of where it resides to access it. All modern, interconnected devices speak HTTP, meaning clients can be entirely heterogenous.

Furthermore, I want it to simple to be able to digest the data in a standardized way so that future applications are able to easily manipulate it. Data is sent using JSON. The entire service is textual, so transmission is efficient and cheap. Parsing though the raw data is not computationally expensive, and because JSON is a standard form of representation, constructing data structures in any native language should be straight forward.

#### Security Implications

Because the API is a stand-alone service it is important to consider access controls and the flow of control. Anyone with the resources and interest should have access to view the data, but it should be secure and protect against unauthorized writes. For this reason, GET requests are largely left unattended. Aside, from overwhelming the server, these types of requests are not much of a threat because the marshalling code does not rely on any input from the user. Any POSTs or RPC style calls need to be credentialed access.

The design consideration was that the database would need some means of keeping track of users that were authorized. This could be handled simply enough by constructing a table of users and hashed passwords, but after logging in a user should not immediately need to authenticate to issue another request. Instead I opted to implement a token style authentication. Completely transparent to the user, on login the dashboard checks in with the API in an attempt to authorize. In the case that authentication is successful, the API issues a token that is valid for a customizable amount of time. This way the system is still secure, but not at the cost of the user experience.

Taken one step further, the dashboard and API allow for the control of a few features that could be very destructive to the connected gardens. For these functions two factor-authentication is required.

I also felt it was necessary that the data should stand alone and act as the single point of contact that connects the garden network to the greater internet. As the most valuable resource, the data should be siloed and kept segmented from any other means of control. Hosting the API on a virtual machine provider allows for firewalls, load balancing, and monitoring that I wouldn't have access to on my own. Furthermore, by only accepting controls from this single machine, I can easily dismiss a large portion of invalid commands issued to garden machines.

### Python

Victor as a framework is meant to be explicitly language agnostic. Data is transferred using very standard RESTful web services meaning the lone requirement for a program to successfully submit data to the API is that it must be able to construct a valid HTTP request. Though this leaves a vast number of capable options I gravitated strongly toward Python for code that is directly interfacing with the sensors.

Python facilitates really rapid development, many of the sensors in this build have far reaching community support and open-source libraries written in Python, and lastly RPi.GPIO is shipped with Raspian, the RaspberryPi foundations Linux distribution. This module provides a direct interface to the boards General Purpose Input/Output pins. Each and every external component interfaces through these pins, so opting to use Python almost exclusively helped keep provisioning and deployment as simple as possible.

## Methodology

### DevOps

DevOps is a methodology and framework built around the idea that developers aren't able to create and ship code as fast as users want to see meaningful updates.

The practice is generally focused on the idea that teams of Software Engineers and teams of information-technology (IT) professionals should not be so inherently separate during the process of building and shipping technology.

Obviously as a single person team this emphasis on communication and cooperation becomes less important, but abstracting and adopting the practice of continually testing, integrating, and deploying keeps code cohesive and allows for much faster development.

By building the infrastructure from the ground up we can automate how our projects build, test every single change, and deploy only when nothing breaks. Meaning, we can both spend more time developing than solving infrastructural problems and also develop quickly and iteratively.

One of the major principles of DevOps that I adopted right away is Continuous Integration. By connecting one of the various CI services directly to our repository we can discover real bugs as soon as they're checked in.

A watcher keeps an eye on our repositories looking for a commit. Once it sees one a hook triggers a build. Using a provided build script that we include in our project the service builds the new push and runs your suite of tests. The status of the build can then be seen on the dashboard, emailed to you as a notification, or displayed in the projects README.

Taken one step further, we can then decide that for any given commit that passes our suite of tests we will package and generate a new version of the project and automatically deploy it to providers like Heroku, AWS, and Digital Ocean. This ensures that any pushed change that does not break other functionality can be immediately an continuously deployed.

## Docker

Every sensor is controlled by a single, separate Python script. Most of the scripts share at least some code including a collection of utility methods for timing and reporting findings I wrote, however, they each have very separate dependencies. Some require specific hardware-level systems packages, whereas others might only need a tagged version of a Python library hosted on Github. It's expected that every component has a unique set of dependencies and it's assumed that many of these will conflict. Furthermore, the scripts are also separate in their access roles. A single process is expected to be able to communicate outside of my home network, and all of the sensor's programs are expected to be able to communicate amongst each other. Likewise, only a single process, the same program that is able to send messages outside of the home network, should be reachable via the internet. That same program should be able to send messages to the other sensor running scripts.

I chose Docker as the primary tool to handle sensor's code deployment, separation, and management. Docker is a technology and framework built around developing, building, and deploying applications inside of software containers. Containers are a virtualization technique in which and application and its dependencies are packaged in isolated processed. Like standard virtual machines, Docker containers ensure that I can customize and specify all of the dependencies at the user level. This solves the dependency collision issues because each container has its own unique and unshared user space. Containers are initialized and provisioned via a scripted Dockerfile, which means that environments are consistent and shareable. Similarly, Docker containers, like the code that they host, work well with version control.

However, unlike virtual machines, containers are very light weight. Once built, a process that generally takes a few minutes depending on internet speed, a container generally starts within seconds. Whereas, each virtual machine is a full operating system with both memory management and virtual devices, Docker containers attempt to save space and resources by sharing a kernel and systems level libraries. This cuts overhead significantly, but decreases the true separation. Containers don't have a full systems level separation like virtual machines, which leaves them somewhat susceptible to breakout attacks. However, Docker containers by default are comfortably secure, and with proper configuration -- namely, not running available processes as root -- the risk of containers is much, much lower than the risk of stand alone processes.

Beyond the security and isolation benefits, containers make the victor framework incredibly scalable. Adding a sensor to the deployment takes three steps -- two of which can be largely automated. The first step is to write the code to interface with the sensor. The file can reside anywhere, but the organization is standardized by storing the file in a directory named after the parameter it Measures. To run in it's own separate container the sensor's code needs a defined Dockerfile. The Dockerfiles used in this project are very similar, so much of the declaration can be reused. Dependencies unique to the sensor's code need to be defined. Lastly, an entry is added to the a DockerCompose YAML file. A DockerCompose file is declared for each deployment. Each machine can host a different configuration of sensors. To keep builds customizable the DockerCompose file defines build instructions, runtime parameters, and names for each sensor container to be run on any given machine. Once defined, start up on any give deployment is as simple as docker-compose up. The configuration in the compose file handles all networking, storage, and environment management.
