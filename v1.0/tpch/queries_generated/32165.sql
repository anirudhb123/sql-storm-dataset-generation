WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey,
           o_custkey,
           o_orderstatus,
           o_totalprice,
           o_orderdate,
           o_orderpriority,
           1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_orderstatus,
           o.o_totalprice,
           o.o_orderdate,
           o.o_orderpriority,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
SELECT r.r_name,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       MAX(o.o_totalprice) AS max_order_value,
       AVG(NULLIF(o.o_totalprice, 0)) AS avg_order_value
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
WHERE r.r_comment IS NOT NULL
GROUP BY r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(ps_supplycost) FROM partsupp)
   AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;
