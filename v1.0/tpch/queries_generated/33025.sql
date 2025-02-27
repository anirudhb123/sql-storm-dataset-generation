WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level,
        CAST(s.s_name AS VARCHAR(100)) AS path
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1,
        CAST(sh.path || ' -> ' || s.s_name AS VARCHAR(100))
    FROM 
        supplier_hierarchy sh
    JOIN 
        partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_net_price,
    STRING_AGG(DISTINCT sh.path, ', ') AS supplier_paths
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
LEFT JOIN 
    supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE 
    (l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31') 
    AND (c.c_mktsegment IN ('BUILDING', 'FURNITURE') OR c.c_acctbal IS NULL)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_revenue DESC;
