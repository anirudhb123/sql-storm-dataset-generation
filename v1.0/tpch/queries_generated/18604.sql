SELECT p_pname, SUM(l_quantity) AS total_quantity
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
GROUP BY p_pname
ORDER BY total_quantity DESC
LIMIT 10;
