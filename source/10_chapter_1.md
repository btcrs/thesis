# Processes

## Introduction

The test garden being monitored
is a NFT hydroponic garden consisting of four channels each of which are four feet in length.
The channels are mounted on a tabletop in a staggered configuration in which the to middle channels
are a few inches above the outer ones to regulate temperature and sun exposure. A 30 gallon reservoir
is affixed on shelf underneath the channels in which a small pond pump feeds water to the higher
end of the channels. On top of the reservoir sits a small water-tight enclosure that houses a
Raspberry Pi 3 -- a credit card sized microcomputer. This device controls a handful of sensors
constantly measuring health indicators and pushing the data to cloud hosted database. This device
can be managed either by accessing the device directly or through a remote provisioning tool.
To display the data collected by the garden's computer, or any collection of garden's computers, another
cloud hosted site provides a dashboard with real time graphics and analytics that are generated from the
most recent data stored in the database.

Thus, after the initial setup by accessing the dashboard site we can gather a a quick and
comprehensive view of the current state of the garden.

## Hardware

### Sensors

#### Temperature
####  Ph
####  Flow
####  Depth
####  Wind
####  Light

## Software

### Angular

### REST

Victor is a hierarchically organized project composed of a few small services.
We started at a top-level, front-end service, which, to a user, provides all of
the project's functionality. However, in order to view and manipulate data,
the dashboard service needs to gather information in a parseable format.
Historically, the dashboard and garden might be heavily coupled. As hardware
components collected measurements they would write them to a relational or flat
file database, which the dashboard would then use to gather and display information.
Also, any commands to be executed by user input would likely entail direct access
of the data collection process.

This presents a few problems. In order to access the data you have to be on the
machine running the program, know the format of data storage, and have a direct
connection to the data that utilizes a retrieval method suitable for that format.
Furthermore, if anything breaks or is scheduled to be updated or modified then everything goes down.
Lastly, gaining access through the use of any vulnerability present in the application
opens the door to any and all other services involved, which means that if you find
a client-side vulnerability in the user-facing dashboard then you likely have full
access to the data collection process.

This isn't a good thing. Instead we can follow micro-service methodology and implement
a back-end api. In terms of technology, this is simply a database hosted in the cloud
with a small bit of marshalling code that can read and write standard HTTP requests.
Based on what is received the code either queries or submits data to the database and
returns a textual representation of what it did.

This unattached service, however, is incredibly valuable in that it makes our applications
much more robust, secure, and accessible. For instance, the data coming from my garden is
valuable and should be made available to any number of clients to read. In the future I may
want to create different an application that reads data from gardens that exist all over the
country and compare their yield based on weather and other health indicators. It could also be
the case that I want to create a native application that can send updates straight to my
desktop. By creating an API using standard RESTful practices the clients that intend to read
in my data don't need any previous knowledge aside from the URL of where it resides to access
it. All modern, interconnected devices speak HTTP, meaning clients can be entirely heterogenous.

Furthermore, I want to be able to digest the data in a standardized way so that I can
create applications down the line that manipulate it. Data is sent using JSON, so transfers are
declarative and very efficient. Parsing though the raw data is not computationally expensive, so
constructing data structures in any native language should be wonderfully simple.

##### Security Implications

Because the API is a stand alone service it is important to consider access controls and the flow
of control. Anyone with the resources and interest should have access to view the data, but
it should be secure and protect against unauthorized writes. For this reason, GET requests
are largely left unattended. Aside, from overwhelming the server, these types of requests are not
much of a threat because the marshalling code does not rely on any input from the user. Any POSTs or
RPC style calls need to be credentialed access.

The design consideration was that the database would need some means of keeping track of users that
were authorized. This could be handled simply enough by constructing a table of users and hashed passwords,
but after logging in a user should not immediately need to authenticate to issue another request. Instead
I opted to implement a token style authentication. Completely transparent to the user, on login the dashboard
checks in with the API in an attempt to authorize. In the case that authentication is successful, the API issues
a token that is valid for a customizable amount of time. This way the system is still secure, but not at the cost
of the user experience.

Taken one step further, the dashboard and API allow for the control of a few features that could
be very destructive to the connected gardens. For these functions two factor-authentication is required.

I also felt it was necessary that the data should stand alone and act as the single point of contact that connects the garden network to the greater internet. As the most valuable resource, the data should be siloed and
kept segmented from any other means of control. Hosting the API on a virtual machine provider allows for firewalls,
load balancing, and monitoring that I wouldn't have access to on my own. Furthermore, by only accepting controls from
this single machine, I can easily dismiss a large portion of invalid commands issued to garden machines.

### Python
#### GPIO

## Methodology

### DevOps

DevOps is a methodology and framework built around the idea that developers aren't
able to create and ship code as fast as users want to see meaningful updates.

The practice is generally focused on the idea that teams of Software Engineers and teams
of information-technology (IT) professionals should not be so inherently separate during the process
of building and shipping technology.

Obviously as a single person team this emphasis on communication and cooperation becomes less
important, but abstracting and adopting the practice of continually testing, integrating, and deploying
keeps code cohesive and allows for much faster development.

By building the infrastructure from the ground up we can automate how our projects build,
test every single change, and deploy only when nothing breaks. Meaning, we can both spend
 more time developing than solving infrastructural problems and also develop quickly and iteratively.

One of the major principles of DevOps that I adopted right away is Continuous Integration.
By connecting one of the various CI services directly to our repository we can discover
real bugs as soon as they're checked in.

A watcher keeps an eye on our repositories looking for a commit. Once it sees one a hook
triggers a build. Using a provided build script that we include in our project the service
builds the new push and runs your suite of tests. The status of the build can then be
seen on the dashboard, emailed to you as a notification, or displayed in the projects
README.

Taken one step further, we can then decide that for any given commit that passes our
suite of tests we will package and generate a new version of the project and automatically
deploy it to providers like Heroku, AWS, and Digital Ocean. This ensures that any pushed
change that does not break other functionality can be immediately an continuously deployed.

### Testing
