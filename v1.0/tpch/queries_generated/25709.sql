WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_suppkey
),
SupplierSales AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        ts.total_sales
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        TotalSales ts ON rs.s_suppkey = ts.l_suppkey
    WHERE 
        rs.rnk <= 5
)
SELECT 
    ss.s_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    REPLACE(SUBSTRING(ss.s_comment, 1, 30), ' ', '_') AS short_comment
FROM 
    SupplierSales ss
ORDER BY 
    total_sales DESC
LIMIT 10;
