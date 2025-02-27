WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
NationDetails AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS average_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
FilteredParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) < 500
),
CombinedResults AS (
    SELECT od.o_orderkey, od.revenue, nd.n_name, fh.s_name,
           CASE WHEN fh.hierarchy_level IS NULL THEN 'Standard' ELSE 'Premium' END AS supplier_status
    FROM OrderDetails od
    JOIN NationDetails nd ON nd.supplier_count > 5
    LEFT JOIN SupplierHierarchy fh ON fh.s_nationkey = nd.n_nationkey
)
SELECT cr.o_orderkey, cr.revenue, cr.n_name, cr.supplier_status, pp.p_name, pp.p_retailprice
FROM CombinedResults cr
JOIN FilteredParts pp ON cr.revenue > (SELECT AVG(revenue) FROM CombinedResults)
ORDER BY cr.revenue DESC, cr.n_name ASC;
