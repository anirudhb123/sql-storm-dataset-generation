WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_per_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) 
            FROM supplier 
            WHERE s_acctbal IS NOT NULL
        )
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        part p 
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(ps.ps_suppkey) > 0
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_customerkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_shipdate >= DATEADD(day, -30, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_customerkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    rs.s_name,
    o.total_revenue,
    COALESCE(o.total_revenue, 0) AS revenue_fallback,
    CASE 
        WHEN rs.rank_per_region IS NULL THEN 'No suppliers'
        ELSE 'Suppliers available'
    END AS supplier_status
FROM 
    FilteredParts p
LEFT JOIN 
    RankedSuppliers rs ON p.supplier_count = rs.rank_per_region
FULL OUTER JOIN 
    RecentOrders o ON o.o_customerkey = p.p_partkey
WHERE 
    (rs.s_acctbal IS NULL OR rs.s_acctbal < 5000.00)
AND 
    p.p_size BETWEEN 10 AND 20
ORDER BY 
    supplier_status, revenue_fallback DESC, p.p_partkey;
