WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(o.o_totalprice) AS avg_order_value,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY total_revenue DESC) AS revenue_rank
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (c.c_acctbal > 100 OR c.c_comment IS NULL)
GROUP BY r.r_name
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_revenue DESC;
