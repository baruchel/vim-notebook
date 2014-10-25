" Vim plugin for communicating with some interpreter from a notebook like document
"
" Maintainer:	Thomas Baruchel <baruchel@gmx.com>
" Last Change:	2014 Oct 25
" Version:      1.1.1

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


if !exists('g:notebook_cmd')
  let g:notebook_cmd = '/bin/sh 2>&1'
endif
if !exists('g:notebook_stop')
  let g:notebook_stop = 'exit'
endif
if !exists('g:notebook_sendinit')
  let g:notebook_sendinit = ''
endif
if !exists('g:notebook_send0')
  let g:notebook_send0 = ''
endif
if !exists('g:notebook_send')
  let g:notebook_send = 'echo NOTEBOOK-VIM-INTERNAL-KEY'
endif
if !exists('g:notebook_detect')
  let g:notebook_detect = 'NOTEBOOK-VIM-INTERNAL-KEY'
endif
if !exists('g:notebook_highlight')
  let g:notebook_highlight = 1
endif
if !exists('g:notebook_resetpos')
  let g:notebook_resetpos = 0
endif
if !exists('g:notebook_shell_internal')
  let g:notebook_shell_internal = '/bin/sh'
endif


if exists('loaded_notebook') || &cp
    finish
endif
let loaded_notebook=1


" Close the current kernel
function! NotebookClose()

  if !exists('b:notebook_pid')
    echo "No kernel is currently running."
    return
  endif

  echon 'Stopping the kernel...'

  exe 'autocmd! * <buffer>'

  " The notebook_send0 has not to be sent here.

  " close the process
  let l:tmp = system('echo "' . b:notebook_stop . '" >> ' . b:notebook_fifo_in)

  " an empty line should close the 'tail -f' process
  let l:tmp = system('echo "" >> ' . b:notebook_fifo_in)

  " kill the shell process
  let l:tmp = system('kill -9 ' . b:notebook_pid)

  " remove some variables
  unlet! b:notebook_stop
  unlet! b:notebook_send
  unlet! b:notebook_pid

  " I have to think if it is really useful to delete the two FIFOs
  " (because a race condition could occur if they are removed
  " before the 'stop' command has actually been read, and it may be
  " important with interpreters that don't accept Ctrl-D like GNU APL
  " When Vim leaves, the directory is deleted anyway.

  "let l:tmp = system('rm -f ' . b:notebook_fifo_in)
  unlet! b:notebook_fifo_in
  "let l:tmp = system('rm -f ' . b:notebook_fifo_out)
  unlet! b:notebook_fifo_out

  echo ' '

endfunction


function! NotebookRestart()

  if !exists('b:notebook_pid')
    echo "No kernel is currently running."
    return
  endif

  call NotebookClose()
  redraw
  call NotebookStart()

endfunction


" Evaluate the Code Block at the position of the cursor.
" Since version 1.0.2 the function NotebookEvaluate() has a return value
" indicating how many lines have been sent to the kernel.
function! NotebookEvaluate()

  if !exists('b:notebook_pid')
    echo "No kernel is currently running."
    return 0
  endif

  let l:currentline = line(".")
  if synIDattr(synID(l:currentline,1,1),"name") != "markdownCodeBlock"
    echo "Current line is not of type 'markdownCodeBlock'"
    return 0
  endif

  let l:save_cursor = getpos(".")
  let l:time0 = localtime()

  let l:blockstart = l:currentline
  while (synIDattr(synID(l:blockstart,1,1),"name") == "markdownCodeBlock")
    \ && (l:blockstart >= 1)
    let l:blockstart = l:blockstart - 1
  endwhile
  let l:blockstart = l:blockstart + 1

  let l:blockend = l:currentline
  let l:lastline = line("$")
  while synIDattr(synID(l:blockend,1,1),"name") == "markdownCodeBlock"
    \ && (l:blockend <= l:lastline)
    let l:blockend = l:blockend + 1
  endwhile
  let l:blockend = l:blockend - 1

  if g:notebook_highlight != 0
    let l:tmp_pattern = "match Todo /"
    let l:currentline = l:blockstart
    while l:currentline < l:blockend
      let l:tmp_pattern = l:tmp_pattern . "\\%" . l:currentline . "l\\|"
      let l:currentline = l:currentline + 1
    endwhile
    let l:tmp_pattern = l:tmp_pattern . "\\%" . l:blockend . "l/"
    execute l:tmp_pattern
    redraw
  endif

  exe l:blockstart . ',' . l:blockend . 'write! >> ' . b:notebook_fifo_in
  if len(b:notebook_send0) > 0
    let l:tmp = system('echo "' . b:notebook_send0 . '" >> ' . b:notebook_fifo_in)
  endif
  let l:tmp = system('echo "' . b:notebook_send . '" >> ' . b:notebook_fifo_in)

  exe 'silent normal! ' . l:blockend . 'Go'
  exe 'read! cat ' . b:notebook_fifo_out
  if g:notebook_highlight != 0
    match
  endif

  if g:notebook_resetpos != 0
    call setpos('.', l:save_cursor)
  endif
  redraw

  let l:mytime = localtime() - l:time0
  if l:mytime < 1
    let l:mytime = ""
  else
    let l:mytime = " Time=" . mytime . " sec."
  endif

  if l:blockstart == l:blockend
    echo "Line ".l:blockstart." was sent to the kernel (1 line)." . l:mytime
  else
    echo "Lines ".l:blockstart."-".l:blockend
      \ . " were sent to the kernel (".(l:blockend-l:blockstart+1)." lines)."
      \ . l:mytime
  endif
  
  return l:blockend - l:blockstart + 1

endfunction


