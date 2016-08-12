" Vim support file to define an APL menus
"
" Maintainer:	Thomas Baruchel <baruchel@gmx.com>
" Last Change:	2014 Feb 14
" Version:      1.1

" Copyright (c) 2014 Thomas Baruchel
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.

" Make sure the '<' and 'C' flags are not included in 'cpoptions', otherwise
" <CR> would not be recognized.  See ":help 'cpoptions'".
let s:cpo_save = &cpo
set cpo&vim

" Pari-GP settings
" ----------------
function! MyPariGpMode()
  let g:notebook_cmd='/home/pi/pari-2.7.2/gp -q'
  let g:notebook_stop='quit()'
  let g:notebook_send='print(\"VIMPARIGPNOTEBOOK\");'
  let g:notebook_detect='VIMPARIGPNOTEBOOK'
  let g:notebook_send0=''
  let g:notebook_sendinit='default(\"readline\",0); default(\"colors\",\"no\");'
endfunc

" Maxima settings
" ---------------
function! MyMaximaMode()
  let g:notebook_cmd='stdbuf -i0 -o0 -e0 /usr/bin/maxima'
     \ . ' --disable-readline --very-quiet'
  let g:notebook_stop="quit();"
  let g:notebook_send0=" 0\$"
  let g:notebook_send='print(\"VIMMAXIMANOTEBOOK\")\$'
  let g:notebook_detect='VIMMAXIMANOTEBOOK '
  let g:notebook_shell_internal = '/bin/sh'
endfunc

" GNU Apl settings
" ----------------
function! MyAplMode()
  let g:notebook_cmd = '/home/pi/APL/svn/trunk/src/apl --noSV --rawCIN --noColor'
  let g:notebook_stop = ')OFF'
  let g:notebook_send0=""
  let g:notebook_send = "'VIMGNUAPLNOTEBOOK'"
  let g:notebook_detect = 'VIMGNUAPLNOTEBOOK'
endfunc

" J settings
" ----------
function! MyJMode()
  let g:notebook_cmd = '~/j/j801/bin/jconsole'
  let g:notebook_stop = "exit ''"
  let g:notebook_send0="''"
  let g:notebook_send = "'VIMJNOTEBOOK'"
  let g:notebook_detect = '   VIMJNOTEBOOK'
endfunc

" Mathematica settings
" --------------------
function! MyMathematicaMode()
  let g:notebook_cmd='{ script -c wolfram /dev/null; }'
  let g:notebook_stop="Quit"
  let g:notebook_send0=""
  let g:notebook_send='Print []; Print [ \"VIMWOLFRAMNOTEBOOK\" ]; Print []'
  let g:notebook_detect='VIMWOLFRAMNOTEBOOK'
endfunc

" Scilab settings
" ---------------
function! MyScilabMode()
  let g:notebook_cmd = '{ script -qfc scilab-cli-bin /dev/null; }'
      \ . ' | grep --line-buffered -Pv "\x0d$"'
  let g:notebook_stop = "quit"
  let g:notebook_send0=""
  let g:notebook_send = 'disp(\"VIMSCILABNOTEBOOK\")'
  let g:notebook_detect = ' VIMSCILABNOTEBOOK   '
  let g:notebook_shell_internal = '/bin/sh'
endfunc

" NGN APL settings
" ----------------
function! MyNgnAPLMode()
  let g:notebook_cmd = 'nodejs ~/APL/apl.js --linewise'
  let g:notebook_stop = "⎕off"
  let g:notebook_send0=""
  let g:notebook_send = "'VIMNGNAPLNOTEBOOK'"
  let g:notebook_detect = 'VIMNGNAPLNOTEBOOK'
  let g:notebook_shell_internal = '/bin/sh'
endfunc

set wildmenu

" Avoid installing the menus twice
if !exists("did_install_notebook_menu")
  let did_install_notebook_menu = 1
  an 45.1 &Notebook.Pari-GP :call MyPariGpMode()<CR>:NotebookStart<CR>
  an 45.2 &Notebook.Maxima :call MyMaximaMode()<CR>:NotebookStart<CR>
  an 45.3 &Notebook.NGN-APL :call MyNgnAPLMode()<CR>:NotebookStart<CR>
  an 45.4 &Notebook.GNU-APL :call MyAPLMode()<CR>:NotebookStart<CR>
  an 45.5 &Notebook.J :call MyJMode()<CR>:NotebookStart<CR>
  an 45.6 &Notebook.BC :call MyBcMode()<CR>:NotebookStart<CR>
  an 45.7 &Notebook.[stop] :NotebookClose<CR>
endif " !exists("did_install_syntax_menu")

" Restore the previous value of 'cpoptions'.
let &cpo = s:cpo_save
unlet s:cpo_save

" shortcut
set wildcharm=<C-Z>

" vim: set sw=2 :
