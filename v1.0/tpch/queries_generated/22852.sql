WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, AVG(s_acctbal) AS avg_acctbal, s_name, 
           CASE WHEN s_comment LIKE '%important%' THEN 'High Priority' ELSE 'Normal' END AS priority
    FROM supplier
    GROUP BY s_suppkey, s_name

    UNION ALL

    SELECT sh.s_suppkey, AVG(s.s_acctbal) AS avg_acctbal, s.s_name, 'Subordinate' AS priority
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    GROUP BY sh.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.avg_acctbal, sh.priority
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.avg_acctbal IS NOT NULL AND LENGTH(s.s_name) > 15
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P')
    GROUP BY o.o_orderkey
),
UnusualPrices AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS cumulative_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 1 AND cumulative_supplycost < 1000
)
SELECT r.r_name, f.s_name, COUNT(DISTINCT d.o_orderkey) AS total_orders, 
       SUM(d.total_order_value) AS total_value, 
       MAX(COALESCE(up.supplier_count, 0)) AS unique_supplier_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN FilteredSuppliers f ON c.c_nationkey = f.s_nationkey
LEFT JOIN OrderDetails d ON f.s_suppkey = d.o_orderkey
LEFT JOIN UnusualPrices up ON f.s_suppkey = up.ps_partkey
WHERE r.r_name IS NOT NULL AND f.priority LIKE 'High Priority%'
GROUP BY r.r_name, f.s_name
HAVING SUM(d.total_order_value) > 50000 OR COUNT(DISTINCT d.o_orderkey) > 10
ORDER BY total_value DESC, r.r_name ASC, f.s_name ASC;
