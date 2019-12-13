#!/bin/sh

if [ ! "$1" ]; then
  echo "usage: $0 file.c" && exit
fi

[ "${CFLAGS}" ] || CFLAGS="-O0 -gdwarf-2"
[ "${ODFLAGS}" ] || ODFLAGS="--disassembler-options=intel --source"
[ "${CC}" ] || CC=gcc

case "$1" in
  disasm)
    binary=$(mktemp /tmp/XXXXXX.o)
    ${CC} -c ${CFLAGS} -o "${binary}" "$2" &&
    objdump ${ODFLAGS} "${binary}"
    rm ${binary} >/dev/null 2>&1
    exit 0
    ;;
  run)
    binary=$(mktemp /tmp/XXXXXX)
    ${CC} ${CFLAGS} -o "${binary}" "$2" &&
    timeout ${TIMEOUT:-1} "${binary}"
    rm "${binary}" >/dev/null 2>&1
    exit 0
    ;;
  *) ;;
esac

vim --cmd "
autocmd BufWritePost * :
execute bufwinnr('disassembly.S') . 'wincmd w' |
let p = getpos('.') |
execute 'silent %!\"$0\" disasm \"$1\"' |
call setpos('.', p) |
execute bufwinnr('output.txt') . 'wincmd w' |
execute 'silent %!\"$0\" run \"$1\"' |
execute bufwinnr('$1') . 'wincmd w'
" \
  -c ":w" \
  -c "
:
let wsrc=bufwinnr('$1') |
let wout=bufwinnr('output.txt') |
let wdis=bufwinnr('disassembly.S') |
execute wout . 'wincmd w' | resize 3 |
execute wsrc . 'wincmd w' | let srch=winheight(0) |
execute wdis . 'wincmd w' | let dish=winheight(0) |
let h=(srch+dish)/2 |
execute wsrc . 'wincmd w' | execute 'resize' . h
" \
  -o "$1" "disassembly.S" "output.txt"
