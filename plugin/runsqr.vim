" runsqr.vim
" author: David Price
" version: 0.1
"
" This file contains routines that may be used to execute SQR program
" directly from VIM.  It depends on SQRW.  Default parameters utilize
" the $PS_HOME environment variable, although you can override these values
" in your .vimrc file.
"
" In command mode:
"   <F8>: execute the SELECT query under your cursor.  The query must begin with
"         the "select" keyword and end with a ";"
"   <Leader><F8>: prompt for an SQL command/query to execute.
"   <F9>: treat the identifier under the cursor as a table name, and do a 'describe'
"         on it.
"   <F10>: prompt for a table to describe.
"   <F11>: set the current SQL*Plus username and password
"   <Leader>sb: open an empty buffer in a new window to enter SQL commands in
"   <Leader>ss: execute the (one-line) query on the current line
"   <Leader>se: execute the query under the cursor (as <F8>)
"   <Leader>st: describe the table under the cursor (as <F9>)
"   <Leader>sc: open the user's common SQL buffer (g:sqlplus_common_buffer) in a
"               new window.
"
"   :Select <...> -- execute the given Select query.
"   :Update <...> -- execute the given Update command.
"   :Delete <...> -- execute the given Delete command
"   :DB <db-name> -- set the database name to <db-name>
"   :SQL <...> -- open a blank SQL buffer in a new window, or if a filename is
"                 specified, open the given file in a new window.
"
" In visual mode:
"   <F8>: execute the selected query
"
" You will be prompted for your user-name and password the first time you access
" one of these functions during a session.  After that, your user-id and password
" will be remembered until the session ends.
"
" You can specify the values of the following global variables in your .vimrc
" file, to alter the behavior of this plugin:
"
"   g:runsqr_exe -- the path and name of the SQRW executable
"       Default: $PS_HOME . "/bin/sqr/ora/BINW/sqrw.exe"
"   g:runsqr_flags -- the command line options that will be used when 
"       executing the SQR.  Default: "-fc:\temp\ -oc:\temp\sqr.log -ic:\pt852\sqr\ 
"       -zifc:\pt852\sqr\pssqr.ini -PRINTER:PD'"
"   g:runsqr_logfile -- Location and name of the log file.  Passed to the command
"       line using the -O parameter.   Default: "c:/temp/sqr.logi"
"
" TODO: 
" Automatic lookup for password from KeePass.
" Command line; KPScript.exe -c:GetEntryString dlprice.kdbx -guikeyprompt 
"   -Field:Password -ref-Title:GENIDEV -ref-UserName:sysadm
"
" ------------------------------------------------------------------------------
" Thanks to:
"   Jamis Buck (jgb3@email.byu.edu) for his version of sqlplus.vim, from which
"     this started.  He, in turns, thanked:
"   Matt Kunze (kunzem@optimiz.com) for getting this script to work under
"     Windows
" ------------------------------------------------------------------------------

" Global variables (may be set in ~/.vimrc) {{{1
if !exists( "g:runsqr_userid" )
  let g:runsqr_userid = "sysadm"
  let g:runsqr_passwd = ""
endif
if !exists( "g:runsqr_exe" )
  "let g:runsqr_exe = $PS_HOME . "/bin/sqr/ora/BINW/sqrw.exe "
  let g:runsqr_exe = "c:/pt852/bin/sqr/ora/BINW/sqrw.exe "
endif
if !exists( "g:runsqr_flags")
  "let g:runsqr_flags = "-fc:\\temp\\ -oc:\\temp\\sqr.log -i" . $PS_HOME . "\\sqr\\ -zif" . $PS_HOME . "\\sqr\\pssqr.ini -PRINTER:PD"
  let g:runsqr_flags = "-fc:\\temp\\ -ic:\\pt852\\sqr\\ -zifc:\\pt852\\sqr\\pssqr.ini -PRINTER:PD"
endif
if !exists( "g:runsqr_logfile" )
  let g:runsqr_logfile = "c:/temp/sqr.log"
endif
if !exists( "g:runsqr_db" )
  let g:runsqr_db = $ORACLE_SID
endif
"}}}

function! RunSQR_GetLogin( force ) "{{{1

  if g:runsqr_passwd == "" || a:force != 0
    if g:runsqr_userid == ""
      if has("win32")
        let l:userid = 'sysadm'
      else
        let l:userid = substitute( system( "whoami" ), "\n", "", "g" )
      endif
    else
      let l:userid = g:runsqr_userid
    endif
    let g:runsqr_db = input( "Please enter your database name: ", g:runsqr_db )
    let g:runsqr_userid = input( "Please enter your SQR user-id:  ", l:userid )
    let g:runsqr_passwd = inputsecret( "Please enter your SQR password:  " )
  endif
endfunction "}}}

function! RunSQR_Exec() "{{{1
  if &filetype == "sqr"
    call RunSQR_GetLogin( 0 )
    let l:filename = expand('%:p')
    let l:connect = " " . g:runsqr_userid . "/" . g:runsqr_passwd . "@" . g:runsqr_db . " "
    let l:cmd = g:runsqr_exe . l:filename . l:connect . g:runsqr_flags . " -o" . g:runsqr_logfile
    echo "Running SQR using " . g:runsqr_userid . "/" . g:runsqr_db
    exe ":silent !start " . l:cmd
    "call AE_configureOutputWindow()
  else
    echohl WarningMsg | echo "Unable to run" | echo "File not an SQR file" | echohl None
  endif
endfunction "}}}


function! RunSQR_OpenLog( fname ) "{{{1
  exe "new " . a:fname
  "set ts=8 buftype=nofile nowrap sidescroll=5 listchars+=precedes:<,extends:>
  normal 1G
  let l:newheight = line("$")
  if l:newheight < winheight(0)
    exe "resize " . l:newheight
  endif
endfunction "}}}


" command-mode mappings {{{1
exe "map <Leader>sc   :call RunSQR_OpenLog( \"" . g:runsqr_logfile . "\" )<CR>"
map <F7>  :call RunSQR_Exec()<CR>
map <F11> :call RunSQR_GetLogin(1)<CR>
"}}}

" visual mode mappings {{{1
"vmap <F8> "zy:call AE_execLiteralQuery( @z )<CR>
"}}}

" commands {{{1
command! -nargs=0 SQRRun :call RunSQR_Exec()
command! -nargs=0 SQRDB :call RunSQR_GetLogin(1)

":menu Oracle.Execute\ whole\ script<Tab>F7 :call AE_execWholeScript()<CR>
":menu Oracle.Execute\ query\ under\ cursor<Tab>F8  :call AE_execQueryUnderCursor()<CR>
":menu Oracle.Prompt\ for\ query<Tab>\\F8  :call AE_promptQuery()<CR>
":menu Oracle.Describe\ table\ under\ cursor<Tab>F09 :call AE_describeTableUnderCursor()<CR>
":menu Oracle.Prompt\ for\ table\ to\ describe<Tab>F10 :call AE_describeTablePrompt()<CR>
":menu Oracle.Change\ connect\ information<Tab>F11 :call AE_getSQLPlusUIDandPasswd(1)<CR>
 
"}}}

