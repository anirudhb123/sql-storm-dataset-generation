WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CAST(s.s_name AS varchar(100)) AS hierarchy_path, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CONCAT(sh.hierarchy_path, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey -- assumes a bizarre self-referencing case for demonstration
    WHERE sh.level < 4
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS total_line_items,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
HighValueSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost) > 500.00
),
SupplierRegion AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           CASE WHEN COUNT(DISTINCT s.s_suppkey) IS NULL THEN 'No Suppliers' ELSE n.n_name END AS region_status
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT DISTINCT 
    p.p_name,
    COALESCE(sh.hierarchy_path, 'No Hierarchy Found') AS supplier_path,
    ao.total_revenue,
    hr.supplier_count,
    CASE 
        WHEN ao.total_revenue IS NULL THEN 'ZERO_REVENUE' 
        WHEN ao.total_revenue > 100000 THEN 'HIGH_REVENUE' 
        ELSE 'MODERATE_REVENUE' 
    END AS revenue_category
FROM part p
LEFT JOIN HighValueSuppliers hvs ON p.p_partkey = hvs.ps_partkey
INNER JOIN AggregatedOrders ao ON ao.o_orderkey IN (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderstatus = 'O' AND o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = hvs.ps_partkey
LEFT JOIN SupplierRegion hr ON 1 = 1 -- Cartesian to associate region info
WHERE p.p_retailprice IS NOT NULL AND p.p_size > 10
ORDER BY revenue_category DESC, ao.total_revenue DESC NULLS LAST;
