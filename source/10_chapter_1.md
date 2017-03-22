# Processes

## Introduction

The test garden being monitored is a mobile Nutrient Film Technique (NFT) hydroponic garden consisting of four channels each of which are four feet in length. The channels are mounted on a tabletop in a staggered configuration in which the two middle channels are a few inches above the outer ones to regulate temperature and sun exposure. (See Figure X.) A 30 gallon reservoir is affixed on a shelf underneath the channels in which a small pond pump feeds water to the higher end of the channels. On top of the reservoir sits a small water-tight enclosure that houses a Raspberry Pi 3 -- a credit card sized microcomputer. This computer controls a handful of sensors constantly measuring health indicators and pushes the data to cloud hosted database. The operator of the garden can manage the computer by accessing it directly or through a remote provisioning tool. To display the data collected by the garden's computer, or any collection of garden's computers, another cloud hosted site provides a dashboard with real time graphics and analytics that are generated from the most recent data stored in the database.

After the initial setup, by accessing the dashboard site we can gather a quick and comprehensive view of the current state of the garden.

## Hardware

### Sensors

#### Temperature

The build includes three separate sensors that gather measures of temperature -- a sensor each for ambient, reservoir, and channel temperature. The ambient and reservoir temperatures are measured via a waterproofed DS18B20 sensor. The DS18B0 is reasonably accurate and IO efficient.

Using the 1-Wire protocol it's possible to gather separate measurements from multiple, identifiable devices using only a single pin of input. (See Figure Y.) This is incredibly beneficial because each of the garden computers can incorporate more devices without the need for a hardware extension that includes additional general-purpose input/output pins. Furthermore, each sensor can be identified programmatically, because each sensor has a unique serial number, which means that a single  process can interface with all of the sensors.

One additional sensor is used to measure the temperature inside one of the top-side growing channels. Instead of the DS18B20 the internal channel temperature is measured using an AM2315\. This sensor includes a waterproof housing that includes an identical DS18B20 temperature sensor, a capacitive humidity sensor, and a small microcontroller to provide a simple I2C communication interface. Though interfacing via I2C adds some complexity, having a measure of humidity inside the channels provides insight into the roots' growing conditions as well as propensity for harmful algae blooms.

It is assumed that monitoring of a single channel is sufficient because the channels exist in close proximity; however without monetary constraints additional sensors could be added very easily. Adding additional DS18B20's to each of the remaining channels for instance would only require mapping each of the serial numbers to their respective locations.

#### Ph

Coupled with temperature, pH is a very descriptive health indicator for a hydroponic garden. I've chosen to use Atlas Scientific's EZO pH circuit and silver electrode pH probe. After the initial calibration this sensor is expected to provide accurate measurements of pH between 0 and 14 for two years. This circuit is capable of communicating asynchronously via serial with the universal asynchronous receiver/transmitter (UART) on the Raspberry Pi. Because communication is handled via serial, the sensor occupies the RX and TX pins on the RaspberryPi.

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

Angular is a javascript framework developed and maintained by Google that is built on the idea that by extending HTML, web application developers can construct modular, declarative components that fit together to build dynamic web pages. Database operations are largely abstracted and the results of any AJAX calls can be bound to, and thus automatically update, any of the previously constructed, reusable DOM elements. 

