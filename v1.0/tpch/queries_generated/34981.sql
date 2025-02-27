WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
AvgPriceByNation AS (
    SELECT n.n_nationkey, n.n_name, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
)
SELECT 
    sh.s_name AS supplier_name,
    sh.level AS supply_chain_level,
    n.n_name AS nation_name,
    a.avg_price,
    COALESCE(t.total_cost, 0) AS total_supply_cost
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN AvgPriceByNation a ON n.n_nationkey = a.n_nationkey
LEFT JOIN TopSuppliers t ON sh.s_suppkey = t.s_suppkey
WHERE (sh.s_acctbal IS NOT NULL AND sh.s_acctbal > 1500)
   OR (sh.s_name LIKE 'Supplier%' AND t.total_cost IS NULL)
ORDER BY supplier_name, supply_chain_level DESC;
