WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS order_year,
        EXTRACT(MONTH FROM o_orderdate) AS order_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY order_year, order_month
),
TopNSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 1 AND 10
    GROUP BY ps.ps_suppkey
    ORDER BY total_cost DESC
    LIMIT 10
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    SUM(ms.total_sales) AS total_monthly_sales,
    COUNT(DISTINCT sh.s_suppkey) AS high_balance_suppliers
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN MonthlySales ms ON ms.order_year = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE c.c_acctbal IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(c.c_custkey) > 5
ORDER BY total_monthly_sales DESC;

WITH CombinedSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    'Supplier Info' AS category,
    COALESCE(NULLIF(s.s_name, ''), 'Unknown Supplier') AS supplier_name,
    SUM(cl.total_lineitem_sales) AS total_sales
FROM supplier s
RIGHT OUTER JOIN CombinedSales cl ON s.s_suppkey = cl.o_orderkey
GROUP BY s.s_name
HAVING SUM(cl.total_lineitem_sales) > 1000
UNION ALL
SELECT 
    'Monthly Sales' AS category,
    CAST(order_month AS varchar) || '/' || CAST(order_year AS varchar) AS sales_month,
    SUM(total_sales) AS total_sales
FROM MonthlySales
WHERE order_year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY order_month, order_year
ORDER BY total_sales DESC;
