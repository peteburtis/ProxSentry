# ProxSentry
## A webcam based pseudo-proximity-sensor experiment for OS X

### [<img src="http://cloud.github.com/downloads/peteburtis/ProxSentry/LargeIcon.png" align="right" /> Get The Latest Version from the Downloads Page](https://github.com/downloads/peteburtis/ProxSentry/)

### Purpose

ProxSentry uses your Mac's built-in camera and OS X's built in facial detection technology to determine when you're paying attention to your computer.

Using this information, ProxSentry can do smart things, like:

* Dim the screen when you stop looking at it
* Stop your Mac from going to sleep while you're reading a long article
* Start your screensaver when you leave, and stop it when you get back
* Lock your screen when you stop using your computer

### Origin Story

During a discussion of sleep and power management on [episode 82 of the podcast Hypercritical](http://http://5by5.tv/hypercritical/82), John Siracusa envisioned that Apple might one day add a proximity sensor to the Mac, so that things like sleeping and waking one's computer could be managed more precisely as the user came and went.

This got my mind spinning: between the built-in camera and the facial detection libraries that have shipped with OS X since Lion, it seemed possible that the Mac might already have a pretty good approximation of a proximity sensor built in. The idea intrigued me, and I was temporarily burned out on the project I was working on anyway, so I decided to sit down for a night or two and see what could be cobbled together.

The result is ProxSentry.

It turns out that the built-in camera works surprisingly well as a user-presence sensor, given proper light conditions.  It feels kind of magical having your screen wake as you sit down to work without touching a thing, or dim as you turn to take a phone call without even thinking about it. Try it for a day and see. I hope Apple builds something this cool into a future Mac.

On the other hand, ProxSentry is literally five nights of work; please don't expect a lot of polish or eye candy. The core concept works, and works well, and the app is stable and useable. But the few graphics clearly have room for improvement, and the control panel is not the greatest piece of UI ever to be released.

### Fair Warning

This is a UI experiment, a toy, a proof-of-concept.  (Or a _disproof_-of-concept, perhaps.)  It's fun to play with, but as an actual tool to be used day-to-day, **it's basically useless**.

The fact that your camera's little green light stays on all the time when this program is running is annoying enough by itself to preclude its serious use.

On top of that, any power savings you might hope to realize (e.g. by dimming the screen more frequently, or sleeping your computer more quickly) are more than offset by the fact that your camera is on _all the time_, and your processor is working semi-hard at doing facial detection _all the time_.  With this program running, your battery percentage will free-fall. (The "Auto-Disable on Battery Power" setting was envisioned to perhaps make up for this weakness.  Still, you'll be running up your electricity bill instead of running down your battery.)

**Although you _can_ configure this program to run at startup, only a masochist would.**

### Consideration for the Author

If you like this program, or appreciate the concept, consider considering my semi-commercial endeavor: an app named [Readomator.](http://graygoolabs.com/mas/readomator)

Readomator is an text-to-speech Instapaper client that functions as a bridge between your read it later list and iTunes' podcasts section.  Flip one button and you can be listening to your saved Instapaper articles.  Once your Instapaper articles are converted into an iTunes podcast, you can sync them to an iPhone or iPod in the usual way, and listen to your reading list when reading would be inconvenient or impossible.  I use it often when I'm driving, washing dishes, gardening, etc. You may find it useful, too.  [It's available in the Mac App Store.](http://graygoolabs.com/mas/readomator)

My destitute blog is [The Future is Shiny](http://thefutureisshiny.com/). Who knows, if you subscribe to it maybe I'll release something else cool some day.

I am [@peteburtis](http://twitter.com/peteburtis) on twitter.  I would love your feedback.

### License

ProxSentry is licensed under the GPLv3.  See License.txt for more.

