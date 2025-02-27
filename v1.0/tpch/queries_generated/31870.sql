WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) FROM supplier
        )
    UNION ALL
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.s_nationkey,
        sh.level + 1
    FROM 
        supplier sp
    JOIN 
        SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE 
        sp.s_acctbal > (0.75 * (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = sh.s_nationkey)) 
)
, PartSuppliers AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.l_discount) AS median_discount,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    PartSuppliers ps ON l.l_partkey = ps.p_partkey
JOIN 
    SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
WHERE 
    l.l_shipdate >= '2023-01-01' 
    AND l.l_shipdate < '2023-12-31'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    total_revenue > (
        SELECT AVG(total_revenue) FROM (
            SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
            FROM 
                lineitem l
            JOIN 
                orders o ON l.l_orderkey = o.o_orderkey
            WHERE 
                l.l_shipdate >= '2023-01-01' 
                AND l.l_shipdate < '2023-12-31'
            GROUP BY 
                l.l_orderkey
        ) AS sub
    )
ORDER BY 
    total_revenue DESC
LIMIT 10;
