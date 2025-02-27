WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)
SELECT 
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    r.r_name AS region,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ps.ps_availqty > 0
  AND r.r_name IN (SELECT DISTINCT r_name FROM region WHERE r_comment LIKE '%enabled%')
  AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY c.c_name, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(total_revenue) FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
        FROM lineitem l 
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderdate >= '1997-01-01'
        GROUP BY o.o_orderkey
    ) AS revenue_table
)
ORDER BY r.r_name, total_revenue DESC;