Mailbox Converter
=================

Suppose you had a developer preview of an upcoming operating system with some
nifty search technology.  Suppose the mail client of this hypothetical system
converted your e-mail boxes from their original "mbox" format to a new "emlx"
format to support the nifty search technology.  Then suppose that for some
reason you wanted to go back to running the current release of the operating
system, and you found that your e-mail boxes were no longer readable.

In such a scenario, you might want a script like this one.

I wrote this when I was running a beta of Mac OS X Tiger, decided to revert
to Panther for a while, and needed to get my messages back into the older
version of Mail.  You provide it with the path to some emlx-style mailboxes,
and it converts them back into mbox files that can be imported into Mail
on Mac OS X 10.3.  By default, it will place the mbox files into a folder
called "Converted", although this can be overridden with a second comand-
line argument.

----------------------------------------------------------------------

Step-by-step instructions for the non-UNIX-inclined:

1.  Drag the "emlx2mbox" folder containing this Read Me file and the
    script to your home folder.

2.  Copy your Mail folder from the Library folder to the "emlx2mbox"
    folder.

3.  Open the Terminal application, found in Applications > Utilities.

4.  Type the following commands into the Terminal window,
    typing Return after each command:

        cd emlx2mbox
        chmod u+x emlx2mbox.rb
        ./emlx2mbox.rb Mail

5.  Watch as the script works its magic.  Hope you don't run into an
    error that I didn't encounter while I was writing it.

6.  Open your mail client on the current release of the operating
    system.

7.  Choose File > Import Mailboxes... from the menu bar, then choose
    "Other" from the list of options.  When asked for the folder
    containing the mailboxes, select the "Converted" folder that the
    script created inside the "emlx2mbox" folder.

8.  Watch as your mail client brings your messages back to life.
    Hope you don't run into an error that I didn't encounter while
    I was testing the script.

9.  Re-name your mailboxes so that they don't have the "-mbox" at
    the end of them, if you care about that sort of thing.

10.  If all went well, write to me and let me know you got something
     out of this little script.

----------------------------------------------------------------------

Note that this script was thrown together in a relatively short amount of
time to solve an immediate problem.  It may not work as advertised.  It may
not work at all.

If it does in fact work for you, and you're overwhelmed with gratitude and
want to throw money my way as a result, the Hallmark Gift Wish Certificates
are good; I can use those for just about anything.  But don't feel obligated
by any means.

- Marshall Elfstrand
  marshall@vengefulcow.com
  July 2005

UPDATE (2021-12-02) - IMDAT SOLAK
---------------------------------

This script was relying on very old libraries. I have updated this script to
require rub 3.x and use ruby's standard libraries.

