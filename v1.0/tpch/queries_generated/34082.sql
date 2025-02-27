WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),

RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),

AggregatedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    r.r_name,
    n.n_name,
    COALESCE(SUM(ag.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    STRING_AGG(DISTINCT p.p_name, '; ') AS part_names
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN RankedOrders ro ON ro.o_custkey = s.s_suppkey
LEFT JOIN AggregatedLineItems ag ON ag.l_orderkey = ro.o_orderkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
WHERE s.s_acctbal IS NOT NULL AND r.r_comment NOT LIKE '%test%'
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY total_revenue DESC;
