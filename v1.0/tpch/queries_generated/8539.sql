WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
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
        s.s_acctbal,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
    SUM(sh.s_acctbal) AS total_acctbal,
    AVG(sh.level) AS avg_hierarchy_level
FROM 
    supplier_hierarchy sh
JOIN 
    nation n ON sh.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_suppliers DESC, total_acctbal DESC
LIMIT 10;
