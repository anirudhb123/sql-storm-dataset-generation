WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
    CASE 
        WHEN COUNT(DISTINCT ps.ps_suppkey) > 10 THEN 'High Supply'
        WHEN COUNT(DISTINCT ps.ps_suppkey) BETWEEN 5 AND 10 THEN 'Moderate Supply'
        ELSE 'Low Supply' 
    END AS supply_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier_hierarchy shp ON ps.ps_suppkey = shp.s_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= '2023-01-01' 
    AND l.l_shipdate < '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY 
    rank, total_revenue DESC;
