WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_orderdate, 
        o_totalprice, 
        o_orderstatus,
        1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)

SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts,
    ROW_NUMBER() OVER (PARTITION BY c.c_name ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS order_rank
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE o.o_orderdate >= '1997-01-01'
AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY c.c_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;