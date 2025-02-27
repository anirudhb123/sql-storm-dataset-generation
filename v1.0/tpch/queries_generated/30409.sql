WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= DATE '2022-01-01'
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(l.l_discount) AS avg_discount,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region,
    PERCENT_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND (l.l_returnflag = 'N' OR l.l_tax IS NOT NULL)
GROUP BY 
    c.c_name, r.r_name
ORDER BY 
    total_sales DESC, c.c_name
FETCH FIRST 50 ROWS ONLY;
