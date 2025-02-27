WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank 
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2 
        WHERE c2.c_nationkey = c.c_nationkey
    )
    UNION ALL
    SELECT ch.c_custkey, ch.c_name, ch.c_nationkey, ch.c_acctbal, ROW_NUMBER() OVER (PARTITION BY ch.c_nationkey ORDER BY ch.c_acctbal DESC) 
    FROM customer_hierarchy ch
    JOIN supplier s ON ch.c_nationkey = s.s_nationkey
)
SELECT p.p_partkey, p.p_name, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
       CASE WHEN MAX(r.r_name) IS NULL THEN 'Unknown Region' ELSE MAX(r.r_name) END AS region_name,
       (SELECT COUNT(DISTINCT o.o_orderkey) 
        FROM orders o 
        WHERE o.o_custkey IN (SELECT c_custkey FROM customer_hierarchy)) AS total_orders,
       STRING_AGG(DISTINCT n.n_name, ', ') FILTER (WHERE n.n_name IS NOT NULL) AS supplier_nations
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN partsupp ps ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
GROUP BY p.p_partkey, p.p_name, s.s_name
HAVING COUNT(DISTINCT l.l_orderkey) > 10 AND SUM(l.l_quantity) IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 10;
