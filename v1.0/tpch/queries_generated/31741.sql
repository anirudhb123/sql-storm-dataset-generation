WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS depth
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- suppliers with above average account balance

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        depth + 1
    FROM 
        partsupp ps
    JOIN 
        SalesHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        sh.depth < 3 -- limit depth for the hierarchy
)

SELECT 
    p.p_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(l.l_orderkey) AS lineitem_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    COALESCE(r.r_name, 'Unknown Region') AS region_name
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SalesHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    l.l_shipdate BETWEEN '2021-01-01' AND '2023-12-31'  -- filter for a specific date range
GROUP BY 
    p.p_partkey, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 -- only include parts with significant revenue
ORDER BY 
    revenue_rank, customer_count DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY; -- pagination for the results
