WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS hierarchy_level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000

    UNION ALL

    SELECT 
        s.s_suppkey,
        sh.s_name,
        sh.s_acctbal + s.s_acctbal AS cumulative_acctbal,
        sh.hierarchy_level + 1
    FROM 
        supplier s
    INNER JOIN 
        SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE 
        s.s_acctbal > 1000
)

SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE NULL END) AS avg_discount_price,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    region r ON c.c_nationkey = r.r_regionkey
LEFT JOIN 
    SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
WHERE 
    o.o_orderdate >= '2023-01-01' 
    AND o.o_orderdate < '2024-01-01'
    AND r.r_name IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_availqty < 100)
ORDER BY 
    revenue_rank, total_revenue DESC;
