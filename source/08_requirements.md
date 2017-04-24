# Requirements {.unnumbered}

As the primary user of this service, I approached development with a strict set of requirements.

First, there must be an attractive web-facing dashboard that is accessible by any and every user that knows where to find it. The dashboard should be extensible so that the numbers of gardens being displayed or connected is entirely up to the user.

Second, the connected gardens should, in real time, update the user on the status of the health indicators being monitored. The data should be transparently stored and accessed through a third party API, and while read access is completely open, any data posted to the API should be monitored and allowed only for credentialed users. In a secure manner, any user with the authorization to do so should have the ability to control the configuration of the garden and any number of configured manual actions.

Last and most important, the product should exist as a fully extensible framework. Though I am designing the project with a finite set of sensors and parameters in mind, adding another sensor, choosing to use a different number of components, and monitoring a greater number of gardens should be expected and accounted for. The system for modification should be simple and documented.

These requirements ensured that I created a useful, secure product that was abstracted from the configuration of the gardens being monitored and the hardware configurations of each garden.

## Summary of Chapters {.unnumbered}

In chapters 1 and 2 I will outline how I designed the application. In chapter 1, **Processes**, I will outline tools, technologies, and components of particular interest. A great deal of planning went into the construction of each particular service, and understanding the deliberate decisions of each should provide context of the overall scope of the project.

Chapter 2, **Implementation**, will then describe in detail how each item's functionality was built and show how they interact in order to display the role and extensibility of each.

In Chapter 3, **Security**, I'll briefly outline the threat model I used while attempting to control the flow of data.

Chapter 4, **Future Work**, I'll identify planned additions and how the extensibility of the framework would allow Victor to adapt to a wide variety of fields and applications.
