function waw() {
  sleep 3
  echo $* # Workout!
}

# 1 -> 2 -> 3 -> 4
# waw 1 && waw 3 &
# waw 2 && wait && waw 4

# 2 will not wait for 1 && 3
waw 1 && waw 3 &
waw 2 && waw 4