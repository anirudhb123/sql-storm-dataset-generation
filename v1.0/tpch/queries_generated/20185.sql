WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNKNOWN' 
            ELSE CAST(p.p_size AS VARCHAR) 
        END AS size_desc
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type LIKE '%Plastic%')
),
ExtremeOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND 
        o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_discount) <= 0.05
    UNION ALL
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_discount) > 0.15
),
SupplierPerformance AS (
    SELECT 
        fs.size_desc, 
        rs.s_name, 
        COUNT(DISTINCT eo.o_orderkey) AS orders_count,
        SUM(eo.total_revenue) AS total_revenue,
        CASE 
            WHEN SUM(eo.total_revenue) IS NULL THEN -1 ELSE SUM(eo.total_revenue) END AS adjusted_revenue
    FROM 
        FilteredParts fs
    LEFT JOIN 
        RankedSuppliers rs ON fs.p_partkey = rs.s_suppkey
    LEFT JOIN 
        ExtremeOrders eo ON eo.total_revenue > 50000
    GROUP BY 
        fs.size_desc, rs.s_name
)
SELECT 
    sp.size_desc,
    sp.s_name,
    COALESCE(sp.orders_count, 0) AS orders_count,
    COALESCE(sp.total_revenue, 0.00) AS total_revenue,
    100.0 * SUM(sp.adjusted_revenue) / NULLIF(SUM(NULLIF(sp.total_revenue, 0)), 0) AS revenue_ratio
FROM 
    SupplierPerformance sp
JOIN 
    region r ON sp.s_name LIKE CONCAT('%', r.r_name, '%')
WHERE 
    r.r_name IS NOT NULL 
GROUP BY 
    sp.size_desc, sp.s_name
HAVING 
    SUM(sp.adjusted_revenue) > 10000
ORDER BY 
    revenue_ratio DESC;
