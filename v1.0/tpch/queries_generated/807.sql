WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationSupplierSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(so.total_sales), 0) AS total_sales,
        COUNT(DISTINCT so.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN SupplierOrderSummary so ON n.n_nationkey = so.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
TopNations AS (
    SELECT 
        nns.n_name,
        nns.total_sales,
        nns.supplier_count,
        RANK() OVER (ORDER BY nns.total_sales DESC) AS sales_rank
    FROM NationSupplierSales nns
)
SELECT 
    tn.n_name,
    tn.total_sales,
    tn.supplier_count,
    CASE 
        WHEN tn.sales_rank <= 3 THEN 'Top Supplier Nation'
        ELSE 'Other Nation'
    END AS ranking_category
FROM TopNations tn
WHERE tn.total_sales > 0
ORDER BY tn.sales_rank, tn.total_sales DESC;
