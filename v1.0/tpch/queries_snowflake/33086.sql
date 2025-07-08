
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS parts_count,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT sh.s_suppkey, sh.s_name, s.s_nationkey, sh.s_acctbal,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey) AS parts_count,
           level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.s_nationkey AND sh.s_acctbal < s.s_acctbal
)

SELECT p.p_name, 
       SUM(CASE 
               WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
               ELSE 0 
           END) AS total_revenue,
       RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
       s.s_name, 
       n.n_name, 
       CASE 
           WHEN SUM(CASE WHEN l.l_quantity > 100 THEN l.l_quantity END) IS NULL THEN 'No orders over 100 units'
           ELSE 'Has orders over 100 units' 
       END AS order_summary
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE o.o_orderstatus = 'O'
GROUP BY p.p_name, p.p_partkey, s.s_name, n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY revenue_rank, total_revenue DESC
LIMIT 10;
