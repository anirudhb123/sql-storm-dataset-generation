WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty < 300
)
SELECT n.n_name AS nation_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS avg_returned_price,
       MAX(CASE WHEN c.c_acctbal IS NULL THEN 'Unknown' ELSE c.c_acctbal END) AS max_account_balance,
       STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
WHERE o.o_orderstatus IN ('O', 'F')
  AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_revenue DESC
LIMIT 50;
