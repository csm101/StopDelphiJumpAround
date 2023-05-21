# StopDelphiJumpAround
This is a plugin for the Embarcadero Delphi/RADStudio IDE that fixes a 
behavior I find extremely annoying.

## What problem does this plugin fix?
The Delphi IDE, like many other IDEs, switches automatically between a "Debug layout"
and a "Release Layout" whenever you start or stop the debugger.

The problem is that it doesn't just change its internal layout but also moves around 
the IDE main window and whenever this happens and It seems to have absolutely no respect
of the fact that I want the IDE window to stay put where I manually placed it.

This is actually driving me mad now that I am trying to work with two instances of delphi
and I want one instance to stay on the left side and one on the right side
(I work on a big 42'' 4K display): I open the thwo instances, I snap one on the right and
and one on the left, then I open the two projects... and just because I am opening the
projects each instace decides to change position. I snap them again where I want to be.
I launch the debuggers, they jump around again.

It feels like trying to read a book while someone insists in turning the page you are
still reading.

## How do I install this plugin?
Download the sources, open the .dpk project in delphi, right click on the project in the
project manager and select "Install". that's it.

## How does it work?
I wrote it as a quick and dirty hack to ease my frustration with this issue, surely
there is a better way of doing it, anyway it works this way:

it subclasses the ide main window and intercepts all the incoming WM_WINDOWPOSCHANGING
windows messages.

if you intercept these messages, you can alter their contents and set the SWP_NOMOVE
and SWP_NOSIZE flags to prevent the window size and position to be changed, and that's
exactly what I do.

You can still manually drag and resize the window or snap it to
sections of the screen by using the WINDOWS+LEFT/RIGHT/UP/DOWN keyboard combinations
because I check for the left mouse button or the WINDOWS key state: if any of the two 
is pressed, I allow the window movement.
