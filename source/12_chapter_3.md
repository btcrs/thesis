# Security

## Introduction

Victor's primary valuable resource is the data read from each of the attached sensors. Without maintaining the integrity of the data, the framework provides very little benefit to any of its users.

For the sake of building a comprehensive model of Victor's priorities, strengths, and weakness I assume there exists some malevolent attacker with the sole intent of causing as much harm to the system as possible with all of the resources necessary to do so.

As I've mentioned previously the data gathered from any and all gardens should be fully available. Localized data is important to the maintainers, but open data provides a sample size large enough for deriving correlations, which may facilitate increased yields and help build stronger configurations.

For this reason, though data's access has no reason to be protected, its integrity and availability, however, are absolute necessary. In regards to integrity, an attacker has two primary vectors each of which are ultimately directed at the API -- submission of new data through the entry point used by garden entities and modification of data through the entry points used by a credentialed user.

Trying to gain the access required to create data an attacker may try to use the exact machines sending valid measurements. For instance they could attempt to gain physical access to the garden's computers. Whether physically or remotely, they could try to breach the network on which the garden in hosted to send properly crafted messages between the network of microcomputers. Alternatively, they could bypass the sender completely, and attempt to send a message directly to the API.

Using the second vector, an attacker may try to manipulate the front-end in an attempt to gain access to privileged functions like manipulation of data, deletion of data, and component control.

Likewise, they could bypass the application and authentication entirely and send a request directly to the API in hopes that it performs some specific action.

## Method

Abstracted from it's actual implementation, Victor provides a few core security implementations

### Physical

### Network

### API

### Authentication
