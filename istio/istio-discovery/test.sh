# PARALLELISM=3

# for i in {1..$PARALLELISM};
# do
#   echo sre-test-${i}
# done


PARALLELISM=10
for ((i=0; i<=PARALLELISM; i++)); do
   echo "$i"
done