WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_suppkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        COALESCE(t.total_revenue, 0) AS total_revenue
    FROM 
        supplier s
    LEFT JOIN 
        TotalSales t ON s.s_suppkey = t.l_suppkey
),
SufficientSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_revenue 
    FROM 
        SupplierSales sp
    WHERE 
        sp.total_revenue > (SELECT AVG(total_revenue) FROM SupplierSales)
)
SELECT 
    s.s_name AS supplier_name,
    r.region_name,
    s.total_revenue,
    CASE 
        WHEN s.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    CONCAT(s.s_name, ' - ', r.region_name) AS supplier_region
FROM 
    SufficientSuppliers s
LEFT JOIN 
    RankedSuppliers r ON s.s_suppkey = r.s_suppkey
WHERE 
    r.rn <= 3
ORDER BY 
    s.total_revenue DESC
LIMIT 10;
