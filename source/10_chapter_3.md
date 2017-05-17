# Security

## Introduction

The most important part of Victor is its data. Victor makes it easy to collect more data and new types of data. It also lets users view data as the composite of a few visually pleasing graphs rather than a wall of text. Getting an overview of the garden's health is quick even with a huge amount of data. Yet none of this functionality is important without the data itself.

For this reason, it is very important to me that the data is accurate and current. When I open Victor's web application I expect to see graphs that represent the state of the garden. Wrong data or a lack of data means Victor is not providing value and could be causing harm.

For instance, what if the water depth graph shows that the reservoir is close to full while it is empty or emptying? In this case, Victor is not providing any value and is very explicitly causing harm by misleading me. Opening the app to see no data at all is still bad, but less dangerous. A lack of data could arise from a simpler hardware failure or software bug, but it could also point to some attacker gaining access to the Gardeners-log service or blocking the web application and the database's communication. In any case, this lack of data availability is much quicker to spot and diagnose.

When I see a healthy reservoir depth I expect to be reading accurate measurements from a sensor that is still online. This expectation is important to keep the framework useful and accountable. Though, I do not believe it is something that I can take for granted.

There are two things that could keep Victor's data from being available and accurate. Either the system could fail or someone, or something, could attack it. There is always some risk of the system failing. Hardware is bound to fail because electronics do not fend well outdoors, and software always needs maintenance. I built the framework to be resilient, which I detailed in the previous chapter. One of the ways I accomplished this, however, was by making routine maintenance easier. These sorts of failures are unpreventable but detectable. Hardware failure, for instance, is much more likely to report unrealistic or no data than it is to show believable, fake data. The latter issue is a bit more unnerving, but should be largely preventable. In this chapter, I will discuss the ways an attacker could abuse Victor's services and use the system to compromise the data's accuracy and availability. I will then outline how I weighed the difficulty and potential damage of these attacks while deciding where to focus the frameworks defense and the mechanisms currently put in place to protect the system.

### Who is the Attacker

The simplest definition of "the attacker" is anyone who attempts to use Victor in an unintended, malicious way. Though short and simple, this definition implies a great deal of difficulty in identifying any single attacker. First, this concept of "the attacker" emphasizes intentionality over concrete actions. A wide variety of things, notably fame, boredom, and financial gain, can motivate cyber attacks. Determining possible outcomes of an attack can help identify likely motivations. Second, there are many more unintended, malicious actions than intended ones. Since I developed the framework I am immediately disadvantaged. I have a very clear, but limited, perspective of Victor's services and how they communicate. An attacker's view is much more fluid. They should not have a very clear understanding of the framework, but they are only limited by their imaginations.

Thinking about who are we protecting the system against is always valuable. It helps identify what exactly we are protecting and what is necessary to protect it. Finding a good answer is difficult because there is almost never one attacker. Victor is likely to elicit some interest from a small subsection of all possible attackers. Though I cannot identify a single attacker, I can try to predict the most likely types of attackers. By doing so I can also start to determine the most common ways attackers will try to abuse Victor's services.

In most cases, categories of attackers can be defined using two variables, motivation and resources. Motivation in this context defines the amount of effort an attacker would commit to my garden's network specifically. Resources include the tooling, experience, personnel, and time available to that attacker.

The most dangerous and most difficult to protect against are the attackers that are highly motivated with a large pool of resources. This group includes nation states and organized, professional rings of hackers. Any garden network, including mine, would be invisible to these sorts of attackers unless it feeds a huge number of people or is integral to generating large amounts of money.

Attackers with little or no motivation and only moderate resources are more plentiful. Novice hackers find or write scripts to find possible targets. These programs wander the open internet looking for machines exposing services, such as a Raspberry Pi running SSH. Then they spend a small amount of time trying to execute a novel attack or guess the password before moving on to the next target. Their motivation is low, but their resources are more plentiful than one would expect. Tools to automate mindless attacks like these are widely available and free. Many automated bots scan the internet in the same way novice hackers do. They look for vulnerable devices that they are confident they can compromise. These vulnerable devices help grow a network of infected machines used to serve ads or perform DDoS attacks. Their motivation is even lower than novice hackers because they are looking for a very specific signature. However, they have the benefit of running perpetually and autonomously. I expect that a very strong majority of attackers interested in Victor would be in this group of attackers. Because of this, most of my defensive measures are to protect against simplistic, automated attacks.

