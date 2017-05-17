# thesis

> Victor: Creating a Monitored, Secured, and Self-Sustaining IOT Hydroponic Garden

I developed Victor to help me grow vegetables by monitoring my garden. Victor is a framework composed of four separate services: `Container-gardening`, `Gardeners-log`, `Gardeners-shed`, and `Victor`. Together these elements gather measurements about garden's environment, store the data in a cloud hosted database, and display the measurements graphically on a web application.

In this thesis I first detail the components, both hardware and software, used in my build and how they fit into the overall design and architecture of the framework. I then discuss how Victor could be abstracted from the use-case of hydroponic garden's entirely and used in a wide variety of distributed data acquisition applications.

Though I do not believe that Victor solves the issues of large scale Internet of Things deployments unanimously, I argue that, for systems that use a microcomputer as the central operator of IoT deployments, Victor mitigates the security and extensibility issues present in devices today.

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Contribute](#contribute)
- [License](#license)

## Install

Requires
```
A Latex distribution
Pandoc
Pandoc Cite-Proc
pip install pandoc-shortcaption
```

```
sudo tlmgr install truncate
sudo tlmgr install tocloft
sudo tlmgr install wallpaper
sudo tlmgr install morefloats
sudo tlmgr install sectsty
sudo tlmgr install siunitx
sudo tlmgr install threeparttable
sudo tlmgr update l3packages
sudo tlmgr update l3kernel
sudo tlmgr update l3experimental
```

## Usage

To auto-generate on save

```
Grunt watch
```

To generate a PDF manually

```
make pdf
```

## License

 © Ben Carothers