[This is a very dense paragraph that calls for illustratuve examples or a figure. What's an example of a reusable DOM element you use that has AJAX call results bound to it, that abstracts away CRUD, and how is it implemented in a declarative way that is modular?]

The web framework space is heavily flooded and also incredibly opinionated. My main criteria were that I wanted a structure that was both pluggable and maintainable, meaning I wanted every file to encapsulate only one module of logic, I needed the act of updating previously stored data to be transparent and fast, and I wanted a framework that was well maintained.

During my research I was immediately confident that Angular would provide a stable base considering the fact that it's backed by Google and has over 50,000 stars on GitHub; however, Angular's directives and two-way data binding are what drove me to ultimately believe Angular would work well within the structure I had devised for Victor.

[OK, I'll bite. What's a directive, and what's two-way binding, and where do you use it?]

As I mentioner earlier, Angular puts a lot of emphasis on the ability to extend HTML to create Directives, which are encapsulations of HTML and client-side javascript that allow developers to create and reuse custom elements. This leads to declarative markup, and means that simply by reading the HTML tags you can get a quick idea of what components do. Furthermore, by defining options that can be passed into directives, it's possible to create multiple similar components without an egregious reuse of code.

[OK, now it get it better. This should go in the first paragraph.]

### REST

Victor is a hierarchically organized project composed of a few small services. 

This isn't clear: (is it your initial design?)

We started at a top-level, front-end service, which, to a user, provides all of the project's functionality. However, in order to view and manipulate data, the dashboard service needs to gather information in a parseable format. Historically, the dashboard and garden might be heavily coupled. As hardware components collected measurements they would write them to a relational or flat file database, which the dashboard would then use to gather and display information. Also, any commands to be executed by user input would likely entail direct access of the data collection process.

This presents [presented?] a few problems. In order to access the data you have to be accessing the machine running the program, know the format of data storage, and have a direct connection to the data that utilizes a retrieval method suitable for that format. Furthermore, if anything breaks or is scheduled to be updated or modified then everything goes down. Lastly, gaining access through the use of any vulnerability present in the application opens the door to any and all other services involved, which means that if you find a client-side vulnerability in the user-facing dashboard then you likely have full access to the data collection process.

This isn't a good thing. [Which "this"?]  Instead we can follow micro-service methodology [What's that? Reference?] and implement a back-end api. In terms of technology, this is simply a database hosted in the cloud with a small bit of marshalling code that can read and write standard HTTP requests. Based on what is received the code either queries or submits data to the database and returns a textual representation of what it did.

This unattached service, however, is incredibly valuable in that it makes our applications much more robust, secure, and accessible. For instance, the data coming from my garden is valuable and should be made available to any number of clients to read. In the future I may want to create different an application that reads data from gardens that exist all over the country and compare their yield based on weather and other health indicators. It could also be the case that I want to create a native application that can send updates straight to my desktop. By creating an API using standard RESTful practices the clients that intend to read in my data don't need any previous knowledge aside from the URL of where it resides to access it. All modern, interconnected devices speak HTTP, meaning clients can be entirely heterogenous.

Furthermore, I want to be able to digest the data in a standardized way so that I can create applications down the line that manipulate it. Data is sent using JSON, so transfers are declarative and very efficient. Parsing though the raw data is not computationally expensive, so constructing data structures in any native language should be wonderfully simple.

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

Every sensor is controlled by a single script. Though most of the scripts share at least some code, I wrote a few utility methods for timing and reporting findings that are imported by nearly every sensor, they each have very separate dependencies. Some require specific hardware-level systems packages, whereas others might only need a tagged version of a Python library hosted on Github. It's expected that every component has a unique set of dependencies and it's assumed that many of these will conflict. Furthermore, the scripts are also separate in their access roles. A single process is expected to be able to communicate outside of my home network, and all of the sensor's programs are expected to be able to communicate amongst each other. Likewise, only a single process, the same program that is able to send messages outside of the home network, should be reachable via the internet. That same program should be able to send messages to the other sensor running scripts.

I chose Docker as the primary tool to handle sensor's code deployment, separation, and management. Docker is a technology and framework built around developing, building, and deploying applications inside of software containers. Containers are a virtualization technique in which and application and its dependencies are packaged in isolated processed. Like standard virtual machines, Docker containers ensure that I can customize and specify all of the dependencies at the user level. This solves the dependency collision issues because each container has its own unique and unshared user space. Containers are initialized and provisioned via a scripted Dockerfile, which means that environments are consistent and shareable. Similarly, Docker containers, like the code that they host, work well with version control.

However, unlike virtual machines, containers are very light weight. Once built, a process that generally takes a few minutes depending on internet speed, a container generally starts within seconds. Whereas, each virtual machine is a full operating system with both memory management and virtual devices, Docker containers attempt to save space and resources by sharing a kernel and systems level libraries. This cuts overhead significantly, but decreases the true separation. Containers don't have a full systems level separation like virtual machines, which leaves them somewhat susceptible to breakout attacks. However, Docker containers by default are comfortably secure, and with proper configuration -- namely, not running available processes as root -- the risk of containers is much, much lower than the risk of stand alone processes.

Beyond the security and isolation benefits, containers make the victor framework incredibly scalable. Adding a sensor to the deployment takes three steps -- two of which can be largely automated. The first step is to write the code to interface with the sensor. The file can reside anywhere, but the organization is standardized by storing the file in a directory named after the parameter it Measures. To run in it's own separate container the sensor's code needs a defined Dockerfile. The Dockerfiles used in this project are very similar, so much of the declaration can be reused. Dependencies unique to the sensor's code need to be defined. Lastly, an entry is added to the a DockerCompose YAML file. A DockerCompose file is declared for each deployment. Each machine can host a different configuration of sensors. To keep builds customizable the DockerCompose file defines build instructions, runtime parameters, and names for each sensor container to be run on any given machine. Once defined, start up on any give deployment is as simple as docker-compose up. The configuration in the compose file handles all networking, storage, and environment management.