The rest are in place to guard against the smaller group of possible attackers that have slightly greater motivation. By committing more time and effort to learning about Victor itself these attackers could conceivably construct a more elaborate attack using the framework's data flow and the communication between services. These scenarios are the most likely to compromise the data accuracy.

I expect the types of attackers, their motivations, and the tools they have available to differ. As I work through the possible attacks and how I worked to prevent them throughout the rest of this chapter I will include a quick synopsis of expected attacker type at the beginning of each section.

### Trust

The four services that comprise Victor are all very different. They each use very different technologies to provide separate, complementary functionality. For the services to work together transparently, they need to be able to communicate.

Transferring data in Victor requires HTTP communication between each component. Luckily, the messages, senders, and receivers are all very predictable. For instance, the web application is never supposed send messages directly to the garden network. We can expect that any message received by the garden and sent from the web application is malicious.

Using the expected flow of communication, I have defined trust relationships between the services. These relationships define what messages the framework expects, trusts, and needs to function. Using that list, I am able to deny any messages that do not fit the expected characteristics.

The garden's computers live in a self-contained subnetwork of my home network. A firewall sits at the entry point of the garden network as a first line of defense. The rules in this firewall deny internet connections to the Raspberry Pis that are not running the Gardener container.

Communication to and from the Gardener is only expected to be with the Gardeners-shed and Gardeners-log. Both services are built on a serverless architecture, so it is not expected to use the same IP address more than once. Amazon Lambda, the serverless hosting service, does not have a set list of addresses that it uses. Amazon owns and publishes a list of their IP addresses, but this list is liable to change at any point.

These reasons make implementing a IP address whitelist error prone. A whitelist would deny any messages sent by an IP address that is not on the list. This would cut down a lot of malicious automated traffic, but in this case it introduces maintenance complexity.

Instead, to be trusted, messages from Amazon need to be signed by the Amazon API Gateway that manages Gardeners-shed's requests. To sign a request, the Gateway first forms the request. Then it generates a string to use as input for a cryptographic hash function. The signature is then created using this string and a secret derived key created using a series of hash-based message authentication codes.

This signature is then verified on the Garden's end. Messages that contain a valid signature are trusted, but the contents are treated as being potentially dangerous.

The Gardener container first reads the message to make sure it is safe and then forwards it. Messages sent within the garden network are all expected to be trustworthy because the Gardener container is looking out for the rest of the machines and containers in garden. The construction and format of the messages are still standardized, so spotting issues in the logs is straightforward.

The Gardeners-log trusts messages sent by both the Gardener container and web application's authenticated users. Messages sent from the Gardener are standardized and must be in an expected format. A request from the garden must also contain a secret API key that matches the one defined by the API's endpoint. Messages from the web application are trusted if they can pass the OAuth authentication check. After a user goes through the process of authenticating with either Facebook or Google, they are given an access key to include in every request.

The web application's expectations are the simplest. It asks for data from the Gardeners-log, so it trusts that the data that it receives is in the right format and vetted data. The Gardeners-log is not expected to do a lot of data processing, so the web application is expected to check it over quickly before reflecting it directly to the web page.

### How Is the Data Sent

In the previous section I defined which services are expected to communicate. I defined some high-level ways to confirm the sender of the message and when the contents of message should be treated cautiously.

Now I will detail exactly why and how the messages are sent from and received by the services.

The Gardener container sends measurements to and receives commands from the Gardeners-log and Gardeners-shed respectively. Victor uses HTTP as a standard protocol for communication. The garden allows connections over port 80 and port 443 for outgoing HTTP and incoming HTTPS, a secure version of HTTP, requests.

Each Raspberry Pi, including the one hosting the Gardener, also expects communication over port 22\. The Pis use port 22 for SSH which is used for both remote deployment via docker-compose and standard management over SSH. Port 22, 80, and 443 are the only externally facing allowed ports. Internally, machines send HTTP messages between each other containing new measurements and commands on port 8000.

Gardeners-shed sends commands to and Gardeners-log receives data from the garden. It also receives requests for data from the web application service. All data transferred is textual and is represented through a standardized JSON-based format.

The `Gardeners-log` and `Gardeners-shed` expect requests over both port 80 and 443 for HTTP and HTTPS. Standard HTTP is used for most requests to the Amazon API gateway that are asking for data. Consumption of data is both non-confidential and is meant to be available to any user. HTTP in this case is allowed so that the data is available to as many users as possible.

