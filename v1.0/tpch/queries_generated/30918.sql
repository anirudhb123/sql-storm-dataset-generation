WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > 30000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'P')
),
AggregateParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RegionNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name LIKE 'Asia%'
),
TopSuppliers AS (
    SELECT s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    c.c_name,
    coalesce(sh.level, -1) AS supplier_level,
    r.n_name AS nation_name,
    tp.total_sales,
    ap.total_avail_qty,
    ap.avg_supply_cost
FROM CustomerOrders co
JOIN RegionNation r ON r.n_nationkey = co.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = co.o_custkey
LEFT JOIN TopSuppliers tp ON tp.s_name = co.c_name
LEFT JOIN AggregateParts ap ON ap.ps_partkey = co.o_orderkey
WHERE tp.total_sales IS NOT NULL
AND ap.total_avail_qty > 0
ORDER BY c.c_name, tp.total_sales DESC;
