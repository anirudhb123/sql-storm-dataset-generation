WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_nationkey AS region_key, s_suppkey, s_name, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    
    UNION ALL
    
    SELECT p.n_nationkey, s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.region_key
    JOIN nation p ON p.n_nationkey = s.s_nationkey
    WHERE sh.level < 3 AND s.s_acctbal > sh.s_acctbal
)

SELECT r.r_name, AVG(sh.s_acctbal) AS avg_acctbal, COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       COUNT(DISTINCT c.c_custkey) AS customer_count, SUM(o.o_totalprice) AS total_order_value
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier_hierarchy sh ON n.n_nationkey = sh.region_key
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
WHERE sh.s_acctbal > 10000
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5 AND AVG(sh.s_acctbal) > 20000
ORDER BY total_order_value DESC;
