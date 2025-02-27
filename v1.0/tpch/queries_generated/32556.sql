WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderkey <> oh.o_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
)

SELECT
    n.n_name AS nation,
    COUNT(DISTINCT cu.c_custkey) AS total_customers,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    AVG(COALESCE(l.l_extendedprice, 0) / NULLIF(l.l_quantity, 0)) AS avg_price_per_unit,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_orders,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer cu ON o.o_custkey = cu.c_custkey
LEFT JOIN 
    OrderHierarchy oh ON oh.o_custkey = cu.c_custkey
WHERE 
    o.o_orderstatus IN ('O', 'F')
    AND l.l_shipdate >= DATE '2022-01-01'
GROUP BY 
    n.n_nationkey, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue_rank;
