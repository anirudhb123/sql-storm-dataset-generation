WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierSales AS (
    SELECT
        sh.s_suppkey,
        sh.s_name,
        SUM(l.l_extendedprice) AS total_supplier_sales,
        s.s_nationkey
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY sh.s_suppkey, sh.s_name, s.s_nationkey
),
MaxSales AS (
    SELECT 
        s_nationkey, 
        MAX(total_sales) AS max_sales
    FROM OrderSummary
    GROUP BY s_nationkey
)
SELECT 
    n.n_name,
    SUM(COALESCE(ss.total_supplier_sales, 0)) AS total_sales_from_nation,
    MAX(ms.max_sales) AS max_sales_per_order
FROM nation n
LEFT JOIN SupplierSales ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN MaxSales ms ON n.n_nationkey = ms.s_nationkey
WHERE n.n_comment IS NOT NULL
GROUP BY n.n_name
HAVING SUM(COALESCE(ss.total_supplier_sales, 0)) > (SELECT AVG(total_sales) FROM OrderSummary)
ORDER BY total_sales_from_nation DESC;
