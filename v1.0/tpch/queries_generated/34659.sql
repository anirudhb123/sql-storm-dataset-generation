WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
), LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS num_line_items
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey
)
SELECT n.n_name, 
       SUM(ps.ps_supplycost * l.total_revenue / NULLIF(l.num_line_items, 0)) AS avg_cost_per_line,
       MAX(sh.level) AS max_supplier_level,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN LineItemSummary l ON l.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM RankedOrders o 
    WHERE o.rnk = 1
)
LEFT JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
GROUP BY n.n_name
HAVING SUM(ps.ps_supplycost) > 50000
ORDER BY avg_cost_per_line DESC;
