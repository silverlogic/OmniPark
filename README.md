# OmniPark
Money 2020 2017 Hackathon iOS App utilizing ARKit, Apple's Speech Recognition & Vison APIs, and Visa APIs

## Technology

* Swift 4.0
* Xcode 9.1 Beta
* iOS 11.1 Beta
* watchOS 3.0.+
* ARKit
* Apple's Speech Recognition API
* Apple's Vision API
* Google Directions API
* Visa Offers Platform

    * Merchants API -> Onboarding
    * Offers API -> Offer Creation
    * Offers API -> Activation
    * Offers API -> Statement

* Visa Direct
* VMORC

## Requirements

* Swift 4.0
* Xcode 9.1 Beta
* iPhone with at least an A9 processor
* Cocoapods 1.3.1
* Ruby 2.3.1

## Installation

### Ruby
Before installing CocoaPods, you will need the correct version of Ruby. For installing and managing different versions of Ruby on your local machine, we recommend using [Ruby Version Manager (RVM)](https://rvm.io/). Begin with the following command:
```
$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
```
Then run the following command to install RVM:
```
$ \curl -sSL https://get.rvm.io | bash -s stable
```
If the previous step is successful, run the following command to install Ruby 2.3.1:
```
$ rvm install ruby-2.3.1
```
Now run the following command to check that the correct version is being used:
```
$ ruby -v
```
The version reported should look like this:
```
ruby 2.3.1p112 (2016-04-26 revision 54768) [x86_64-darwin15]
```

### Cocoapods
[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects. You can install it with the following command:
```
$ gem install cocoapods
```

### Setup
After installing CocoaPods, use the following command to clone the repo:
```
$ git clone git@github.com:silverlogic/OmniPark.git
```
Then run the following command to install the dependencies used:
```
$ pod install
```
Then run the following command to open the project and start coding:
```
$ open OmniPark.xcworkspace
```
