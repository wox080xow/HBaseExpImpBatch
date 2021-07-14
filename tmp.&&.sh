function waw() {
  sleep 3
  echo $* # Workout!
}

waw 1 && waw 3 &
waw 2 && wait && waw 4