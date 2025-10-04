# 01 - Réseau docker/macvlan
echo "### docker network inspect macvlan_lan"; docker network inspect macvlan_lan | sed -n '1,80p'
echo
echo "### Interfaces"; ip -br a
echo "### Route"; ip r

# 02 - Conteneurs
echo "### docker ps"; docker ps
echo "### node1 local"; docker exec node1 sh -lc 'ip a; netstat -lnt; curl -sI http://127.0.0.1/ | head -1'
echo "### node2 local"; docker exec node2 sh -lc 'ip a; netstat -lnt; curl -sI http://127.0.0.1/ | head -1'
