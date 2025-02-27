WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        0 AS level,
        CAST(s.s_name AS varchar(255)) AS path
    FROM 
        supplier s
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        sh.level + 1,
        CAST(sh.path || ' -> ' || s.s_name AS varchar(255))
    FROM 
        supplier_hierarchy sh
    INNER JOIN 
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    INNER JOIN 
        supplier s ON ps.ps_partkey = s.s_suppkey
)
SELECT 
    sh.level,
    sh.path,
    COUNT(*) AS num_suppliers,
    SUM(s.s_acctbal) AS total_acctbal,
    MAX(s.s_comment) AS longest_comment
FROM 
    supplier_hierarchy sh
JOIN 
    supplier s ON sh.s_suppkey = s.s_suppkey
GROUP BY 
    sh.level, sh.path
ORDER BY 
    sh.level, total_acctbal DESC;
