WITH RECURSIVE order_hierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, o_totalprice
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.orderdate, o.orderstatus, o.totalprice
    FROM orders o
    INNER JOIN order_hierarchy oh ON oh.o_orderkey = o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_quantity) AS max_quantity,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
  AND (n.n_name IS NOT NULL OR r.r_name IS NULL) 
  AND l.l_returnflag = 'N'
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
