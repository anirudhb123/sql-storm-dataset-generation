WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) * 1.5 FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
SalesByRegion AS (
    SELECT n.n_name AS region_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
SupplierSales AS (
    SELECT s.s_name, SUM(l.l_extendedprice) AS supplier_total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_name
),
TotalSales AS (
    SELECT region_name, COALESCE(SUM(ss.supplier_total_sales), 0) AS total_supplier_sales
    FROM SalesByRegion rs
    LEFT JOIN SupplierSales ss ON rs.region_name = ss.supplier_total_sales
    GROUP BY region_name
)
SELECT rh.s_name, ts.region_name, ts.total_supplier_sales
FROM SupplierHierarchy rh
JOIN TotalSales ts ON rh.s_nationkey = (
    SELECT n.n_nationkey FROM nation n WHERE n.n_name = ts.region_name
)
WHERE ts.total_supplier_sales > (
    SELECT AVG(total_sales) FROM TotalSales
)
ORDER BY ts.total_supplier_sales DESC;
