WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.s_suppkey, s.s_name, s.s_acctbal, sh.hierarchy_level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT CONCAT(s.s_name, '(', sh.hierarchy_level, ')'), ', ') AS suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    r.r_regionkey, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_available_quantity DESC;
