vim-notebook
============

A plugin for the Vim editor for handling any interpreter in a Notebook style.

This plugin is intended to create documents with an interpreter running in the
background and evaluating some "cells" containing code whenever asked. Of course,
it is very easy to execute some code from vim, but the standard way of doing it
will involve a new session of the interpreter at each call, losing variables, etc.
With this plugin, a single interpreter is waiting in the background with a persistent
state between calls.

It follows the philosophy of the Vim editor better than some similar plugins:
rather than launching an interactive interpreter within a buffer, it keeps it in
the background and makes it write into the buffer when the user needs it.

Thus, Vim will behave like several well-known "notebook" software:

  * iPython Notebook
  * Maple
  * Mathematica
  * etc.

It has been tested with several interpreters and seems to work well with _Octave_,
_Maxima_, _GNU APL_, _J_, etc. as well as with some standard tools like `bc` or `sh`.

A demo can be seen [there](https://www.youtube.com/watch?v=wCGydHdE4b8).

[![Demo](http://img.youtube.com/vi/wCGydHdE4b8/0.jpg)](https://www.youtube.com/watch?v=wCGydHdE4b8)

The plugin uses Unix background processes, special files, etc. and will only work
on Unix-like operating systems; it has been tested under Linux and Mac OS X.

When the kernel is launched, the filetype of the document will be set to "markdown"
and the standard syntax file for the Markdown type will be used; syntax highlighting
will also be enabled. This standard syntax file defines a "markdownCodeBlock"
element made with lines of code beginning with 4 spaces:

    this is an example of "markdownCodeBlock"

When the cursor is on such a line, using the `NotebookEvaluate` command will make the whole
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

You should probably map the the `NotebookEvaluate` command to some convenient key.
For instance:

    map µ :NotebookEvaluate<CR>

will map the µ key to the function evaluating code blocks.

### Various settings

The code block being evaluated can be highlighted until the output has been printed:

    let g:notebook_highlight = 1

By default, the cursor is on the last line of the output after evaluation. If you
want rather the cursor staying at the initial location, just set:

    let g:notebook_resetpos = 1

The previous setting has no effect when evaluating all the cells at a time.

# Configuring a "kernel"

Not all interpreters will work with the plugin, but it is intended to allow many
ways of hacking and you should be able to use many different programs anyway.
Have a look at different settings in order to understand them.

The interpreter should not use any buffering when writing to the standard output.
If it is the case, it should still be possible to use the interpreter with the
help of the `stdbuf` command (see the example for Maxima below).

#### Configuring the sh kernel

This is the default setting:

    let g:notebook_cmd = '/bin/sh 2>&1'
    let g:notebook_stop = 'exit'
    let g:notebook_send = 'echo NOTEBOOK-VIM-INTERNAL-KEY'
    let g:notebook_detect = 'NOTEBOOK-VIM-INTERNAL-KEY'
    let g:notebook_send0 = ''

The first line is the command to be used for starting the interpreter. In order
to catch error messages as well we added `2>&1` to the command.
The second line is the command to be sent to the interpreter for leaving.
The third line is a command for the interpreter making it print some arbitrary
and complicated string. The fourth line is the _exact_ string printed by the
interpreter from the previous command.
The last line is a hack; here no setting is provided; some more complicated
interpreters may need it (see below).

#### Configuring the bc calculator

    let g:notebook_cmd='bc 2>&1'
    let g:notebook_stop='quit'
    let g:notebook_send='print \"VIMBCNOTEBOOK\n\"'
    let g:notebook_detect="VIMBCNOTEBOOK"
    let g:notebook_send0=""

The settings are similar to the previous ones.

#### Configuring Octave

Ocatve should work with no problem with following settings:

    let g:notebook_cmd='octave'
    let g:notebook_stop='exit'
    let g:notebook_send='printf \"VIMOCTAVENOTEBOOK\n\"'
    let g:notebook_detect='VIMOCTAVENOTEBOOK'
    let g:notebook_send0=""

#### Configuring Maxima

The plugin was written with Maxima in mind and it should work quite well with it.
But since Maxima can be compiled in many different ways, the following settings may
have to be adjusted. Here are some working settings:

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
some more characters after each command and before asking for the internal key.
If this setting is not used, the user should _never_ forget the final `;` in
the code being evaluated. If the `;` (or `$` character) is forgotten, the whole
session will be lost and the kernel will have to be killed and restarted.

Several hacks can be used; the user can choose to never use the `;` but to add it
in the `g:notebook_send0` variable:

    let g:notebook_send0="\;"

Adding `;` by mistake will print an error message but the communication between
processes will remain alive.

Another strategy can be something like that:

    let g:notebook_send0=" 0\$"

Now the user has to use the `;` (or `$`) syntax; a strange error will be printed
when forgotten but the communication between processes will remain alive also.

#### Configuring Pari-GP

The plugin should work well with Pari-GP; however it has been tested with an old
out-of-date version of Pari-GP; the settings should be something like:

    let g:notebook_cmd='gp -q'
    let g:notebook_stop='quit()'
    let g:notebook_send='print(\"VIMPARIGPNOTEBOOK\");'
    let g:notebook_detect='VIMPARIGPNOTEBOOK'
    let g:notebook_send0='default(\"readline\",0); default(\"colors\",0);'

#### Configuring GNU APL

GNU APL works very well with the following settings:

    let g:notebook_cmd = '/home/pi/APL/svn/trunk/src/apl --noSV --rawCIN --noColor'
    let g:notebook_stop = ')OFF'
    let g:notebook_send0=""
    let g:notebook_send = "'VIMGNUAPLNOTEBOOK'"
    let g:notebook_detect = 'VIMGNUAPLNOTEBOOK'

#### Configuring the J interpreter

The three-spaces prompt may be an issue. A quick fix can be:

    let g:notebook_cmd = '~/j/j801/bin/jconsole'
    let g:notebook_stop = "exit ''"
    let g:notebook_send0="''"
    let g:notebook_send = "'VIMJNOTEBOOK'"
    let g:notebook_detect = '   VIMJNOTEBOOK'

You have to be careful when copying lines 3 (no-op like) and 5 (with three spaces).

# Using the Notebook plugin

Just start it with:

    :NotebookStart

(or add some shortcut in your configuration file).

Then, a block of code (at the position of the cursor) may be evaluated with:

    :NotebookEvaluate

The whole notebook document may be evaluated with:

    :NotebookEvaluateAll

The kernel may be stopped with one of the two following commands:

    :NotebookStop
    :NotebookClose

The kernel may be stopped and restarted with:

    :NotebookRestart

If you encounter some issues, just type `:!ps` and if you see your interpreter still
running though not answering, you may want to kill all involved processes with:

    :NotebookEmergencyStop

or rather with

    :NotebookEmergencyRestart

By default the plugin uses `/bin/sh` as an internal process; it is known to work
also with `bash`. You may set this with:

  let g:notebook_shell_internal = '/bin/sh'
  let g:notebook_shell_internal = '/bin/bash'
  etc.

in your configuration file, but unless you have good reasons to do it, you
are advised not to change this setting.