" Start a new kernel
function! NotebookStart()

  if exists('b:notebook_pid')
    echo 'Warning: a running kernel is already attached to the current buffer.'
    return
  endif

  if len(g:notebook_shell_internal) > 0
    let l:shelltmp = &shell
    let &shell = g:notebook_shell_internal
  endif

  echon 'Starting the kernel...'

  " create two fifo special files
  let b:notebook_fifo_in = tempname()
  let l:tmp = system('mkfifo ' . b:notebook_fifo_in)
  let b:notebook_fifo_out = tempname()
  let l:out = b:notebook_fifo_out
  let l:tmp = system('mkfifo ' . b:notebook_fifo_out)

  " copy the global variables to buffer variables
  " in order to allow the global variables to be changed
  let b:notebook_stop = g:notebook_stop
  let b:notebook_send0 = g:notebook_send0
  let b:notebook_send = g:notebook_send

  let l:tmp = 'tail -f ' . b:notebook_fifo_in
  let l:tmp = l:tmp . ' | ' . g:notebook_cmd
  let l:tmp = l:tmp . ' | { while IFS= read -r line;'
  let l:tmp = l:tmp . ' do { while [ "$line" != "' . g:notebook_detect .'" ];'
  let l:tmp = l:tmp . ' do echo "$line"; IFS= read -r line; done; } > ' . b:notebook_fifo_out .';'
  let l:tmp = l:tmp . ' done; } &'
  let l:tmp = l:tmp . ' echo "$!"'
  "let l:tmp = l:tmp . ' > ' . b:notebook_fifo_in
  let b:notebook_pid = system(l:tmp)

  " send an initial command to be detected
  " --------------------------------------
  " Since version 1.1.1 sending an initial notebook_send0 is disabled;
  " it is replaced with sending a notebook_sendinit command
  if len(g:notebook_sendinit) > 0
    let l:tmp = system('echo "' . g:notebook_sendinit . '" >> ' . b:notebook_fifo_in)
  endif
  let l:tmp = system('echo "' . b:notebook_send . '" >> ' . b:notebook_fifo_in)

  set filetype=markdown
  syntax on

  let l:tmp = system('cat ' . l:out . ' > /dev/null')
  echo ' '
  redraw

  if len(g:notebook_shell_internal) > 0
    let &shell = l:shelltmp
  endif

  " autocmd for stopping the kernel when closing the buffer
  exe 'autocmd BufDelete <buffer> call NotebookClose()'
  exe 'autocmd BufUnload <buffer> call NotebookClose()'
  " exe 'autocmd VimLeave <buffer> call NotebookClose()'

endfunction


" Stop the kernel when communication is lost (by using ps + grep for
" finding the PID of the 'tail' process and killing it)
function! NotebookEmergencyStop()

  if !exists('b:notebook_pid')
    echo "No kernel is currently running."
    return
  endif

  let l:cmd = 'ps a | grep -F "tail -f ' . b:notebook_fifo_in . '"'
    \ . ' | awk "!/grep/ {print \$1}"'
  let l:tmp = system(l:cmd)
  echo "Killing processes with PID " . l:tmp
  let l:tmp = system("kill -9 " . l:tmp)
  exe 'autocmd! * <buffer>'
  unlet! b:notebook_stop
  unlet! b:notebook_send
  unlet! b:notebook_pid
  unlet! b:notebook_fifo_in
  unlet! b:notebook_fifo_out

endfunction


" Restart the kernel when communication with the kernel is lost
function! NotebookEmergencyRestart()

  if !exists('b:notebook_pid')
    echo "No kernel is currently running."
    return
  endif

  call NotebookEmergencyStop()
  call NotebookStart()

endfunction


" Evaluate the whole document
function! NotebookEvaluateAll()

  if !exists('b:notebook_pid')
    echo "No kernel is currently running."
    return
  endif

  let l:currentline = 0
  let l:total = 0
  let l:nbrblocks = 0
  let l:lastline = line('$')
  let l:time0 = localtime()

  let l:resetpostmp = g:notebook_resetpos
  let g:notebook_resetpos = 0

  " Warning : the number of lines is changing during the loop!
  while l:currentline < l:lastline
    let l:currentline = l:currentline + 1
    if (synIDattr(synID(l:currentline,1,1),"name") == "markdownCodeBlock")
      exe 'silent normal! ' . l:currentline . 'G'
      let l:nbr = NotebookEvaluate()
      redraw
      let l:lastline = line('$')
      let l:currentline = line('.')
      let l:total = l:total + l:nbr
      let l:nbrblocks = l:nbrblocks + 1
    endif
  endwhile

  let g:notebook_resetpos = l:resetpostmp

  if l:total == 1
    let l:count = '(1 line)'
  else
    let l:count = '(' . l:total . ' lines)'
  endif

  let l:mytime = localtime() - l:time0
  if l:mytime < 1
    let l:mytime = ""
  else
    let l:mytime = " Time=" . mytime . " sec."
  endif

  if l:nbrblocks == 0
    echo 'No code block was found in the current document.'
  elseif l:nbrblocks == 1
    echo 'One block was sent to the kernel ' . l:count . '.' . l:mytime
  else
    echo l:nbrblocks . ' blocks were sent to the kernel ' . l:count . '.'
     \ . l:mytime
  endif

endfunction


command! NotebookStart :call NotebookStart()
command! NotebookEvaluate :call NotebookEvaluate()
command! NotebookEvaluateAll :call NotebookEvaluateAll()
command! NotebookClose :call NotebookClose()
command! NotebookStop :call NotebookClose()
command! NotebookRestart :call NotebookRestart()
command! NotebookEmergencyStop :call NotebookEmergencyStop()
command! NotebookEmergencyRestart :call NotebookEmergencyRestart()
