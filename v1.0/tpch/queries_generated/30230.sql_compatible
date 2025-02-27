
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_orderdate, 
           o_totalprice, o_orderpriority, o_comment, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O' 

    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_orderdate, 
           o.o_totalprice, o.o_orderpriority, o.o_comment, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE oh.level < 5 
)

SELECT 
    c.c_name,
    r.r_name AS region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-10-31'
  AND (c.c_acctbal IS NOT NULL AND c.c_acctbal > 100) 
GROUP BY c.c_name, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 
ORDER BY total_revenue DESC
LIMIT 10;
