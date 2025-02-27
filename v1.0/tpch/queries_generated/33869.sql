WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartCounts AS (
    SELECT ps.ps_partkey, COUNT(*) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemAgg AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY l.l_orderkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, la.total_revenue
    FROM orders o
    JOIN LineItemAgg la ON o.o_orderkey = la.l_orderkey
    WHERE o.o_orderstatus = 'O' AND la.total_revenue > 1000
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    MAX(pc.supplier_count) AS max_supplier_count,
    AVG(fo.total_revenue) AS avg_order_revenue
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN PartCounts pc ON pc.ps_partkey = ps.ps_partkey
LEFT JOIN FilteredOrders fo ON fo.o_custkey = c.c_custkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
ORDER BY avg_order_revenue DESC
LIMIT 10;
