WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           oh.order_rank + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
                           AND o.o_orderdate > oh.o_orderdate
)
SELECT c.c_name, COUNT(DISTINCT oh.o_orderkey) AS total_orders,
       SUM(oh.o_totalprice) AS total_revenue, 
       MAX(oh.o_orderdate) AS last_order_date,
       AVG(oh.o_totalprice) AS avg_order_value,
       DENSE_RANK() OVER (ORDER BY SUM(oh.o_totalprice) DESC) AS revenue_rank
FROM customer c
LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
LEFT JOIN lineitem li ON li.l_orderkey = oh.o_orderkey
LEFT JOIN partsupp ps ON ps.ps_partkey = li.l_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE c.c_acctbal IS NOT NULL
  AND c.c_mktsegment IN ('BUILDING', 'FURNITURE')
  AND (li.l_discount < 0.05 OR li.l_discount IS NULL)
GROUP BY c.c_name
HAVING total_orders > 1
ORDER BY total_revenue DESC
LIMIT 10;