HTTPS is used for any request that will create, delete, or manipulate data on Gardeners-log. The use of HTTPS when authenticating and performing authenticated requests, like deletion or configuration, is crucial. In this case, using encrypted messages prevents an attacker from gaining unauthorized access to credentialed actions because it protects the tokens that authorize these actions.

The front-end sends commands to and receives data from the Gardeners-log. Any message that the user wants to send to the garden is mediated by the Gardeners-shed. I limit the number of possible senders to simplify the process of defending the communication.

The front-end expects requests over both port 80 and 443 for HTTP and HTTPS. For this build I chose to use GitHub Pages, GitHub's free hosting service, because it is free and very easy to manage. Ideally, the service would default to HTTPS, but GitHub Pages does not allow this configuration. Instead messages and commands are sent in a protected way programmatically.

### Threats

I have now defined clear expectations for how Victor's services are meant to interact. Using these expectations I will begin to consider the ways in which an attacker might try to access the data or prevent others from accessing it.

There are two main ways an attacker could modify the data to make it inaccurate. Both of these have the primary goal of tricking Gardeners-log into trusting the faulty message. The attacker in these scenarios would be motivated to attack my garden specifically because these attacks require a good amount of knowledge and time.

First an attacker could pretend to be part of the garden network and send fake measurements to Gardeners-log.

To send messages to `Gardeners-log` the attacker would either need to steal the API key used to validate the Gardener container's messages and then send fake updates to the database, or they would need to gain access to the garden's network and send messages to the Gardener container, which would be forwarded and trusted by Gardeners-log.

Getting into the garden's network could include either physically accessing one of the Raspberry Pis and modifying the code or trying to access the garden's subnetwork with their own device and pretending to be a new garden machine.

Alternatively, an attacker could try to send messages from the web application to modify or delete the data already stored in the Gardeners-log. If the attacker were able to make authenticated requests they could also send dangerous commands to the garden.

If they were unable to authenticate through the web application, they could also try to send requests directly to the `Gardeners-log` and hope that their credentials were not checked there.

There are also two places in Victor's data flow that an attacker could keep a user from being able to access the data. The attacker in these scenarios would be much less motivated. In fact, the garden would not even need to be the primary target. The attacker would most likely be a bot or a large network of bots called a botnet.

The two places where data could be prevented from making it to the user are between the garden's network and the Gardeners-log and between Gardeners-shed service and the web application.

Blocking communication between the Gardeners-log and the garden prevents a user from viewing data and issuing commands.

If the Gardeners-log or garden network are overloaded with junk traffic, they will not be able to communicate. The user no longer has access to the most recent data because the garden cannot send messages to `Gardeners-log`. The messages will be sent once the connection is resumed, but the latency can be an issue. Any configuration or control messages that need to be sent to the garden will not make it. Both of these issues can be severe in time-sensitive applications, like a rapidly dropping reservoir.

Blocking communication between the Gardeners-shed and web application causes slightly different issues. The user will not be able to view any data through the web application even though the data would likely be complete and recent. The user will also be unable to send messages to the garden. In a dire situation, the maintainer of the garden would have to access the Raspberry Pis directly over SSH.

Lastly, each service includes some form of authentication, so they are all susceptible to a brute force attack. If any attacker found the credentials to one of the services they would be able to upload their own code, which could contain backdoors allowing them to perform any action they wanted, or invoke unauthorized actions.

Discovering the credentials of the either of the Amazon AWS hosted service's administrator would allow the attacker to create their own API endpoints to perform any action. Bypassing a garden machine's SSH authentication would give the attacker direct access to the API key allowing them to create fake data. Circumventing OAuth authentication on the web application service would allow the attacker to modify and delete data and send commands through `Gardeners-shed` to the garden.

These three scenarios show that bypassing or breaking authentication on any of the services allows an attacker to easily manipulate the data, so protecting against these sorts of attacks is an important part of keeping the data accurate.

## What Needs Secured

Implementing secure authentication and proper session management is absolutely key. Gaining unauthorized access to any of the services, but especially the database, is highly damaging. It is critical that passwords are strong and two-factor authentication is used where possible. When a user authenticates with the web application, their session should not last forever. Instead, they should be required to confirm their session or reauthenticate periodically.

