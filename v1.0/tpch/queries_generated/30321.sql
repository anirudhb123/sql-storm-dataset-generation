WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
    
    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM 
        SupplierHierarchy sh
    JOIN 
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000.00
),

OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sh.level, -1) AS supplier_level,
    os.line_count,
    os.total_revenue,
    r.r_name AS region_name,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        ELSE CONCAT('Revenue: ', CAST(os.total_revenue AS VARCHAR), ' USD')
    END AS revenue_comment
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN 
    OrderStats os ON os.line_count > 0
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND (s.s_acctbal IS NULL OR s.s_acctbal >= 500.00)
ORDER BY 
    p.p_partkey, revenue_comment DESC;
