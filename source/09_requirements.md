# Requirements {.unnumbered}

As the primary user of this service I approached development with a strict set
of requirements.

First, there must be an attractive web-facing dashboard that is accessible by
any and every user that knows where to find it.

The dashboard should be extensible so that the numbers of gardens being displayed
or connected is entirely up to the user.

Secondly, the connected gardens should, in real time, update the user on the
status of the health indicators of which it is monitoring.

The data should be transparently stored and accessed through a third party API, and
while read access is completely open write-access should be monitored and allowed only
to credentialed users.

Lastly, in a secure manner, any user with the authorization to do so should have the
ability to control the configuration of the garden and a number of manual actions.

These requirements ensured that I created a useful, secure product that was
abstracted from the number of gardens being monitored and the hardware configurations
of each.
