vim-notebook
============

A plugin for the Vim editor for handling any interpreter in a Notebook style.

This plugin is intended to create documents with an interpreter running in the
background and evaluating some "cells" containing code whenever asked. Of course,
it is very easy to execute some code from vim, but the standard way of doing it
will involve a new session of the interpreter at each call, losing variables, etc.
With this plugin, a single interpreter is waiting in the background with a persistent
state between calls.

Thus, Vim will behave like several well-known "notebook" software:

  * iPython
  * Maple
  * Mathematica
  * etc.

It has been tested with several interpreters and seems to work well with _Maxima_,
_GNU APL_, etc. as well as with some standard tools like `bc` or `sh`.

A demo can be seen [there](https://www.youtube.com/watch?v=wCGydHdE4b8).

[![Demo](http://img.youtube.com/vi/wCGydHdE4b8/0.jpg)](https://www.youtube.com/watch?v=wCGydHdE4b8)

The plugin uses Unix background processes, special files, etc. and will only work
on Unix-like operating systems.

When the kernel is launched, the filetype of the document will be set to "markdown"
and the standard syntax file for the Markdown" type will be used (it is up to the
user to enable highlighting or not). This syntax file defines a "markdownCodeBlock"
element made with lines of code beginning with 4 spaces:

    this is an example of "markdownCodeBlock"

When the cursor is on such a line, calling the relevant function will make the whole
block (no matter where the cursor is exactly in the block) be sent to the interpreter
and the output will be printed below.

Of course, the document may contain anything else: headers, text, etc. It should follow
the Markdown style, though it is not absolutely mandatory.

# Installation

Just copy the _notebook.vim_ file in your ~/.vim/plugin directory.

By default, the plugin will use `sh` when launched; you will have to configure it
to the interpreter you want to use.

# Basic configuration

Several global variables are involved in the configuration of the plugin; you should
set them in your ~/.vimrc configuration file.

### Shortcuts

You should probably map the `NotebookEvaluate()` function to some convenient key.
For instance:

    map µ :call NotebookEvaluate()<CR>

will map the µ key to the function evaluating code blocks.

### Various settings

The code block being evaluated can be highlighted until the output has been printed:

    let g:notebook_highlight = 1

By default, the cursor is on the last line of the output after evaluation. If you
want rather the cursor staying at the initial location, just set:

    let g:notebook_resetpos = 1

# Configuring a "kernel"

Not all interpreters will work with the plugin, but it is intended to allow many
ways of hacking and you should be able to use many different programs anyway.
Have a look at different settings in order to understand them.

### Configuring the sh kernel

This is the default setting:

    let g:notebook_cmd = '/bin/sh'
    let g:notebook_stop = 'exit'
    let g:notebook_send = 'echo NOTEBOOK-VIM-INTERNAL-KEY'
    let g:notebook_detect = 'NOTEBOOK-VIM-INTERNAL-KEY'
    let g:notebook_send0 = ''

The first line is the command to be used for starting the interpreter.
The second line is the command to be sent to the interpreter for leaving.
The third line is a command for the interpreter making it print some arbitrary
and complicated string. The fourth line is the _exact_ string printed by the
interpreter from the previous command.
The last line is a hack; here no setting is provided; some more complicated
interpreters may need it (see below).

### Configuring the bc calculator

    let g:notebook_cmd='bc 2>&1'
    let g:notebook_stop='quit'
    let g:notebook_send='print \"VIMBCNOTEBOOK\n\"'
    let g:notebook_detect="VIMBCNOTEBOOK"
    let g:notebook_send0=""

The settings are similar to the previous ones; but here we added `2>&1` to the
command in order to catch error messages as well.

### Configuring Maxima

The plugin was written with Maxima in mind. Here are some working settings:

    let g:notebook_cmd='stdbuf -i0 -o0 -e0 /usr/bin/maxima'
       \ . ' --disable-readline --very-quiet'
    let g:notebook_stop="quit();"
    let g:notebook_send0="\;"
    let g:notebook_send='print(\"VIMMAXIMANOTEBOOK\")\$'
    let g:notebook_detect='VIMMAXIMANOTEBOOK '

The command is prefixed with `stdbuf -i0 -o0 -e0` in order to unbuffer the following
command because intercommunication between processes is highly sensitive and the
whole system could be stuck otherwise.

The last line contains an espace character in the string; this is because Maxima
seems to add an espace when printing the string. If you encounter some issues with
these settings, you should carefully study wether your version of Maxima behaves
like that or not (you can do it by launching Maxima in a `script` session and then
study the resulting _typescript_ file).

Furthermore, the `g:notebook_send0` setting _may_ be used here. It will send
some more characters after each command and before askinf for the internal key.
If this setting is not used, the user should _never_ forget the final `;` in
the code being evaluated. If the `;` (or `$` character) is forgotten, the whole
session will be lost and the kernel will have to be restarted.

Several hacks can be used; the user can choose to never use the `;` but to add it
in the `g:notebook_send0` variable:

    let g:notebook_send0="\;"

Adding `;` by mistake will print an error message but the communication between
processes will remain alive.

Another strategy can be something like that:

    let g:notebook_send0=" 0\$"

Now the user has to use the `;` (or `$`) syntax; a strange error will be printed
when forgotten but the communication between processes will remain alive also.

### Configuring GNU APL

GNU APL works very well with the following settings:

    let g:notebook_cmd = '/home/pi/APL/svn/trunk/src/apl --noSV --rawCIN --noColor'
    let g:notebook_stop = ')OFF'
    let g:notebook_send0=""
    let g:notebook_send = "'VIMGNUAPLNOTEBOOK'"
    let g:notebook_detect = 'VIMGNUAPLNOTEBOOK'

### Configuring the J interpreter

The three-spaces prompt may be an issue. A quick fix can be:

    let g:notebook_cmd = '~/j/j801/bin/jconsole'
    let g:notebook_stop = "exit ''"
    let g:notebook_send0="''"
    let g:notebook_send = "'VIMJNOTEBOOK'"
    let g:notebook_detect = '   VIMJNOTEBOOK'

You have to be careful when copying lines 3 (no-op like) and 5 (with three spaces).

# Using the Notebook plugin

Just start it with:

    :call NotebookStart()

(or add some shortcut in your configuration file).

If you encounter some issues, just type `:!ps` and if you see your interpreter still
running though not answering, you may want to kill all involved processes with:

    :call NotebookEmergencyStop()

or rather with

    :call NotebookEmergencyRestart()
