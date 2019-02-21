if exists('loaded_autospace')
  finish
endif
let loaded_autospace = 1

let g:enable_autospace = 1
fun! AutospaceToggle()
  if g:enable_autospace
    let g:enable_autospace = 0
    echo 'disable autospace'
  else
    let g:enable_autospace = 1
    echo 'enable autospace'
  endif
endfun

fun! s:OnCursorMoved()
  if g:enable_autospace
    if !exists("b:buffer_len")
      let b:buffer_len = s:GetBufferLen()
    endif
    let diff_len = s:GetBufferLen() - b:buffer_len
    if diff_len > 0 && diff_len <= 3
      if exists("b:do_au_javascript") && b:do_au_javascript == 1
        cal au_javascript#typing()
      endif
    endif
  endif
  let b:buffer_len = s:GetBufferLen()
endfun

fun! s:GetBufferLen()
  return line2byte(line("$")+1)
endfun

com! AutospaceToggle call AutospaceToggle()

au CursorMovedI * call s:OnCursorMoved()
