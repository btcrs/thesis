# Alternate applications

## Introduction

Though I designed the framework around the use case of monitoring and controlling hydroponic gardens, I put a lot of time and care into making the services as extensible as possible.

Internet of things devices already make up a huge portion of all internet connected devices globally. By 2021 IoT is expected to be a 2.9 trillion dollar industry made 20 billion separate interconnected devices [^fn18][@van_der_meulen_gartner_nodate-1]. A majority of these devices are, and will be, sensors because IoT is an incredibly efficient, cost-effective means of using analytics to increase productivity and ultimately decrease operating costs.

Though still very young, IoT is facilitating a number of very interesting projects in production environments. Disney, during its renovation of Disney Springs, recently built two five-level parking garages that fully leverage Internet of Things technology. Each parking spot has a small device attached to the ceiling directly above it. The device using a combination of high-power LEDs and a proximity sensor determines whether or not the parking spot is open and illuminates the LEDs if so. The devices also passes on the status of their parking spot so the total open spots per row, floor, and garage can be displayed on a number of signs to mitigate congestion and make parking much more efficient and simple.[^fn19][@magic_look_nodate]

The city of Barcelona is funding a 90 million dollar project to construct a network of sensors installed throughout the city. As many as 3000 motion detecting street lights with the capability of sensing pollution and humidity have already been installed. Furthermore, they are attempting to install a network of sensors used to gather sound levels to create and urban map of noise pollution. Notably, the project necessitates 1500 WiFi access points that will provide city-wide internet access for free. [^fn20][@adler_how_nodate]

The breadth applications is endless, and the number of people with access to start developing is vast because microcomputers are cheap, available, and come with active and helpful communities. However, because of the state of the industry, there are a number of key issues that hinder deployment and development. Victor was designed to solve at least some of these problems, while allowing for a deployment of multiple configurations.

## Standards

In many ways IoT is still in its infancy. As hardware gets smaller and cheaper, the market is being flooded with vendors each of which hope to secure a foothold in the space and lobby to create their ideal standard.

To most the devices themselves are irrelevant, but the real value comes from the way, or ways currently, in which they communicate.

I devised Victor using an opinionated set of standards, but understanding that the industry trends shift constantly, I favored extensibility by completely abstracting communication.

One assumed constant is that communication to and from the `Gardeners-log` is explicitly HTTP traffic. The API provided by `Gardeners-log` is RESTful meaning its operation depends on HTTP requests to specifically constructed endpoints, so there is little leeway in the communication channels between the services. However, these REST is already a web standard in wide use. Any device capable of speaking HTTP has access to the data.

We give the Gardener container on the root garden machine the ability to speak HTTP over the internet, but communication between machines is less solidified.

Communication between containers is abstracted into shared messaging modules. A module handles two separate tasks shared by any data logging application. First, the module is tasked with formatting a measurement. Though the API functions expect measurements are passed according to a specific JSON schema, `Gardeners-log` could mandate an alternate form of transfer and to conform a developer would only need to change the communication module.

Second, the communication module is tasked with sending messages between containers. For the sake of conformity and simplicity, I built the module to send messages in a JSON format over HTTP much like those that will be sent on to `Gardeners-log`. An internal network is defined by the docker-compose file, but the channels of communication are pretty straight forward because the messages are coming to and from the Gardener container. Though alternate networking technologies are gaining popularity for use in power conscious applications.

The Open Connectivity Foundation, a consortium dedicated to establishing the importance of interoperability it IoT, has consistently pushed for ZigBee's Dotdot as the unifying language of interconnected devices. ZigBee offers a suite of high-level communication protocols, each of which are used to create short range mesh networks with small, low-power digital radios. In the case of relative contained installment, or at least one in which devices can establish line of site with at least one neighbor, ZigBee protocols are beneficial because they use significantly less power and are intended to be cheaper than WiFi alternatives.

The communication module means redesigning the sensor's network is as simple as reimplementing or overriding the send method. ZigBee requires specialized hardware, but the framework is designed to easily adapt to the software changes necessary to leverage the hardware changes.

Furthermore the network architecture currently in place is totally agnostic to the protocol used to send messages. The garden's machines are configured in a star network in which one centralized point in the network delegates a majority of the communication, a topology that works well with both of the aforementioned communication protocols.

## Maintenance

Maintenance is a huge concern with large installations of complex IoT configurations. As billions of devices flood the internet, it is imperative to have some means of automating maintenance. A centralized method of provisioning, deployment, and management is crucial for system administrators

Maintenance of a machine can be further separated into two separate sub-categories, maintenance of the OS and maintenance of the processes it is running. I have leveraged three tools to keep Victor as maintainable as possible in order to promote extensibility and scalability.

The first two, `cron-apt` and `iptables configured with fail2ban` were mentioned in the previous chapter. None of the machines require a very extensive list of running services, so a majority of the OS maintenance is required for security. Regular updates and a firewall that can adapt to new threats handles 90% of regular OS maintenance. Most importantly, however, the machines need a sturdy stable connection to both their network and their external components.

Each container is capable of determining the state of its sensor. Though runtime errors can occur for a number of reasons, the calls to the the sensors fail in an explicitly verbose way. If the measurement method fails the script does not stop. Instead a message is sent to the Gardener with a declaration of the failure. The Gardener is tasked with parsing the message and determining what to do. I have chosen to send a simple email with the sensor's status, but this can be tailored to use whatever method the maintainer finds most convenient like a text, slack message, or push notification.

