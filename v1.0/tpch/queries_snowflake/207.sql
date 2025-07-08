
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY s.s_suppkey, s.s_name
), SalesRanked AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM SupplierSales s
), NationalSales AS (
    SELECT 
        n.n_name,
        SUM(ss.total_sales) AS national_total_sales,
        COUNT(DISTINCT ss.s_suppkey) AS total_suppliers
    FROM nation n
    LEFT JOIN SupplierSales ss ON ss.s_suppkey IN (
        SELECT s.s_suppkey
        FROM supplier s
        WHERE s.s_nationkey = n.n_nationkey
    )
    GROUP BY n.n_name
)
SELECT 
    nr.n_name,
    COALESCE(n.national_total_sales, 0) AS national_total_sales,
    COALESCE(n.total_suppliers, 0) AS total_suppliers,
    COUNT(DISTINCT sr.s_suppkey) FILTER (WHERE sr.sales_rank <= 5) AS top_suppliers_count
FROM nation nr
LEFT JOIN NationalSales n ON nr.n_name = n.n_name
LEFT JOIN SalesRanked sr ON sr.s_suppkey IN (
    SELECT s.s_suppkey
    FROM supplier s
    WHERE s.s_nationkey = nr.n_nationkey
)
GROUP BY nr.n_name, n.national_total_sales, n.total_suppliers
ORDER BY national_total_sales DESC, nr.n_name;