The security of the garden's network is a weakness of the framework. No unnecessary services should be running on any of the garden's machines. Only the single machine hosting the Gardener container should be able to access the internet. The firewall should only allow messages through if they are expected and should fail closed. Failing closed, as opposed to open, means that if some received packet makes it through the machine's list firewall rules without being accepted or denied, then it should be denied by default rather than allowed through. The goal should ultimately be to harden the machines to the greatest extent possible using all modern best practices.

Data received by Gardeners-log and sent and received within the network should be checked and sanitized. To protect against the situation in which a message is able to bypass the authentication of the web application service and the identification of the Gardeners-log service, Gardeners-log and garden machines should sanitize it to limit its potential damage.

Likewise, the web application's controls should be checked and sanitized to prevent any unnecessary web vulnerabilities, like cross-site scripting or request forgery, to eliminate the tools an attacker has to elevate privileges. These are two instances in which we want to protect against dangerous input, and they are both handled in a very similar way.

Any data that is going to be reflected to the web application's view, used to set configuration variables, or invoke manual action needs to be treated as potentially dangerous. Reflected text in the web application can be dangerous if it is rendered on the page as valid HTML. For this reason, user input is either sanitized or escaped. This is another example of how Angular provided a lot of value right out of the box.

Sanitization of user input includes removing potentially dangerous characters entirely. This is commonly handled using regular expressions by looking for strings that match a particular pattern -- in this scenario we would try to identify and remove strings that begin with `<` and end with `>` because this is a pattern followed by all HTML tags. Angular sanitizes items by default if they are assigned in the HTML using the `ng-bind-html` and can be sanitized manually by using the `$sanitize` service.

```javascript
  function cleanContent(string) {
    return "<span>" + $sanitize(string) + "</span>";
  }
```

There is no current use case where we need to store and display HTML or text with potentially dangerous characters, so sanitizing the input is the safest option. Escaping, where the dangerous tokens are escaped so that they are not recognized as HTML, is handled by default through standard two-way data binding.

All the graphs are constructed using parameter values stored in Gardeners-log's entries, so every title string is escaped to prevent the possibility of an attacker inserting malicious code into the database as a parameter title causing it to be rendered on the dashboard to every subsequent user.

It is also possible for dangerous input to be sent to the Gardener container as an RPC request. The Gardener is capable of executing a handful of commands to modify the environment remotely. These commands can be changes to software, such as the propagation of new configuration, or hardware, like turning on the pumps for a set amount of time.

It is certain, however, that we can list each possible valid command. For this reason, I created a dispatch table including all the possible commands mapped to their function. Functions are first class objects in Python, so they can be stored in Dictionaries by default and invoked by key. This prevents execution of unwanted code because any command sent to the Gardener container's RPC server is cross-referenced with the dispatch table. This creates a whitelist for incoming requests. Furthermore, the parameters expected to be passed to these functions each have defining characteristics that can be checked before the functions execution. the dispatch table can also store an upper or lower bound on the parameter.

Under this system, the Gardener container might receive a request from the Gardeners-shed. This request contains a signature proving that it is indeed from the Gardeners-shed service and has a body that contains the following:

```yaml
turnPumpsOn 5
```

This message is split and expected to be in the form `method parameter`. The dispatch table includes a line, which matches the string `turnPumpsOn` to the appropriate method.

```yaml
{
  'turnPumpsOn': pumps.turnOn
}
```

In turn, this method is called with the passed parameter. This flow means that, barring a serious breach, a validated message is sent from the Gardeners-shed service containing a method known to exist and be available for remote execution.

## How Did I Secure It

I implemented a handful of security mechanisms to keep Victor safe while remaining extensible, powerful, and user friendly. Each of these preventative measures is intended to help defend both the weakest and most important parts of the framework.

### Physical

Physical security only protects against a very motivated attacker that is interested in doing long term damage. If the attacker already has direct physical access to the garden and its devices, they can already do a lot of physical damage. The following attacks are harder to detect and capable harming the system over longer periods of time.

Physical security is ultimately a deterrent rather than a means to an end. It is possible to interface with the Raspberry Pi machines over both ethernet and usb, so protecting physical access to these ports is important. Furthermore, the filesystem is contained on a single SD card, so direct access to this card could allow an attacker access regardless of whether or not the ports are protected.

