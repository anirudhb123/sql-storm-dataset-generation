WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
AggregatedSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
)
SELECT 
    ph.supplier_name,
    rg.r_name AS region_name,
    as_order.total_sales,
    as_order.avg_quantity,
    CASE 
        WHEN as_order.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM SupplierHierarchy ph
LEFT JOIN TopRegions rg ON ph.s_nationkey = rg.rn
LEFT JOIN AggregatedSales as_order ON ph.s_suppkey = as_order.o_orderkey
WHERE rg.rn <= 5
ORDER BY total_sales DESC, ph.level;
