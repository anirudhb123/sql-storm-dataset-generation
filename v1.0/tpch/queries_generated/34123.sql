WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal > 5000
),
HighValueOrders AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
LatestOrders AS (
    SELECT o.c_custkey,
           MAX(o.o_orderdate) AS latest_order_date
    FROM orders o
    GROUP BY o.c_custkey
)
SELECT p.p_name,
       r.r_name,
       n.n_name,
       AVG(ps.ps_supplycost) AS avg_supply_cost,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
       STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
       COUNT(DISTINCT so.o_orderkey) AS high_value_order_count,
       SUM(so.total_value) AS total_high_value
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN orders o ON o.o_custkey = s.s_suppkey
LEFT JOIN HighValueOrders so ON o.o_orderkey = so.o_orderkey
JOIN LatestOrders lo ON o.o_custkey = lo.c_custkey AND o.o_orderdate = lo.latest_order_date
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice)
    FROM part p2
    WHERE p2.p_size BETWEEN 10 AND 20
) OR s.s_acctbal IS NULL
GROUP BY p.p_name, r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY avg_supply_cost DESC;