I am using three primary methods of protecting the devices from an attacker with physical access. The hardware is kept in a secured enclosure, unused and unnecessary ports are removed, and SD cards are fixed and secured.

An enclosure is a necessary component of the build because the garden is outside at most times. It is possible to grow plants indoors with the proper lighting, but, even then, an enclosure protects the electronics from possible leaks. Though the enclosure is primarily in place as protection from the elements, adding a simple lock is an easily implemented first line of defense. The enclosure is fully acrylic, however, so a motivated attacker would have little problem gaining access to the devices.

With the device in hand, an attacker's first step would be attempting to gain local access over USB or ethernet. Though we may require these ports for wireless adapters, there are unused ports on each device. Unused ports can easily be desoldered and removed. Used ports can be coated in epoxy making their connections semi-permanent making it much more difficult to physically interface with the device. Lastly, the SD card contains all the data necessary to send messages to the proper API endpoint, so some means of obfuscation and protection is necessary. Encryption of the entire filesystem is the most secure way of solving this issue, but it can be problematic in the case of power failure. An authorized user may not be around to enter the decryption key for every device on reboot. In addition, in a large-deployment this could be a huge waste of time. For Victor's purposes, the creation of fake data is not a large enough concern to risk the increase in device management, so the SD card is handled much like a port that is in use and covered in epoxy. Coating the SD card reader in epoxy is enough to create a semi-permanent connection. Card failure happens much less often than reboot, so maintenance issues are less of a concern. There is always the chance of an attacker desoldering the entire reader and physically connecting it to another device, but there is a fine line when it comes to balancing the interplay between usability and overall system security. In this instance, mitigating the risk would compromise the management of the garden, and likely result in the implementation of a costly secured enclosure. The risk of an attacker removing a device's storage in the hopes of gaining write access to the `Gardeners-log` is too low to justify the costs associated, especially when considering that an attacker would still need to brute force the password of the device.

### Network

The following security mechanisms used to protect the garden's network are primarily used to prevent attackers with low motivation and low resources. These best practice methods of keeping Linux machines safe and secure should prevent the sorts of attacks bots and novice attackers are capable of performing.

Only one Raspberry Pi is allowed access out of the subnetwork to the open internet. This is the machine that the Gardener container, which is used to send and receive messages to Gardeners-log. Though the machine with the Gardener container has some additional measures, each Raspberry Pi was hardened by the following actions.

-Every machine's username and password were changed from their defaults.

Though this step seems trivial, the number of computers with unchanged credentials that are accessible over the internet is unnerving. For instance, using Shodan, which is a search engine that regularly and randomly fingerprints internet facing machines, it is trivially easy to find vulnerable devices. Searching for the phrase "default password" results in over 80,000 devices that contain those two words in their response, most commonly in the banner.

```
Cisco Router and Security Device Manager (SDM) is installed on this device.
This feature requires the one-time use of the username "cisco"
with the password "cisco". The default username and password have a privilege l...
```

![Default Password Search\label{Default Password}](source/figures/default.png){ width=60% }

This is a real response indexed on April 8th, 2017\. Furthermore, determining a list of internet facing Raspberry Pis running SSH is just as simple. Though Raspberry Pis are capable of running multiple operating systems, they are distributed with the Raspian OS. Searching for internet facing hosts that are running Raspian with port 22 open results in an index of over 50,000 devices. Since Raspian ships with default credentials and was created primarily for users with little Linux experience, it is likely that many of these services are entirely open.

![Raspian Search\label{Open Raspian}](source/figures/raspian.png){ width=60% }

-All unused services were shut off

Raspberry Pi's operating system comes with a handful of unnecessary running services by default. None of my devices require FTP, Apache, or SQL to run properly. Furthermore, any service they do need will be running inside of a Docker container.

-Machines are kept regularly updated.

One of the easiest ways to keep the OS and necessary services secure is by updating them regularly. To cut down on maintenance requirements this is handled with `cron-apt` a tool used to automatically update packages at regular time intervals.

The main Gardener machine also included the following two measures because of its increased responsibilities.

-The machine used to communicate with `Gardeners-log` needs comprehensive logging.

The Gardener machine has the largest SD card at a whopping 64 Gigabytes, so it handles extensive logging. Standard Debian logging keeps track of log ins and failed attempts.

-Protect against unwanted packets with a firewall.

