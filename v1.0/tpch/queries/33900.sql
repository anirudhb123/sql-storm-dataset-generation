WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, 1 AS level
    FROM orders
    WHERE o_orderdate >= DATE '1997-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_custkey = oh.o_custkey)
)
SELECT 
    c.c_name,
    r.r_name AS region_name,
    SUM(o.o_totalprice) AS total_spent,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS total_returns,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE o.o_orderstatus IN ('O', 'F')
AND (o.o_totalprice - l.l_discount * l.l_extendedprice) > 1000
GROUP BY c.c_name, r.r_name
HAVING SUM(o.o_totalprice) > 5000
ORDER BY total_spent DESC
LIMIT 10;