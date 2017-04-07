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

To prevent as many of the previously stated vulnerabilities as possible I've put in place security mechanisms to keep Victor as safe while remaining extensible, powerful, and user friendly.

### Physical

Physical security is ultimately a deterrent rather than a means to an end. It's possible to interface with the Raspberry Pi machines over both ethernet and usb, so protecting access to these ports is important. Furthermore, the filesystem is contained on a single SD card, so access to the card is a means of gaining access to potentially damaging information.

In total there are three primary implemented means of protecting the devices from an attacker with physical access keeping appropriate hardware in a secured enclosure, removing unnecessary ports, and securing the SD card.

An enclosure is a necessary component of the build because the garden is outside at most times. It's possible to grow indoors with the proper lighting, but, even then, an enclosure protects the electronics from possible leaks. Though the enclosure is primarily in place as protection from the elements, adding a simple lock is an easily implemented first line of defense. The enclosure is fully acrylic, however, so a motivated attacker would have little problem gaining access to the devices.

With the device in hand, an attackers first step would be attempting to gain local access over USB or ethernet. Though, we may require these ports for wireless adapters, not all of the ports are likely to be in use. Unused ports can easily be desoldered and removed. Used ports can be coated in epoxy making their connections semi-permanent and interfacing using these vectors **much** more annoying for an attacker. Lastly, the SD card contains all of the data necessary to send messages to the proper API endpoint, so some means of obfuscation and protection was necessary. Encryption of the entire filesystem is the most secure way of solving this issue, but it can be problematic in the case of power failure because an authorized user may not be around to enter the decryption key for every device on reboot. Not to mention the fact that in a large-deployment this could be a huge waste of time. For Victor's purposes the creation of data is not a large enough concern to risk the increase in device management, so we can handle the SD card much like actively in use port. Coating the SD card reader in epoxy is enough to create a semi-permanent connection which likely offers enough of a discouragement to possible attacker. There's always the chance of desoldering the entire reader and physically connecting it to another device, but this is a risk I was willing to take.

### Network

The garden was in close proximity to my home wifi network, so I connected a small portable router to use as a separate access point. All garden devices connected to this router allowing me to create and manage a protected subnet. Only one device was allowed access in and out of the network. This machine hosted the gardener container used to send and receive messages to the API. Though the gardener machine has some additional measures, each Raspberry Pi was hardened by the following actions.

-Every machine's username and password were changed from their defaults.

Though this step seems trivial, the number of microcomputers with unchanged credentials that are accessible over the internet it unnerving.

-All unused services were shut off

Raspberry Pi's OS comes default with a handful of unnecessary running services. None of my devices require FTP, Apache, or SQL to run properly. Furthermore, any service they do need will be running inside of a Docker container.

-Machines are kept regularly updated.

One of the easiest ways to keep the OS and necessary services secure is by updating them regularly. To cut down on maintenance requirements this is handled with `cron-apt` a tool used to automatically update packages at regular time intervals.

The main gardener machine also included the following two measures because of its increased responsibilities.

-The machine used to communicate with the API needs comprehensive logging.

The gardener machine has the largest SD card at a whopping 64 Gigabytes, so it handles pretty extensive logging. Standard Debian logging keeps track of log ins and failed attempts.

-Protect against unwanted packets with a firewall.

Iptables is is a standard firewall included in most Linux distributions that allows for user-defined configuration of the tables provided by the Linux kernel firewall. The configuration I've used is pretty simple, but it allows me to define the ports and networks from which I allow communication. A huge benefit of the firewall is that it allows me to drop any packet that's not sent to the expected ports -- 80, 443, and 22\. Furthermore, a third party tool Fail2ban runs on the Raspberry Pi and monitors the logs and autonomously modifies the iptables rules to ban any IPs that appear malicious. Too many password failures or inappropriate snooping are circumstances that can be configured as a means for ban.

### API

One of the benefits of using a serverless architecture hosted with cloud services is that, I'm not responsible for hardening any of the servers that my API will ultimately run on. I do, however, need to properly manage authentication to the endpoints I want protected. The two mechanisms that I used to protect the endpoints were Amazon authorizers and API keys.

API keys aren't inherently a great form of security because they relies on a single secret shared between the main garden device in the API, but because the garden's network and devices are secured well they provide a cost effective and simple means of decent protection. The key is created and stored within the Amazon Management Portal and set as an environmental variable on the main garden machine. Every request sent to the API from the garden contains the key in it's headers. Though I'm confident about the API key's role in this particular build, future applications may wish to utilize IOT frameworks, like AWS Greengrass or AT&T's M2X, for management, deployment and security.

When a request is sent to an Amazon API Gateway it first checks to determine whether or not any custom authorizers are associated with the lambda function it's trying to access. If one exists the gateway grabs the authorizer token in the request and forwards it to the authorizer. The API implements a OAuth authentication via Lambda so functions protected via the authorizer are perfectly secure assuming a valid OAuth configuration and barring any breach of Google or Facebook.

In terms of availability, AWS Lambda is infinitely scalable. The service is ultimately reliant on Amazon, but because the code is spun up directly in response to the requests it receives its infrastructure is as large as the number of people or entities trying to access it. Furthermore, the servers owned by Amazon capable of running Victor's functions are spread geographically. The risk of company wide outage or denial of service is slim compared to alternatives.

### Authentication

Authentication, in my opinion, is the largest element of risk that exists in the framework. Authentication to any of the management services is immediately damaging, and yet I only have control of the garden's management. To some extent I have to put trust in the fact that I've vetted the services that I've chosen to use, but I also need to ensure the use of best practices where I have the control to do so.

As I mentioned in the network section, each of the Raspberry Pis have a defined set of credentials used to authenticate over SSH. The passwords are all sufficiently long and randomized. Though, theoretically, they could be broken using brute force, it would be prohibitively expensive both computationally and financially.

The front-end utilizes the best practices for using the OAuth authentication protocol. In this case the provider, Facebook and Google, set the username and password requirements, so I can be pretty confident in the strength of credentials. Furthermore, both of these services are continually adopting two-factor authentication, which is ideal for authenticating to make credentialed API calls. The custom Lambda authorizer upon receiving a success response from the chosen provider sends the access token protected in the request's body. The token is stored in a cookie on the user's machine and used in subsequent requests that require the key. Secure coding on the front-end helps protect against a remote attacker gaining access to or using another user's token. After a predetermined amount of time the token is invalidated and the user is required to authenticate once again.

### Closing Thoughts

The security of the system is a balance of strength and convenience. The resources and actions made available to the user vary in both value and vulnerability. Extra measures of security are put in place both where value is stored and where it won't impact the user's perception of the tool. Furthermore, security is handed off to providers when I felt that they would reliably provide a deliberately secure and well-maintained service, which keeps the operator's duties relatively low. At a significantly greater cost to the owner of the system it would be absolutely possible to implement a much more secure framework, but I think that considering the overall risk of breach, the mechanisms put in place allow for a perfectly secure environment.
