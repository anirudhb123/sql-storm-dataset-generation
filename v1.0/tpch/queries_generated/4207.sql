WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
      AND s.s_acctbal > 100.00
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_sales IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    AVG(ts.total_sales) AS avg_sales_per_supplier,
    MAX(ts.total_sales) AS max_sales
FROM TopSuppliers ts
JOIN nation n ON ts.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ts.sales_rank <= 10
GROUP BY r.r_name
ORDER BY r.r_name;