The connection status of the device is a bit harder to determine. For instance, a device measuring temperature and humidity could lose connection to garden's network. If this machine configuration was unique it may be possible to determine simple because of a lack of temperature and humidity measurements, but its highly possible this is a commonly used configuration in the network. Though I have not been able to implement this in a production setting, one way I have been working to solve this issue is with docker-swarm, another service provided by the third tool Docker. Docker-swarm allows me to cluster each of the separate garden machines around a central manager. Each of the nodes, every connected machine, is then capable of running a predefined service, much like docker-compose services. It is possible then to define a service for every duplicated configuration and run them simultaneously on each of the nodes responsible for that action. In doing so we create a network of N managers, where N is the number of garden configurations, and Y nodes, where Y is the number of machines utilizing that configuration for each node respectively. Swarm implements a consensus algorithm, Raft, by which the group is capable of surviving (N-1)/2 manager losses, where N is the current number of managers. This modified architecture would allow Victor to maintain a consistent internal state of the entire swarm and all the services running on it

Regardless of future direction, Docker is already facilitating huge gains in scalability and continuos integration. Firstly, the amount of downtime in the garden system is incredibly low. In the case of failure, loss of power, or standard reboot the containers are set to restart automatically. In the case of unexpected stoppage the Docker daemon attempts to restart the container until it succeeds. If restarting continues to fail the daemon keeps trying to start the container using an incremental back-off algorithm. The garden architecture is fault tolerant, so regardless of the number of sensors a maintainer chooses to interface with, a single-failure will not compromise a deployment.

Second, the use of docker-compose promotes constant development and modification. Changes made to the `container-gardening` service can be propagated quickly and unobtrusively. With a version of a configuration already running, a maintainer can remotely build the entire new set of Docker container that make up the compose file on the target machine, run each one of them, and shut down the previous version. This set up provides a three command deployment process that takes minutes to build and causes no downtime.

### Organization

Machines on the garden's network are heterogenous by design but not by necessity. Despite a varying number and collection of services, each machine's processes are defined in exactly the same way. Each machine's docker-compose.yml file is a textual representation of its running services. Docker-compose.yml configurations can be consolidated a set collection of builds or tailored specifically to every garden machine, but the format will be identical regardless.

The organization of the fleet is defined by the organization at the system level. In the pursuit of quick development, easy deployment, and clean devices, none of the Raspberry Pis are required to directly host the code that will ultimately run on them.

Garden code is self-contained within a single directory and is comprised of scripts to interface with sensors, Dockerfiles to containerize the scripts, and Docker-compose files to automate the process of maintaining configurations.

The top level directory contains three directories used to separate these three. The Dockerfiles and sensor program directories are fully mirrored. Sensor code is separated by the parameter being measured. If multiple sensors are being used to measure the same parameter then they are each given their own directory within parameter's directory named after the sensor in contention. The Docker-compose files are separated into their own separate directories named by machine configuration and contain services named that match their code's repository name. Each of the services reference the relative path to the Dockerfile that matches their name.

The well-defined organization has a few strategic extensibility gains. First, adding a component is incredibly straight-forward because the three necessary steps are highlighted by the directories contained within the top level directory. The configuration of existing machines can change very rapidly. Adding a service to a configuration is a small amount of change -- especially if the sensor's code and Dockerfile has already been written. Lastly, this configuration allows for totally remote deployment. All of the path references are relative, so the docker-compose file can be run remotely. As I mentioned in the `implementation` chapter, the Dockerfiles each pull the entire `container-gardening` repository. Though this is wasteful, it keeps the organization and deployment incredibly simple.

## Service Based Architecture

The sensor network is easily the most extensible part of the framework because in many ways it is the most integral. However, implementing a service based architecture allows for redundancy or change at the service level.

The Amazon Lambda hosted API is an opinionated decision that can be substituted with a number of alternate choices. I decided REST was a suitable framework because JSON is relatively human readable compared to XML and nearly every internet connected device has the capability of sending JSON data over HTTP, but ultimately the framework needs only a way of storing and retrieving data. We could conceivably include a stand alone database on either the garden network or front-end service.

Furthermore, using a web application as the front-end is largely arbitrary. There are a huge number available mediums to display and manipulate data. Mobile or native apps, voice controlled skills via Alexa or Siri, or textual bots implemented within a tool like Slack are all totally viably and arguably more efficient.

These two services can be substituted entirely assuming they provide the same functionality, whereas the garden's configuration is largely tied to its physical implementation, which is one of the main reasons that `Gardeners-log`, `Gardeners-shed`, and `Victor` were delegated to third-party providers.

Victor as a framework provides an ideal platform for facilitating a secure and configurable IoT while limiting the amount of code necessary to make changes. Though a large amount of variability is expected and allowed within the garden's network, the other services limit active management by passing it off to third party providers. The framework is capable of adapting to a great deal of change, and should thrive by acting reliably regardless of the developer's modifications.

## Closing Thoughts

The IoT ecosystem is likely to mature drastically in the next few years. The desire for a fully standardized market is unlikely, but as the market share consolidates it appears it may converge on a common means of communication and discovery. Victor was developed to adapt and conform to standardization as a model of how an ecosystem can be situated to provide necessary features without stagnating the growth of deployment.

The organization and tooling that Victor is able to offer through secure, quick, and emerging technologies like Docker allows for constant development and deployment. Provisioning new devices is seamless, and the architecture of the application is cost-efficient and capable of scaling to as many or few devices as necessary.

The design provides a lot of value for networked, data acquisition focused deployments of IoT hardware.

[^fn18]: http://www.gartner.com/newsroom/id/3598917
[^fn19]: http://www.wdwmagic.com/attractions/disney-springs/news/17may2016-photos---a-look-at-the-new-lime-parking-garage-at-disney-springs.htm
[^fn20]: http://datasmart.ash.harvard.edu/news/article/how-smart-city-barcelona-brought-the-internet-of-things-to-life-789
