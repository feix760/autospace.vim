if exists('loaded_autospace_js')
    finish
endif
let loaded_autospace_js = 1

au CursorMovedI *.js call s:Main()

fun s:Main()
    if exists("g:enable_autospace") && !g:enable_autospace
        let b:buffer_len = s:GetBufferLen()
        return
    endif
    if !exists("b:buffer_len")
        let b:buffer_len = s:GetBufferLen()
    endif
    let curr_len = s:GetBufferLen()
    let diff_len = curr_len - b:buffer_len
    if diff_len > 0 && diff_len <= 3
        call s:JsTypingHandler()
    endif
    let b:buffer_len = s:GetBufferLen()
endfun

fun! s:GetBufferLen()
    return line2byte(line("$")+1)
endfun

let s:jsVarExp = "[a-zA-Z0-9_\\$#@'\\])\"]"
let s:jsKeywords = '|abstract|arguments|boolean|break|byte|case|catch|char|class|const|continue|debugger|default|delete|do|double|else|enum|eval|export|extends|false|final|finally|float|for|function|goto|if|implements|import|in|instanceof|int|interface|let|long|native|new|null|package|private|protected|public|return|short|static|super|switch|synchronized|this|throw|throws|transient|true|try|typeof|var|void|volatile|while|with|yield|'

fun! s:isKeyword(w)
    return stridx(s:jsKeywords, '|'.a:w.'|') != -1
endfun

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

fun s:JsTypingHandler()
    let pos = col('.') - 1
    let prevStr = s:CursorSubLine(0)
    let prevText = s:CursorSubLine(100)
    let note = s:IsInNote()
    if note != ''
        " echo 'in note:' note
        if note == '"' && prevStr[strlen(prevStr) - 1] == '"'
            call s:CurrentLineReplace(pos - 1, pos, '"双')
        endif
        return
    endif
    let prev = s:IsPrev(prevStr, '[；：，。‘’”“？（）！]')
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = printf('%s全角', prev)
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif

    let prev = s:IsPrev(prevStr, '\s*\(==\|= =\|!=\|! =\)')
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = printf(' %s= ', substitute(prev, '\s\+', '', 'g'))
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif

    let prev = s:IsPrev(prevStr, '< =\|> =\|= =\|! =\|== =\|& &\|| |\|/ /\|!= =')
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = substitute(prev, '\s\+', '', 'g')
        let rep = printf('%s ', rep)
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif
    
    let prev = s:IsPrev(prevStr, '\s\?\(+ +\|- -\)')
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = substitute(prev, '\s', '', 'g')
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif
    
    let m = matchlist(prevStr, printf('\(%s\+\)\([+*%><=&/|?-]\)$', s:jsVarExp))
    if len(m) && !s:isKeyword(m[1])
        let prev = m[2]
        let beg = pos - strlen(prev)
        let rep = printf(' %s ', prev)
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif

    let m = matchlist(prevStr, '\(function\|yield\)\*$')
    if len(m)
        call s:CurrentLineReplace(pos, pos, ' ')
        return 
    endif
    
    let prev = s:IsPrev(prevStr, printf('[,:;]\(%s\)', s:jsVarExp), 1)
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = printf(' %s', prev)
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif
    
    let prev = s:IsPrev(prevStr, '\(\s\|^\)\(if\|for\|while\|switch\|catch\)\((\)', 3)
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = printf(' %s', prev)
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif
    
    let prev = s:IsPrev(prevStr, '}\([a-zA-Z]\)', 1)
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = printf(' %s', prev)
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif
    
    let prev = s:IsPrev(prevStr, '\(try\|else\|else if\|finaly\|do\|)\)\({\)', 2)
    if strlen(prev) > 0
        let beg = pos - strlen(prev)
        let rep = printf(' %s', prev)
        call s:CurrentLineReplace(beg, pos, rep)
        return
    endif

    let prev = s:IsPrev(prevText, ' \+[\n\r]')
    if strlen(prev) > 0
        let prevLine = line('.') - 1
        call setline(prevLine, substitute(getline(prevLine), ' \+$', '', ''))
        return
    endif
    
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

fun s:IsPrev(str, regex, ...)
    let regex = printf('\(%s\)$', a:regex)
    let match = matchlist(a:str, regex)
    if !exists('a:1')
        let group = 0
    else
        let group = a:1 + 1
    endif
    if empty(match)
        return ''
    else 
        return match[group]
    endif
endfun

fun s:CurrentLineReplace(beg, end, str)
    let preLine = getline('.')
    let newLine = strpart(preLine, 0, a:beg).a:str.strpart(preLine, a:end)
    let c = col('.')
    call setline('.', newLine)
    call cursor(line('.'), c + (strlen(a:str) - (a:end - a:beg)))
endfun

