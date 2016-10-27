# Introduction {.unnumbered}

10 years from now computers will feed the world. For decades agricultural scientists
have worked tirelessly to improve and perfect the process of large-scale food production.
Advances in farming technology have without a doubt led to strong boosts in crop yield
at lower costs. Furthermore, without this development the amount of land and water
necessary to feed the global population would be absurd. Today 40% of land and 85%
of water consumption is used solely to grow food. Being that we can produce the same
amount of yield that we did 50 years ago with approximately 1/3 of the land, without
agricultural advances we'd need 26 billion acres of land, nearly 80% of all land on
earth, to produce enough food.

The increased production of food, however, is not as far reaching as one would like.
In fact, it is likely that those who need increased production of food most are those
that are affected least by recent technological advances in food. The International
Assessment of Agricultural Science and Technology for Development (IAASTD) has responded
that despite significant scientific and technological achievements in our ability
to increase agricultural productivity, we have been less attentive to some of
the unintended social and environmental consequences of our achievements.

So, with the looming global food crisis, environmental impact of rising global temperatures,
and ever growing global population; how can we improve on the process of growing food?
One Japanese company, Mirai, working with GE has spearheaded an experiment proposing indoor
hydroponic gardens. After purchasing a retired 25,000 square foot Sony semi-conductor factory
plant physiologist Shigeharu Shimamura began converting it into the world's largest indoor
farm illuminated by LED. The constantly lit, environmentally controlled grow room immediately
showed some of the benefits of the practice. Produce waste was from nearly 50 percent to just 10,
productivity per square foot was nearly 100 times as much, and water usage was just 1 percent of
what a conventional farm would consume. Thus it has been proposed that hydroponics could be
 the future of agriculture.

Hydroponics is a method of growing crops using only a nutrient solution administered
directly to the roots of the plants being grown and an inert medium used to suspend the
roots of the plants into the given solution. Crops grown hydroponically use significantly
less water, yield many times more than their soil-grown counterparts, and can grow
healthy, nutrient-rich vegetables despite inhospitable soil conditions or temperatures.

The promise of more sustainable produce has led to an increased adoption of hydroponics
both commercially and by amateur gardeners all over the world; however, there are two
incredibly important complications that have kept soilless gardens from being widely accessible.

Firstly, there is a large learning curve associated with growing plants hydroponically.
In comparison to tradition soil gardens, hydroponic gardens require strict monitoring of
growing conditions, nutrient solutions, and root health. Furthermore, hydroponic gardens
are prone to a collection of diseases and pests that are not commonly seen in soil
gardens.

Second, hydroponic gardens are costly. The initial start up costs, cost of labor, and
cost of upkeep are all significantly higher for hydroponic gardens. In commercial grow
operations this cost is often offset by the greater yield, but the necessity of more
higher-paid operators is a serious business consideration. For smaller, hobbyist
gardeners looking to build a hydroponic garden in a community space or at home the
increased cost can be incredibly prohibitive. Even if the garden's yield outweighs the
cost of materials, the opportunity cost associated with constantly monitoring and
servicing a hydroponic garden is often impossible to commit to.

In many ways these two glaring problems are not entirely avoidable. The initial costs
of materials and continuing cost of maintenance and upkeep will most likely always be
more than a traditional soil garden.  however, I believe that the benefits of hydroponic
gardens are enticing enough that by lessening the burden of monitoring and upkeep the
prospect of hydroponic gardens could become immediately more viable and likely less
expensive as well.

Nutrient Film Technique (NFT) is a sub-genre of hydroponic gardens that utilize
a shallow film of nutrient enriched water running separate channels on a slight
decline to deliver sustenance to plant's roots, which are suspended in a medium absent
of any nutrients on the top of the aforementioned channels. NFT gardens provide
an ideal environment in which plants are consistently exposed to water, oxygen, and nutrients.

With a good setup this ensures that plants grown using the NFT methodology will
consistently produce high-quality vegetable with increased yields even over other
hydroponic crops. However, this comes at a significant cost. Because NFT gardens are
so reliant on the constant flow of nutrients they also require constant monitoring.
These gardens are susceptible to a handful of disastrous issues regarding flow that
are capable the plants affected within a matter of hours. In the case that the the
pump supplying water from the reservoir to the channels were to lose power the
plants would dry up and die within a few hours. Similarly because of the tight plumbing and
inevitability of sediment being introduced into the reservoir a clogged line could kill
all of the plants in a single channel or even an entire garden if it was the main line.
A less dire, but still pressing complication occurs because as the plants consume the
nutrients from the solution some of the water evaporates through the openings at the
top of each channel. If the amount of water that sweats out of the system is greater
than the consumption rate of the nutrients, then the plants are at risk of dying from
being exposed to a pH imbalanced solution.

In an effort to explore methods of making hydroponic gardens, a high-yield, sustainable,
space saving means of growing fresh produce, more available I built Victor -- a collection of
services used in conjunction to mitigate the amount of time taking measurements about the growing conditions
of your garden, provide you with real time alerts in the case that something seems to be going
wrong, and give you an interface with managing some of the upkeep remotely. The test garden being monitored
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
comprehensive view of the current state of the garden. I believe this tool can easily cut back both
the total number of hours required to maintain a hydroponic garden and lower the barrier of entry
by providing gardeners with baseline numbers to compare to and programmable warnings.
