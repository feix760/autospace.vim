if exists('au_javascript')
  finish
endif
let au_javascript = 1

fun! au_javascript#typing()
  let pos = col('.') - 1
  let prevStr = s:CursorSubLine(0)
  let prevText = s:CursorSubLine(100)
  let note = s:IsInNote()

  " jsx skip
  if !empty(matchlist(prevStr, '^\s*<\(a\|div\|ul\|span\)\>.*$')) 
    return
  endif

  " 双引号"提示
  if note != ''
    if note == '"' && prevStr[strlen(prevStr) - 1] == '"'
      call s:CurrentLineReplace(pos - 1, pos, '"双')
    endif
    return
  endif

  " 中文符号
  let prev = s:IsPrev(prevStr, '[；：，。‘’”“？（）！]')
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf('%s全角', prev)
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " == -> ===
  let prev = s:IsPrev(prevStr, '\s*\(==\|= =\|!=\|! =\)')
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf(' %s= ', substitute(prev, '\s\+', '', 'g'))
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " 'a < =' -> 'a <= '
  let prev = s:IsPrev(prevStr, '< =\|> =\|= =\|! =\|== =\|& &\|| |\|/ /\|!= =\|= >')
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf('%s ', substitute(prev, '\s\+', '', 'g'))
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " 'a + +' -> 'a++'
  let prev = s:IsPrev(prevStr, '\s\?\(+ +\|- -\)')
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = substitute(prev, '\s', '', 'g')
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " 'a+' -> 'a + '
  let prev = s:IsPrev(prevStr, printf('%s\+\zs[+*%><=&/|-]', s:varChat))
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf(' %s ', prev)
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " 'function*' -> 'function* '
  let prev = s:IsPrev(prevStr, '\<\(function\|yield\)\*')
  if strlen(prev) > 0
    call s:CurrentLineReplace(pos, pos, ' ')
    return 
  endif

  " ';if' -> '; if'
  let prev = s:IsPrev(prevStr, printf('[,:;]\zs%s', s:varChat))
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf(' %s', prev)
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " 'if(' => 'if ('
  let prev = s:IsPrev(prevStr, '\<\(if\|for\|while\|switch\|catch\)\zs(')
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf(' %s', prev)
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " '}e' -> '} e' ('} else')
  let prev = s:IsPrev(prevStr, '}\zs[a-zA-Z]')
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf(' %s', prev)
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " 'try{' -> 'try {'
  " 'if (a){' -> 'if (a) {'
  let prev = s:IsPrev(prevStr, "[a-zA-Z_)'\"]\\zs{")
  if strlen(prev) > 0
    let beg = pos - strlen(prev)
    let rep = printf(' %s', prev)
    call s:CurrentLineReplace(beg, pos, rep)
    return
  endif

  " '; \n' -> ';\n'
  let prev = s:IsPrev(prevText, ' \+[\n\r]')
  if strlen(prev) > 0
    let prevLine = line('.') - 1
    call setline(prevLine, substitute(getline(prevLine), ' \+$', '', ''))
    return
  endif
endfun

let s:varChat = '[a-zA-Z0-9_\-\$#@]'

fun! s:CursorSubLine(count)
  let pos = col('.') - 1
  let preStr=strpart(getline('.'), 0, pos)
  let currLine = line('.')
  if a:count > 0 && currLine > 1
    let beg = currLine - a:count
    let end = currLine - 1
    if beg < 1
      let beg = 1
    endif
    let lines = getline(beg, end)
  else
    let lines = []
  endif
  call add(lines, preStr)
  return join(lines, "\n")
endfun


fun! s:IsInNote()
  let prevStr = s:CursorSubLine(0)
  let prevText = s:CursorSubLine(100)
  if s:IsPrev(prevText, '\n\s*/\*\([^*]\|\*[^/]\|\*$\)*') != ''
    return '/*'
  endif
  let pair = ''
  let i = 0
  let len = strlen(prevStr)
  while i < len
    let ch = prevStr[i]
    if pair != ''
      " escape
      if ch == '\'
        " skip next char
        let i += 1
      elseif pair == ch
        " leave pair
        let pair = ''
      endif
    elseif stridx("\"'`/", ch) != -1
      " inline cmt
      if ch == '/' && i + 1 < len && prevStr[i + 1] == '/'
        return '//'
      endif
      " in pair
      let pair = ch
    endif
    let i += 1
  endwhile
  return pair
endfun

fun s:IsPrev(str, regex)
  let regex = printf('%s$', a:regex)
  let match = matchlist(a:str, regex)
  if empty(match)
    return ''
  else
    return match[0]
  endif
endfun

fun s:CurrentLineReplace(beg, end, str)
  let preLine = getline('.')
  let newLine = strpart(preLine, 0, a:beg).a:str.strpart(preLine, a:end)
  let c = col('.')
  call setline('.', newLine)
  call cursor(line('.'), c + (strlen(a:str) - (a:end - a:beg)))
endfun

