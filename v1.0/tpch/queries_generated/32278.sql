WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), TotalOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_value
    FROM orders o
    GROUP BY o.o_custkey 
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
), SupplierPart AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
), NationalSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS sales_value
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT nh.n_name, nh.sales_value, sp.p_name, sp.total_quantity_sold,
       CONCAT('Supplier: ', sh.s_name, ' - Level: ', sh.level) AS supplier_info,
       CASE WHEN sp.total_avail_qty IS NOT NULL THEN 'Available' ELSE 'Not Available' END AS availability_status,
       nt.total_value * COUNT(DISTINCT y.y_custkey) AS adjusted_total_value
FROM NationalSales nh
LEFT JOIN SupplierPart sp ON nh.n_nationkey = sp.ps_suppkey
JOIN SupplierHierarchy sh ON sp.ps_suppkey = sh.s_suppkey
JOIN TotalOrders nt ON nt.o_custkey = sh.s_nationkey
LEFT JOIN (
    SELECT DISTINCT c.c_custkey, CASE
        WHEN c.c_acctbal IS NULL THEN 'No Balance'
        ELSE 'Has Balance'
    END AS balance_status
    FROM customer c
) y ON nt.o_custkey = y.c_custkey
WHERE nh.sales_value > 5000
ORDER BY nh.sales_value DESC, sp.total_quantity_sold ASC;
