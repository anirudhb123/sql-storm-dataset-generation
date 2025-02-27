WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) as order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) as order_rank
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate > oh.o_orderdate
)

SELECT 
    c.c_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) * 100 AS avg_discount_percentage,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
INNER JOIN nation n ON c.c_nationkey = n.n_nationkey
INNER JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE o.o_orderdate >= '1997-01-01'
AND l.l_shipdate IS NULL
GROUP BY c.c_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;