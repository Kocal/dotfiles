set termguicolors
set background=dark
autocmd vimenter * ++nested colorscheme solarized8

" General Settings (https://github.com/sd65/MiniVim)
set ttyfast " Faster refraw
set mouse=nv " Mouse activated in Normal and Visual Mode
set shortmess+=I " No intro when starting Vim
set smartindent " Smart... indent
set expandtab " Insert spaces instead of tabs
set softtabstop=4 " ... and insert two spaces
set shiftwidth=4 " Indent with two spaces
set incsearch " Search as typing
set hlsearch " Highlight search results
set cursorline " Highligt the cursor line
set showmatch " When a bracket is inserted, briefly jump to the matching one
set scrolloff=10 " Always keep 10 lines after or before when scrolling
set sidescrolloff=5 " Always keep 5 lines after or before when side scrolling
set noshowmode " Don't display the current mode
set number " Show the line number
set updatetime=1000
set ignorecase " Search insensitive
set smartcase " ... but smart
let &showbreak="\u21aa " " Show a left arrow when wrapping text
set encoding=utf-8  " The encoding displayed.
set fileencoding=utf-8  " The encoding written to file.
" Open all cmd args in new tabs
execute ":silent tab all"

""" Prevent lag when hitting escape (https://github.com/sd65/MiniVim)
set ttimeoutlen=0
set timeoutlen=1000
au InsertEnter * set timeout
au InsertLeave * set notimeout

" Helper functions (https://github.com/sd65/MiniVim)
function! CreateShortcut(keys, cmd, where, ...)
  let keys = "<" . a:keys . ">"
  if a:where =~ "i"
    let i = (index(a:000,"noTrailingIInInsert") > -1) ? "" : "i"
    let e = (index(a:000,"noLeadingEscInInsert") > -1) ? "" : "<esc>"
    execute "imap " . keys . " " . e .  a:cmd . i
  endif
  if a:where =~ "n"
    execute "nmap " . keys . " " . a:cmd
  endif
  if a:where =~ "v"
    let k = (index(a:000,"restoreSelectionAfter") > -1) ? "gv" : ""
    let c = a:cmd
    if index(a:000,"cmdInVisual") > -1
      let c = ":<C-u>" . strpart(a:cmd,1)
    endif
    execute "vmap " . keys . " " . c . k
  endif
endfunction
function! TabIsEmpty()
    return winnr('$') == 1 && len(expand('%')) == 0 && line2byte(line('$') + 1) <= 2
endfunction
function! MyQuit()
  if TabIsEmpty() == 1
    q!
  else
    if &modified
      if (confirm("YOU HAVE UNSAVED CHANGES! Wanna quit anyway?", "&Yes\n&No", 2)==1)
        q!
      endif
    else
      q
    endif
  endif
endfunction
function! MySave()
  let cantSave = "echo \"Can't save the file: \" . v:exception | return"
  let notSaved = "redraw | echo 'This buffer was NOT saved!' | return"
  try
    silent w
  catch /:E45:\|:E505:\|:E212:/
    if (confirm("This buffer is read only! Wanna save it anyway?", "&Yes\n&No", 2)==1)
      try
        silent w!
      catch /:E212:/
        if (confirm("Can't open the file, do you want to save it as root?", "&Yes\n&No", 2)==1)
          try
            w !sudo tee % > /dev/null
            edit!
          catch
            exe cantSave
          endtry
        else
          exe notSaved
        endif
      catch
        exe cantSave
      endtry
    else
      exe notSaved
    endif
  catch /:E32:/
    if (confirm("This buffer has no file to be saved in! Wanna choose it?", "&Yes\n&No", 2)==1)
      call feedkeys("\<Esc>:w ")
    else
      exe notSaved
    endif
  catch
    exe cantSave
  endtry
  let time = strftime("%T")
  let file = expand('%:p')
  let permissions = getfperm(file)
  echom file . " saved at " . time | redraw
  echohl iGreen | echon "    SAVED     "
  echohl Green | echon  " " . GetFileSize() . ", " . time . ", " . permissions
  echohl None
endfunction
function! OpenLastBufferInNewTab()
    redir => ls_output
    silent exec 'ls'
    redir END
    let ListBuffers = reverse(split(ls_output, "\n"))
    for line in ListBuffers
      let title = split(line, "\"")[1]
      if title !~  "\[No Name"
        execute "tabnew +" . split(line, " ")[0] . "buf"
        break
      endif
    endfor
endfunction
function! ToggleColorColumn()
    if &colorcolumn != 0
        windo let &colorcolumn = 0
    else
        windo let &colorcolumn = 80
    endif
endfunction
function! MyPasteToggle()
  set invpaste
  echo "Paste" (&paste) ? "On" : "Off"
endfunction
function! OpenNetrw()
  if TabIsEmpty() == 1
    Explore
  else
    Texplore
  endif
endfunction
function! MenuNetrw()
  let c = input("What to you want to do? (M)ake a dir, Make a (F)ile, (R)ename, (D)elete : ")
  if (c == "m" || c == "M")
    normal d
  elseif (c == "f" || c == "F")
    normal %
  elseif (c == "r" || c == "R")
    normal R
  elseif (c == "d" || c == "D")
    normal D
  endif
endfunction
function! ToggleComment()
  if exists('b:comment_leader')
    if getline(".") =~ '^' . b:comment_leader
      " Uncomment the line
      execute 'silent s/^' . b:comment_leader .'\( \)\?//g'
      if exists('b:comment_ender')
        execute 'silent s/ ' . b:comment_ender .'$//g'
      endif
    elseif getline(".") =~ '^\s*$'
      " Empty lines: ignore
    else
      " Comment the line
      execute 'silent s/^/' . b:comment_leader .' /g'
      if exists('b:comment_ender')
        execute 'silent s/$/\ ' . b:comment_ender .'/g'
      endif
    endif
  else
    echom "Unknow comment's symbols for filetype"
  endif
endfunction

" Usefull shortcuts to enter insert mode (https://github.com/sd65/MiniVim)
nnoremap <CR> i<CR>
nnoremap <Backspace> i<Backspace>
nnoremap <Space> i<Space>

""" Shortcuts (https://github.com/sd65/MiniVim)
" Ctrl A - Begin Line
call CreateShortcut("C-a", "0", "inv")

" Ctrl E - End Line
call CreateShortcut("C-e", "$l", "inv")

" Ctrl S - Save
call CreateShortcut("C-s", ":call MySave()<CR>", "nv", "cmdInVisual", "restoreSelectionAfter")
call CreateShortcut("C-s", ":call MySave()<CR>i<Right>", "i", "noTrailingIInInsert")

" Home - Go To Begin
call CreateShortcut("Home", "gg", "inv")

" End - Go To End
call CreateShortcut("End", "G", "inv")

" Ctrl K - Delete Line
call CreateShortcut("C-k", "dd", "in")
call CreateShortcut("C-k", "d", "v")

" Ctrl Q - Duplicate Line
call CreateShortcut("C-q", "mjyyp`jjl", "i")
call CreateShortcut("C-q", "mjyyp`jj", "n")
call CreateShortcut("C-q", "y`]p", "v")

" Ctrl Down - Pagedown
call CreateShortcut("C-Down", "15j", "inv")

" Ctrl Up - Pageup
call CreateShortcut("C-Up", "15k", "inv")

" Ctrl Right - Next Word
call CreateShortcut("C-Right", "w", "nv")

" Ctrl Left - Previous Word
call CreateShortcut("C-Left", "b", "nv")

" Ctrl F - Find
call CreateShortcut("C-f", "/", "in", "noTrailingIInInsert")

" Ctrl H - Search and Replace
call CreateShortcut("C-h", ":%s/", "in", "noTrailingIInInsert")

" Ctrl G - Search and Replace on the line only
call CreateShortcut("C-g", ":s/", "in", "noTrailingIInInsert")

" Ctrl L - Delete all lines
call CreateShortcut("C-l", "ggdG", "in")

" Pageup - Move up Line
call CreateShortcut("PageUp", ":m-2<CR>", "inv", "restoreSelectionAfter")

" Pagedown - Move down Line
call CreateShortcut("PageDown", ":m+<CR>", "in")
call CreateShortcut("PageDown", ":m'>+<CR>", "v", "restoreSelectionAfter")

" Ctrl Pageup - Move up Line booster
call CreateShortcut("C-PageUp", ":m-16<CR>", "inv", "restoreSelectionAfter")

" Ctrl Pagedown - Move down Line boosted
call CreateShortcut("C-PageDown", ":m+15<CR>", "in")
call CreateShortcut("C-PageDown", ":m'>+15<CR>", "v", "restoreSelectionAfter")

" Ctrl C - Quit
call CreateShortcut("C-c", ":call MyQuit()<CR>", "inv", "cmdInVisual")

" Tab - Indent
call CreateShortcut("Tab", ">>", "n")
call CreateShortcut("Tab", ">", "v", "restoreSelectionAfter")

" Shift Tab - UnIndent
call CreateShortcut("S-Tab", "<<", "in")
call CreateShortcut("S-Tab", "<", "v", "restoreSelectionAfter")

" Ctrl Z - Undo
call CreateShortcut("C-z", "u", "in")

" Ctrl R - Redo
call CreateShortcut("C-r", "<C-r>", "in")

" Ctrl D - Suppr (the key)
call CreateShortcut("C-d", "<del>", "iv", "noLeadingEscInInsert", "noTrailingIInInsert")
call CreateShortcut("C-d", "x", "n")

" Ctrl T - New tab
call CreateShortcut("C-t", ":tabnew<CR>i", "inv", "noTrailingIInInsert", "cmdInVisual")

" Alt Right - Next tab
call CreateShortcut("A-Right", "gt", "inv")

" Alt Left - Previous tab
call CreateShortcut("A-Left", "gT", "inv")

" F2 - Paste toggle
call CreateShortcut("f2",":call MyPasteToggle()<CR>", "n")

" F3 - Line numbers toggle
call CreateShortcut("f3",":set nonumber!<CR>", "in")

" F4 - Panic Button
call CreateShortcut("f4","mzggg?G`z", "inv")

" F6 - Toggle color column at 80th char
call CreateShortcut("f6",":call ToggleColorColumn()<CR>", "inv")

" Ctrl O - Netrw (:Explore)
call CreateShortcut("C-o",":call OpenNetrw()<CR>", "inv", "noTrailingIInInsert", "cmdInVisual")

" Ctrl \ - Toggle comments
call CreateShortcut("C-\\", ":call ToggleComment()<CR>", "inv")

""" Vim-Plug Plugins
call plug#begin()

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-obsession'
Plug 'vim-airline/vim-airline'
Plug 'lifepillar/vim-solarized8'

call plug#end()