Iptables is a standard firewall included in most Linux distributions that allows for user-defined configuration of the tables provided by the Linux kernel firewall. The configuration I have used is simple, but it allows me to define the ports and networks from which I allow communication. A huge benefit of the firewall is that it allows me to drop any packet that is not sent to the expected ports -- 80, 443, and 22\. Furthermore, a third-party tool, Fail2ban, runs on the Raspberry Pi and monitors the logs. It autonomously modifies the iptables rules to ban any IPs that appear malicious. Too many password failures or inappropriate snooping are circumstances that can be configured as a means for ban.

### Database Services

One of the benefits of using a serverless architecture hosted within the cloud is that, I am not responsible for hardening any of the servers that my API functions will ultimately run on. I do, however, need to properly manage authentication to the endpoints I want protected. The two mechanisms that I used to protect the endpoints were Amazon authorizer functions and API keys.

API keys are not inherently a great form of security because they rely on a single secret shared between the main garden device that is running the Gardener container and the Gardeners-log service. Because the garden's network and devices are secured and the Gardener is only sending encrypted messages, API keys provide a cost effective and simple means of decent protection. The key is created and stored within the Amazon Management Portal and set as an environmental variable on the main garden machine. Every request sent to the Gardeners-log API from the garden contains the key in its headers.

Though I am confident about the API key's role in this build, future applications may wish to utilize IOT frameworks, like AWS Greengrass or AT&T's M2X, for management, deployment and security. These frameworks facilitate local development for remote deployment, handling intermittent connectivity via data synchronization, and permission policies through X.509 certificates. The strongest benefit provided by these alternative services is that, unlike Victor's Gardeners-log service, they are able to identify the devices that are sending them data, which creates fine-grained control over the set of API actions each identity is authorized to invoke. These benefits come at a cost both monetarily and in the sense that the sender and receiver of the data become much more coupled.

When a request is sent to an Amazon API Gateway it first checks to determine whether or not any custom authorizers are associated with the Lambda function it is trying to access. If one exists the gateway grabs the authorizer token in the request and forwards it to the authorizer function. The API function implements the OAuth authentication protocol so functions protected via the authorizer functions are perfectly secure, assuming a valid OAuth configuration is in place and barring any breach of Google or Facebook.

In terms of availability, AWS Lambda is infinitely scalable. The service is ultimately reliant on Amazon, but because the code is spun up directly in response to the requests it receives, its infrastructure is as large as the number of people or entities trying to access it. Furthermore, the servers owned by Amazon that are capable of running Victor's functions are spread geographically. The risk of company-wide outage or denial of service is slim compared to any alternatives.

### Authentication

As I mentioned earlier, there are many places in the framework where a failure to protect authentication can cause a lot of problems. Authentication to the management of any of the four services is critically damaging, but I am only personally protecting the garden network's management. I have to trust in the fact that I have vetted the security practices of the services I have chosen to use, but I also need to ensure that I use best practices where I have control.

As I mentioned in the network section, each of the Raspberry Pis have a defined set of credentials used to authenticate over SSH. The passwords are all sufficiently long and randomized. Theoretically, they could be broken using a brute force attack, but it would be prohibitively expensive both computationally and financially.

The front-end web application utilizes the best practices for using the OAuth authentication protocol. In this case, the provider, Facebook and Google, set the username and password requirements, so I can be confident in the strength of credentials. Furthermore, both of these services are continually adopting two-factor authentication, which is ideal for authenticating to make credentialed API calls. The custom Lambda authorizer, upon receiving a success response from the chosen provider, sends the access token protected in the request's body. The token is stored in a cookie on the user's machine and used in subsequent requests that require the key. Secure coding of the web application helps protect against a remote attacker gaining access to or using another user's token. After a predetermined amount of time the token is invalidated and the user is required to authenticate once again.

Authentication can be daunting to secure because there are many things that can go wrong, I am confident that by following best practices and using cryptographically secure passwords that I have done my due diligence.

### Closing Thoughts

The security of the system is a balance of strength and convenience. The resources and actions made available to the user vary in both value and vulnerability. Extra measures of security are put in place both where I find the most value and where it will not impact the user's perception of the tool. Furthermore, security is handed off to third party providers when I felt that they can reliably provide a deliberately secure and well-maintained service, which keeps the operator's duties relatively low. At a significantly greater cost to the owner of the system it would be possible to implement a much more secure framework, but considering the overall risk of breach, the mechanisms put in place allow for a secure environment.
