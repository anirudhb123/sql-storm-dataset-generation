WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)
SELECT 
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    p.p_name AS part_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(oh.o_totalprice) AS avg_order_value,
    MAX(oh.o_orderdate) AS last_order_date
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON l.l_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE 
    l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    AND (c.c_acctbal IS NOT NULL OR s.s_acctbal > 1000)
GROUP BY 
    c.c_name, n.n_name, p.p_name
HAVING 
    total_revenue > 5000
ORDER BY 
    total_revenue DESC, customer_name;
