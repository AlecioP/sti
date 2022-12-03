# STI
STI (_**S**ervizio **T**erminologico **I**ntegrato_)

## Architecture
![Architecture](https://raw.githubusercontent.com/iit-rende/sti-cts2-portlets-build/master/screenshot/infrasttuttura.png)

## Overview 

This repository is meant to be the starting point to the whole STI app. This project is composed of 3 main parts:
1. **CTS2-FRAMEWORK** subdirectory is the merge of two forks of the same original repository [cts2/cts2-framework](https://github.com/cts2/cts2-framework). The two forks are [iit-rende/sti-cts2-framework](https://github.com/iit-rende/sti-cts2-framework) and [lexevs/cts2-framework](https://github.com/lexevs/cts2-framework). The original repo is a development framework, which allows to implement applications compliant to [Common-Terminology-Service-2 functional standard](https://www.omg.org/cts2/).
2. **STI-SERVICE** is a plugin for the _OSGI_ framework **CTS2**. The code for this subproject is available at [iit-rende/sti-service](https://github.com/iit-rende/sti-service).
3. **STI-CTS2-PORTLETS** is a repository containing two portlets (compatible with liferay portal) which are used to communicate with **STI-SERVICE** plugin. The code is available at [iit-rende/sti-cts2-portlets-build](https://github.com/iit-rende/sti-cts2-portlets-build)

## More

Detailed informations about this project and its dependencies are available [here](./publiccode.yml). 

As explained in [italia/publiccode.yml-docs](https://github.com/italia/publiccode.yml-docs/blob/main/README.md) this is what the file is meant for:

> Many great software projects are developed by public administrations, however
> reuse of these projects is very limited. Some of the reasons for low uptake of
> such projects is a lack of discoverability and that it is hard to find out what
> project can actually work in the context of a different public administration.
> 
> The `publiccode.yml` file is meant to solve all those problems. As such, it is
> an easily readable file for civil servants that are trying to figure out
> whether a project will work for them, and easily readable for computers as
> well. It contains information such as:
> * the title and description of the project or product in English and/or other
>   languages;
> * the development status, e.g. `concept`, `development`, `beta`, `stable`,
>   `obsolete`;
> * which organisation developed the project;
> * who is caring for the maintenance and when this expires; 
> * who to contact for technical or support inquiries;
> * what national and local legal frameworks this project or product is designed
>   for;
> * what software dependencies this project or product has. 
>
> The `publiccode.yml` file format should both be able to easily be added to any
> new project, as well as grow with the project as it expands beyond the original
> context it was developed in.