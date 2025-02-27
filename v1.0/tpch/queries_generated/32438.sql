WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
    )
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, hs.total_sales,
           RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY hs.total_sales DESC) AS sales_rank
    FROM orders o
    JOIN TotalSales hs ON o.o_orderkey = hs.l_orderkey
),
SalesByRegion AS (
    SELECT n.n_name AS region_name, SUM(od.total_sales) AS total_region_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN TotalSales ts ON ts.l_orderkey = l.l_orderkey
    JOIN OrderDetails od ON od.o_orderkey = ts.l_orderkey
    GROUP BY n.n_name
),
SalesRanking AS (
    SELECT sb.region_name, sb.total_region_sales,
           RANK() OVER (ORDER BY sb.total_region_sales DESC) AS region_rank
    FROM SalesByRegion sb
)
SELECT 
    sh.s_name AS supplier_name,
    c.c_name AS high_value_customer,
    sr.region_name,
    sr.total_region_sales,
    sh.level
FROM SupplierHierarchy sh
JOIN HighValueCustomers c ON sh.s_nationkey = c.c_nationkey
JOIN SalesRanking sr ON sr.region_rank < 4
WHERE sr.total_region_sales IS NOT NULL
ORDER BY sr.total_region_sales DESC, sh.s_name, c.c_name;
