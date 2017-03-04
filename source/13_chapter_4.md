# Alternate applications

## Introduction

Though I designed the framework around the use case of monitoring and controlling hydroponic gardens, I put a lot of time and care into making the services as extensible as possible.

Internet of things devices already make up a huge portion of all internet connected devices globally. By 2021 IoT is expected to be a $276 billion dollar industry made 16 billion separate interconnected devices. A majority of these devices are, and will be, sensors because IoT is an incredibly efficient, cost-effective means of using analytics to increase productivity and ultimately decrease operating costs.

Though still very young, IoT is facilitating a number of very interesting projects in production environments. Disney, during its renovation of Disney Springs, recently built two five-level parking garages that fully leverage Internet of Things technology. Each parking spot has a small device attached to the ceiling directly above it. The device using a combination of high-power LEDs and a proximity sensor determines whether or not the parking spot is open and illuminates the LEDs so. The devices also passes on the status of their parking spot so the total open spots per row, floor, and garage can be displayed on a number of signs to mitigate congestion and make parking much more efficient and simple.

The city of Barcelona is funding a 90 million dollar project to construct a network of sensors installed throughout the city. As many as 3000 motion detecting street lights with the capability of sensing pollution and humidity have already been installed. Furthermore, they're attempting to install a network of sensors used to gather sound levels to create and urban map of noise pollution. Notably, the project necessitates 1500 WiFi access points that will provide city-wide internet access for free.

The breadth applications is endless, and the number of people with access to start developing is vast because microcomputers are cheap, available, and come with active and helpful communities. However, because of the state of the industry, there are a number of key issues that hinder deployment and development. Victor was designed to solve at least some of these problems, while allowing for a deployment of multiple configurations.

## Standards

In many ways IoT is still in its infancy. As hardware gets smaller and cheaper, the market is being flooded with vendors each of which hope to secure a foothold in the space and lobby to create their ideal standard.

To most the devices themselves are irrelevant, but the real value comes from the way, or ways currently, in which they communicate.

I devised Victor using an opinionated set of standards, but understanding that the industry trends shift constantly, I favored extensibility by completely abstracting communication.

One assumed constant is that communication to and from the API is explicitly HTTP traffic. The API is RESTful meaning its operation depends on HTTP requests to specifically constructed endpoints, so there's little leeway in the communication channels between the services. However, these REST is already a web standard in wide use. Any device capable of speaking HTTP has access to the data.

We give the gardener container on the root garden machine the ability to speak HTTP over the internet, but communication between machines is less solidified.

Communication between containers is abstracted into shared messaging modules. A module handles two separate tasks shared by any data logging application. First, the module is tasked with formatting a measurement. Though the API expects measurements are passed according to a specific JSON schema, the API could mandate an alternate form of transfer and to conform a developer would only need to change the communication module.

Second, the communication module is tasked with sending messages between containers. For the sake of conformity and simplicity, I built the module to send messages in a JSON format over HTTP much like those that will be sent on to the API. An internal network is defined by the docker-compose file, but the channels of communication are pretty straight forward because the messages are coming to and from the gardener container. Though alternate networking technologies are gaining popularity for use in power conscious applications.

The Open Connectivity Foundation, a consortium dedicated to establishing the importance of interoperability it IoT, has consistently pushed for ZigBee's Dotdot as the unifying language of interconnected devices. ZigBee offers a suite of high-level communication protocols, each of which are used to create short range mesh networks with small, low-power digital radios. In the case of relative contained installment, or at least one in which devices can establish line of site with at least one neighbor, ZigBee protocols are beneficial because they use significantly less power and are intended to be cheaper than WiFi alternatives.

The communication module means redesigning the sensor's network is as simple as reimplementing or overriding the send method. ZigBee requires specialized hardware, but the framework is designed to easily adapt to changes like these.

Furthermore the network architecture currently in place is totally agnostic to the protocol used to send messages. The garden's machines are configured in a star network, a topology that works well with both of the aforementioned communication protocols.

## Maintenance

Maintenance is a huge concern with large installations of complex IoT configurations. As billions of devices flood the internet, it's imperative to have some means of automating maintenance. A centralized method of provisioning, deployment, and management is crucial for system administrators

### Organization

Machines on the garden's network are heterogenous by design but not by necessity. Despite a varying number and collection of services, each machines processes are defined in the same way. docker-compose gives a textual representation of the running services. Docker-compose.yml configurations can be consolidated a set collection of builds or tailored specifically to every garden machine, but the format will be identical regardless.

## Closing Thoughts

The sensor network is easily the most extensible part of the framework because in many ways it's the most integral. The API is an opinionated decision that can be substituted with a number of alternate choices. I decided REST was a suitable framework because JSON is relatively human readable as opposed to XML and nearly every internet connected device has the capability of sending JSON data over HTTP, but ultimately the framework needs only a way of storing and retrieving data. We could conceivably include a stand alone database on either the garden network or front-end service. Furthermore, using a web application as the front-end is largely arbitrary. There are a huge number available mediums to display and manipulate data. Mobile or native apps, voice controlled skills via Alexa or Siri, or textual bots implemented within a tool like Slack are all totally viably and arguably more efficient.

These two services can be substituted entirely assuming they provide the same functionality, whereas some physical configuration mush occur in close proximity to the garden, which is one of the main reasons that the API and front-end were delegated to third-part providers.

Victor as a framework provides an ideal platform for facilitating a secure and configurable IoT while limiting the amount of code necessary to make changes. Though a large amount of variability is expected and allowed within the garden's network, the other services limit active management by passing it off to third party providers. The framework is capable of adapting to a great deal of change, and should thrive by acting reliably regardless of the developer's modifications.
