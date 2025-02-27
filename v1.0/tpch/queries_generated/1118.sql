WITH RankedLineItems AS (
    SELECT 
        l_orderkey,
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rn
    FROM 
        lineitem
    GROUP BY 
        l_orderkey, l_partkey
),
TopLineItems AS (
    SELECT 
        l_orderkey,
        l_partkey,
        revenue
    FROM 
        RankedLineItems
    WHERE 
        rn <= 3
),
SupplierRevenue AS (
    SELECT
        ps.s_suppkey,
        SUM(t.revenue) AS total_revenue
    FROM 
        TopLineItems t
    JOIN 
        partsupp ps ON t.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.s_suppkey
)

SELECT 
    s.s_suppkey,
    s.s_name,
    COALESCE(sr.total_revenue, 0) AS total_supplier_revenue,
    CASE 
        WHEN sr.total_revenue >= 100000 THEN 'High'
        WHEN sr.total_revenue >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM 
    supplier s
LEFT JOIN 
    SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
WHERE 
    s.s_acctbal IS NOT NULL
ORDER BY 
    total_supplier_revenue DESC;
