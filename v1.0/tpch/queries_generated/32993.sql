WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 50000 AND sh.level < 5
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 10
),
SalesData AS (
    SELECT o.o_orderkey, 
           COUNT(l.l_linenumber) AS line_item_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.ps_supplycost,
    ph.ps_availqty,
    COALESCE(sd.line_item_count, 0) AS total_line_items,
    COALESCE(sd.total_sales, 0.00) AS total_sales_value,
    nh.r_name AS region_name,
    sh.level AS supplier_level
FROM PartSupplier ph
LEFT JOIN SalesData sd ON ph.p_partkey = (
    SELECT l.l_partkey 
    FROM lineitem l 
    JOIN orders o ON l.l_orderkey = o.o_orderkey 
    WHERE o.o_orderkey IN (SELECT o.o_orderkey FROM orders)
    LIMIT 1
)
LEFT JOIN NationRegion nh ON ph.ps_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost = ph.ps_supplycost
    LIMIT 1
)
JOIN SupplierHierarchy sh ON sh.s_nationkey = nh.n_nationkey
WHERE ph.ps_supplycost > (
    SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2
)
ORDER BY total_sales_value DESC, ph.p_name ASC;
