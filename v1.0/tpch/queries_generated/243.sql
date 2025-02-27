WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY l.l_suppkey
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.s_name,
        COALESCE(ts.total_sales, 0) AS total_sales,
        rs.s_acctbal
    FROM RankedSuppliers rs
    LEFT JOIN nation n ON rs.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN TotalSales ts ON rs.s_suppkey = ts.l_suppkey
    WHERE rs.rnk <= 3
)
SELECT 
    sd.region,
    sd.nation,
    sd.s_name,
    sd.total_sales,
    sd.s_acctbal,
    CASE 
        WHEN sd.total_sales IS NULL THEN 'No Sales'
        WHEN sd.total_sales > 10000 THEN 'High Volume'
        WHEN sd.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM SupplierDetails sd
ORDER BY sd.region, sd.nation, sd.total_sales DESC;
