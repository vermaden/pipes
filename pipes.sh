#!/usr/bin/env bash

f=75   # framerate
s=13   # straight probability
r=2000 # reset after ${r} chars
t=0    # number of used characters
c=1    # default color
n=0    # new random direction
l=0    # line

# /usr/bin/tput from FreeBSD base system is too limited
if ls -l /usr/local/bin/tput 1> /dev/null 2> /dev/null
then
  TPUT=/usr/local/bin/tput
else
  TPUT=tput
fi

w=$( ${TPUT} cols )  # terminal window width
h=$( ${TPUT} lines ) # terminal window height
x=$(( w/2 ))         # terminal window center vertical
y=$(( h/2 ))         # terminal window center horizontal

# colors array
v=( [00]="\x82" [01]="\x8c" [03]="\x90" [10]="\x98" [11]="\x80" [12]="\x90" \
    [21]="\x94" [22]="\x82" [23]="\x98" [30]="\x94" [32]="\x8c" [33]="\x80" )

while getopts "f:s:r:h" arg
do
  case ${arg} in
    (f) (( f=( ${OPTARG}>19 && ${OPTARG} < 101 )?${OPTARG}:${f} )) ;;
    (s) (( s=( ${OPTARG}>4  && ${OPTARG} < 16  )?${OPTARG}:${s} )) ;;
    (r) (( r=( ${OPTARG}>0                     )?${OPTARG}:${r} )) ;;
    (h)
      echo "usage: $( basename ${0} ) [OPTIONS]"
      echo "  OPTIONS:"
      echo "    -f [20-100]  framerate (default ${f})"
      echo "    -s [5-15]    probability of a straight fitting (default ${s})"
      echo "    -r [LIMIT]   reset after x characters (default ${r})"
      echo "    -h           help (this screen)"
      echo
      exit 1
      ;;
  esac
done

${TPUT} smcup # clear terminal
${TPUT} reset # reset terminal
${TPUT} civis # disable cursor display

# clear terminal after receiving CTRL-C
trap "${TPUT} rmcup; ${TPUT} reset; exit" SIGINT

while true
do
  # new position
  ((   ${l}%2   )) && (( x+=(${l}==1)?1:-1 ))
  (( !(${l}%2 ) )) && (( y+=(${l}==2)?1:-1 ))

  # change color on edge
  (( c=(${x}>${w} || ${x}<0 || ${y}>${h} || ${y}<0)?(${RANDOM}%7):$c ))
  (( x=(${x}>${w})?0:(( ${x}<0)?${w}:${x}) ))
  (( y=(${y}>${h})?0:(( ${y}<0)?${h}:${y}) ))

  # new random direction
  (( n=${RANDOM}%${s}-1 ))
  (( n=(${n}>1 || ${n}==0)?${l}:${l}+${n} ))
  (( n=(${n}<0)?3:${n}%4 ))

  # print
  ${TPUT} cup ${y} ${x}
  printf "\033[1;3${c}m\xe2\x94${v[${l}${n}]}"
  (( ${t}>${r} )) && ${TPUT} reset \
                  && ${TPUT} civis \
                  && t=0 || (( t++ ))
  l=${n}
  sleep $( echo "scale=5;1/${f}" | bc )
done
