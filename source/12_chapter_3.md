# Security

## Introduction

Victor's primary valuable resource is the data read from each of the attached sensors. Without maintaining the integrity of the data, the framework provides very little benefit to any of its users.

For the sake of building a comprehensive model of Victor's priorities, strengths, and weakness I assume there exists some malevolent attacker with the sole intent of causing as much harm to the system as possible with all of the resources necessary to do so.

As I've mentioned previously the data gathered from any and all gardens should be fully available. Localized data is important to the maintainers, but open data provides a sample size large enough for deriving correlations, which may facilitate increased yields and help build stronger configurations.

For this reason, though data's access has no reason to be protected, its integrity and availability, however, are absolute necessary.

### Trust

The three services that Victor is comprised of are made up of very different technologies, as noted in the previous two chapters, and the have similarly different boundaries of trust.

The garden's computers live in a self-contained subnet. A firewall sits at the entry point of the network and allows only properly formed messages through. For this reason there's an expectation of trust between garden devices. Messages sent among internal entities have an assumed integrity, but the construction and format of the messages are still standardized. Messages to the gardener container are trusted if they are signed by the API.

The API trusts messages sent by both the gardener container and authenticated users. Messages sent from the gardener are standardized and must be of the expected format. A request from the garden must also contain a secret API key that matches the one defined for the respective API's endpoint. Messages from the front end are trusted if the can pass the OAuth authentication check. After a user goes through authenticating through either Facebook or Google, they're give an access key which be passed with every request. Changes to the API are pushed only by a authenticated user with the proper role-based access.

The front-end puts it's trust in the API to pass properly formed and fully vetted data. Changes to the front-end are propagated through Github.

### Data Flows and Entry Points

The gardener container hosted on one of the garden machines sends newly gathered measurements and receives commands from the API. No other data is expected to transfer during normal operation. However, in the case of management and deployment, the garden machines expect remote access by a credentialed admin user.

The garden thus expects connections via port 80 and 443 for standard HTTP and SSL respectively as well as port 22 for remote deployment via docker-compose and management over SSH.

The API sends and receives requests to the garden. All data transferred is textual and represented through a standardized JSON-based format. Deployment of new developments and changes is handled via Serverless using the AWS CLI or through the Amazon Web Services management portal.

The API expects requests over both port 80 and 443 for HTTP and SSL.

The front-end sends requests and receives data from the API. Any message that the user wishes to be received by the garden needs to be accepted by the API and forwarded appropriately.

The front-end expects requests over both port 80 and 443 for HTTP and SSL.

### Threats

In regards to integrity, an attacker has two primary vectors each of which are ultimately directed at the API -- submission of new data through the entry point used by garden entities and modification of data through the entry points used by a credentialed user.

Trying to gain the access required to create data an attacker may try to use the exact machines sending valid measurements. For instance they could attempt to gain physical access to the garden's computers. Whether physically or remotely, they could try to breach the network on which the garden in hosted to send properly crafted messages between the network of microcomputers. Alternatively, they could bypass the sender completely, and attempt to send a message directly to the API.

Using the second vector, an attacker may try to manipulate the front-end in an attempt to gain access to privileged functions like manipulation of data, deletion of data, and component control.

Likewise, they could bypass the application and authentication entirely and send a request directly to the API in hopes that it performs some specific action.

For any of the services, a user could attempt to forcefully break authentication. Gaining access to the API administrator would allow the attacker to create endpoints to either the front-end or garden that would appear totally valid to the other services. Bypassing SSH authentication to the garden would give an attacker direct access to the API key and faux integrity needed to craft data creation calls deemed acceptable by the API. Similarly, bypassing OAuth authentication on the front-end allows an attacker to modify any and all data as well as send commands through the API to the garden.

Considering availability, there are two points at which the attacker could hinder the services availability, which are the channels of communication between the API and the other two services. Disruption of communication between the API and the garden has two compromising implications. First, the user no longer has access to the most recent data because the garden cannot send messages to the API. The messages will be sent once the connection is resumed, but the latency can be an issue. Secondly, any configuration and control that needs to be sent to the garden won't make it. Both of these issues can severe in time-sensitive applications. The second channel, between the API and front-end, creates similar, but slightly different issues. In this case the user wont be able to view any data through the application despite the fact that the data would likely be complete and recent. The user will also be unable to send messages to the garden, but in this case they'll have little indication of success or failure.

## Key Vulnerabilities

Considering the most blatant avenues of attack, the service has a few vulnerabilities that are most critical.

Authentication and proper session management is absolutely key. Gaining unauthorized access to any of the services, but especially the API, is highly damaging. It's absolutely critical that passwords are strong and two-factor authentication is used where possible. Sessions should require sane re-authentication and confirmation.

Network security of the garden is a weakness of the service. No unnecessary services should be running on any of the garden's machines. Only the single machine hosting the gardener container should be network facing. The firewall should have stringent checks and fail closed. The goal should ultimately be to harden the machines to the greatest extent possible using all modern best practices.

Data received by the API and sent and received within the network should be checked and sanitized. If somehow a message was able to bypass the step of authentication, the API and garden machines should sanitize it in hopes of limiting its potential damage.

Likewise, the front-end controls should be checked and sanitized to prevent any unnecessary web vulnerabilities, like cross-site scripting or request forgery, to eliminate the tools an attacker has to elevate privileges.

## Security Mechanisms

To prevent as many of the previously stated vulnerabilities as possible I've put in place security mechanisms to keep Victor as safe as possible while still being extensible, powerful, and user friendly.

### Physical

### Network

### API

### Authentication
