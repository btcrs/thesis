# Requirements {.unnumbered}

As the primary user of this service I approached development with a strict set
of requirements.

First, there must be an attractive web-facing dashboard that is accessible by
any and every user that knows where to find it. The dashboard should be
extensible so that the numbers of gardens being displayed or connected is
entirely up to the user.

Secondly, the connected gardens should, in real time, update the user on the
status of the health indicators of which it is monitoring. The data should be
transparently stored and accessed through a third party API, and while read
access is completely open write-access should be monitored and allowed only
to credentialed users.

Lastly, in a secure manner, any user with the authorization to do so should have the
ability to control the configuration of the garden and a number of manual actions.

These requirements ensured that I created a useful, secure product that was
abstracted from the number of gardens being monitored and the hardware configurations
of each.

##Summary of chapters

In chapters 1 and 2 I will outline how I designed the application. In chapter 1, **Processes**,
I will outline tools, technologies, and components of particular interest. A great deal
of planning went into the construction of each particular service, and understanding the
deliberate decisions of each should provide context of the overall scope of the project.

Chapter 2, **implementation**, will then describe in detail how each item's functionality
was built and finally show how the interact in order to display the role and extensibility
of each.
