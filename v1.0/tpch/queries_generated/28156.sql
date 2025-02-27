SELECT p.p_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
       SUM(ps.ps_availqty) AS total_available_quantity, 
       AVG(s.s_acctbal) AS average_supplier_balance,
       SUBSTRING(p.p_comment, 1, 23) AS short_comment,
       CONCAT('Region:', r.r_name, ' - ', n.n_name) AS region_nation
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_brand LIKE 'Brand%'
  AND s.s_acctbal > 5000
  AND p.p_size IN (large, medium)
GROUP BY p.p_name, r.r_name, n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY total_available_quantity DESC, average_supplier_balance DESC;
