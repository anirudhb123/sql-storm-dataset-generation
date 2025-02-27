WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
)
SELECT 
    n.n_name,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier_hierarchy sh ON l.l_suppkey = sh.s_suppkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey AND r.r_name IS NOT NULL
WHERE 
    l.l_shipdate >= '2022-01-01'
    AND (n.n_name LIKE '%land' OR n.n_name LIKE 'Fr%')
GROUP BY 
    n.n_name
HAVING 
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 500
ORDER BY 
    total_quantity DESC
FETCH FIRST 10 ROW ONLY;
