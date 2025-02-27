WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_nationkey,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000

    UNION ALL

    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_nationkey,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        SalesHierarchy sh ON c.c_nationkey = sh.c_nationkey
    WHERE 
        c.c_acctbal BETWEEN 1000 AND 5000
)

SELECT 
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    SUM(CASE 
            WHEN p.p_retailprice IS NULL THEN 0 
            ELSE p.p_retailprice * ps.ps_availqty 
        END) AS total_inventory_value,
    AVG(COALESCE(l.l_discount, 0)) AS average_discount,
    MAX(l.l_extendedprice) AS max_selling_price,
    MIN(l.l_extendedprice) AS min_selling_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_size > 10 
    AND EXISTS (
        SELECT 1 
        FROM SalesHierarchy sh 
        WHERE sh.c_nationkey = n.n_nationkey
    )
GROUP BY 
    r.r_name
ORDER BY 
    total_suppliers DESC,
    total_inventory_value DESC;
