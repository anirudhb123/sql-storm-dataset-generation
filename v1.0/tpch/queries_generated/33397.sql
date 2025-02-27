WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, 1 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')

    UNION ALL

    SELECT s.n_nationkey, sp.s_suppkey, sp.s_name, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
MonthlySales AS (
    SELECT 
        o.o_orderkey,
        DATE_TRUNC('month', o.o_orderdate) AS sales_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, sales_month
),
RankedSales AS (
    SELECT 
        ms.sales_month,
        RANK() OVER (PARTITION BY ms.sales_month ORDER BY SUM(ms.total_sales) DESC) AS sales_rank,
        COUNT(ms.o_orderkey) AS order_count
    FROM MonthlySales ms
    GROUP BY ms.sales_month
),
SuppliersWithHighSales AS (
    SELECT 
        sh.s_suppkey,
        sh.s_name,
        rs.sales_month,
        rs.order_count
    FROM SupplierHierarchy sh
    JOIN RankedSales rs ON sh.level <= 3
    WHERE rs.sales_rank <= 5
)
SELECT 
    s.s_name AS supplier_name,
    COALESCE(SUM(p.ps_supplycost * p.ps_availqty), 0) AS total_cost,
    AVG(c.c_acctbal) AS average_customer_balance,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_served
FROM SuppliersWithHighSales s
LEFT JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
LEFT JOIN customer c ON c.c_nationkey = s.s_nationkey
LEFT JOIN nation n ON n.n_nationkey = c.c_nationkey
WHERE c.c_acctbal IS NOT NULL OR c.c_acctbal > 1000
GROUP BY s.s_name
HAVING AVG(c.c_acctbal) > 500
ORDER BY total_cost DESC;
