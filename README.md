Give Me JS is a set of opinionated bash scripts for OSX for generating NPM modules and Github repos following certain conventions. Specifically it helps to generate a new Github repository containing a skeleton NPM module / JavasScript project. Each generated project has ES6, Babel, Webpack, Commitizen and Semantic Release already configured, ready for you to run a single command to see results. This project does: create a new github repository. This project does not: commit to that repository. For more information on the goals of this project, please see the notes section below.

## Before you get started

### Quick tips

I highly recommend that you use [Homebrew](https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Installation.md#installation) to install the following prerequisites.  I also highly recommend that you use [NVM](https://github.com/creationix/nvm) to install and manage Node. The first two or three steps in [these instructions](http://stackoverflow.com/a/28025834/1397590) do a good job of explaining how to install NVM using Homebrew. You can also [install it manually](http://jilles.me/managing-node-versions-with-nvm/).  NVM lets you easily switch between node versions without completely installing/uninstalling. Again, this decision is up to you. There is nothing in Give Me JS that requires Homebrew or NVM, but I think they'll make your life a bit easier. :) Hint: if you have problems installing Homebrew or NVM, make sure you run `xcode-select --install`, first.

### Prerequisites

Please make sure you have the following installed using either Homebrew or some other method:

- [Git](https://git-scm.com/download)
- [Node / Npm](https://nodejs.org)
- [Hub](https://hub.github.com), make sure that running `git version` returns both git's version and hub's version, otherwise it isn't set up properly.
- Also, please have your SSH public key [generated and uploaded to Github](https://help.github.com/articles/generating-ssh-keys/).

## Getting started

### Installation

Execute `npm install -g givemejs`.

### Generate your first project

Execute `givemejs testrepo cycle`. This will accomplish several things:

1. Generate a blank Github repo at https://github.com/mygithubusername/testrepo
2. Create a skeleton Cycle.js project in a new folder: `./testrepo`

You can alternatively run `givemejs myorganization/testrepo cycle` to generate your project under a specific github organization.

### What do we get?

All this script does is run gimme.sh, followed by the adapter

## Adapter support

### Cycle.js

The Cycle.js adapter gets you through the first page of the Cycle.js Getting Started page and if it is working properly, should produce a simple counter.

## Notes

This could probably be rewritten as a yeoman generator, but I don't have experience writing those and frankly, I just wanted something really simple and specific to my use cases. I'm happy to receive PR requests for other Frameworks. Ideally all of the PRs should be pretty minimal and just cover the first page or two of a getting started for a framework. This is not really meant to be a generator for kitchen sinks.

The main point of this project is as a learning experiment. Often in the marketing of frameworks there is a ton of boilerplate included in basic projects. It is sometimes difficult to understand what parts of the boilerplate are part of the framework and what parts are just opinionated best practices. This project attempts to draw clear boundaries between actual framework boilerplate and non-framework best practices. 

I've wrestled with making this a pure JS solution and making it cross platform, but to be honest I don't develop on Windows or Linux so I don't have the motivation to make it happen at the moment. I also like the current setup which allows to to easily see exactly what cli commands are being executed. This is always helpful for me because it shows the steps that leads up to a completed project, rather than just getting a code dump.