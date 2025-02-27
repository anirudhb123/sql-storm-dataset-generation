WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TotalSales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2022-01-01'
    GROUP BY p.p_partkey
),
RegionSales AS (
    SELECT r.r_name, SUM(ts.total_sales) AS region_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN TotalSales ts ON ps.ps_partkey = ts.p_partkey
    GROUP BY r.r_name
)
SELECT r.r_name, COALESCE(cs.order_count, 0) AS customer_order_count, 
       COALESCE(rs.region_sales, 0) AS total_region_sales,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM region r
LEFT JOIN CustomerOrders cs ON cs.c_custkey IN (
    SELECT DISTINCT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
)
LEFT JOIN RegionSales rs ON r.r_name = rs.r_name
LEFT JOIN SupplierHierarchy sh ON r.r_regionkey = sh.s_nationkey
WHERE rs.region_sales > 1000000 OR (cs.order_count IS NULL AND sh.level <= 2) 
ORDER BY total_region_sales DESC, customer_order_count DESC;
