# Conclusion

First and foremost, Victor was built to help me maintain a hydroponic garden. I cannot say that it accomplished that goal in the first two seasons that it has been running because I do not have any vegetables grown to prove it. As it turns out, growing food is still hard regardless of how much data you have about your garden. However, Victor is one way in which I can iterate on my failures in a quantifiable way. The conditions of the garden and their results can be catalogued and referenced during future seasons meaning ultimately, given enough time, I will know the optimal environment necessary to grow productive, healthy vegetables.

Victor is also a prototype framework for services that run on the Internet of Things (IoT). Victor's services are organized around aggregation and analysis of data, and Victor is designed to address two current challenges facing the IoT: security and extensibility. 

The IoT is expected to grow tremendously over the next decade, and I believe one of the driving causes of this is the direct and immediate benefit of scalable data aggregation and analysis. Gartner estimates that 43% of all businesses have already implemented some form of IoT. [^fn1] IoT is already making an impact by increasing workflow efficiency and cost savings. The consumer market for IoT sees many of the same benefits and is also growing at an unprecedented rate with an expected $725 billion being spent on IoT in 2017\. [^fn2]

Though the cost of production for connected devices has been driven down over the past few years, two challenges still stand as obstacles for future growth -- security and extensibility. Incidents like October 2016's huge Mirai distributed denial of service attack from a botnet of insecure IoT cameras and DVRs has consumers much more interested in the security of the devices they are purchasing. [^fn3] The companies and developers of such IoT devices have yet to match the consumer's concern with a strong emphasis on device security. 

Extensibility will prevent a future of disposable IoT. The market is shifting rapidly and the applications of these devices are incredibly varied. A strong platform for extensibility, both in hardware and software, would mean that a collection of IoT devices would be able to grow with their application rather than serve a singular isolated purpose. 

Using current, light-weight virtualization tools, Victor makes extensibility simple to develop and deploy. However, this is only feasible if the IoT device or platform is running on a microcomputer. Likewise, virtualized encapsulation, sane device hardening, and protected communication among the entities of a service-based architecture facilitate a strongly secured IoT environment without compromising usability or functionality.

The future applications of IoT devices are vast and constantly growing. I think it is important for the market to adopt a framework and architecture for large scale networks of interconnected devices for the sake of the security of the network and the feasibility of long-term, large-scale adoption. Though I do not argue that Victor is the ultimate solution to the problems faced by IoT, it has solved many of those issues for my garden installation, and I hope I have the lettuce to show for it as soon as I can.

[^fn1]: http://www.gartner.com/newsroom/id/3236718
[^fn2]: http://www.pcworld.com/article/3167268/internet-of-things/as-iot-sales-surge-consumers-still-lead-the-way.html
[^fn3]: http://www.networkworld.com/article/3135270/security/fridays-ddos-attack-came-from-100000-infected-devices.html
