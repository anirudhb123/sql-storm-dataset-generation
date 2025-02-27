WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderTotals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT ot.o_orderkey, ot.total_order_value,
           RANK() OVER (ORDER BY ot.total_order_value DESC) AS order_rank
    FROM OrderTotals ot
),
PartSupplierData AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
FilteredSuppliers AS (
    SELECT sh.s_name, sh.s_nationkey, ps.p_partkey, ps.ps_supplycost
    FROM SupplierHierarchy sh
    LEFT JOIN PartSupplierData ps ON sh.s_nationkey = ps.p_partkey
    WHERE ps.cost_rank = 1
),
FinalReport AS (
    SELECT ns.n_name AS nation_name, COUNT(DISTINCT fs.s_name) AS supplier_count,
           SUM(fs.ps_supplycost) AS total_cost
    FROM FilteredSuppliers fs
    JOIN nation ns ON fs.s_nationkey = ns.n_nationkey
    GROUP BY ns.n_name
)
SELECT fr.nation_name, fr.supplier_count, fr.total_cost,
       CASE WHEN fr.total_cost IS NULL THEN 'No Costs' ELSE 'Costs Present' END AS cost_status
FROM FinalReport fr
WHERE fr.supplier_count > 0
ORDER BY fr.total_cost DESC;
