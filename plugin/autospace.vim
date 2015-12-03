if exists('loaded_autospace')
    finish
endif
let loaded_autospace = 1
let enable_autospace = 1

fun! AutospaceToggle()
    if g:enable_autospace
        let g:enable_autospace = 0
        echo 'disable autospace'
    else
        let g:enable_autospace = 1
        echo 'enable autospace'
    endif
endfun

com! AutospaceToggle call AutospaceToggle()
