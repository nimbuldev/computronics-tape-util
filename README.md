Originally forked from https://github.com/RVRX/computronics-tape-util

# A Computronics Cassette Tape Utility (for server players)

For the Minecraft mod, [Computronics](https://wiki.vexatos.com/wiki:computronics) (a [ComputerCraft](https://www.computercraft.info/) addon).
A group of utilites for Computronics Cassette Tapes, with focus on utilites that work on Minecraft servers.  
Current Included Utilities are:

-   Download utility for writing batches of files to a single cassette,
-   Looping a cassette from start to finish of all songs (not entire cassette), with automatic detection for song ending.

## Getting the Program On Your CC Computer

Copy [tape-dl.lua](https://raw.githubusercontent.com/RVRX/computronics-tape-util/master/tape-util.lua) code to pastebin, and enter:

`pastebin get [pastebin url] tape-util`, to download the program.  
Or Alternatively,  
`wget https://raw.githubusercontent.com/RVRX/computronics-tape-util/master/tape-util.lua ./tape-util`

## Usage

general usage can be seen by typing `tape-util`

### Downloader Utility

Downloads multiple tracks from a github directory and writes them to the cassette sequentually.

#### Setup/Prerequisites

In either order:

-   Download .wav or convert music file to .wav
-   Use [LionRay](https://github.com/gamax92/LionRay) to convert those to .dfpwm
    (Note: LionRay doesn't appear to have any batch converting, must be done one-by-one).
-   Upload .dfpwm files to a folder on github.

#### Running

Run the Program with
`tape-util dl [Directory URL]` 
 
for example: `tape-util dl https://github.com/nimbuldev/computronics-tape-util/tree/master/example-files` 

### Song Looper Utility

The song looper utility searches your cassette for the end of the song, then loops only up until that point, thereby skipping any dead/unwritten space at the end of a cassette.

#### Running

`tape-util loop`
