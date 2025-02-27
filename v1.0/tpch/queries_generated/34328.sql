WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT oh.o_orderkey) AS total_orders,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    OrderHierarchy oh ON l.l_orderkey = oh.o_orderkey
WHERE 
    l.l_shipdate >= '2023-01-01'
    AND l.l_shipdate < '2024-01-01'
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    n.n_nationkey, n.n_name
HAVING 
    COUNT(DISTINCT oh.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
