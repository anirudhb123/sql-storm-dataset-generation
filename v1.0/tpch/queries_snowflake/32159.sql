
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal > 10000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal < 10000 AND ch.level < 5
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
NationPerformance AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON o.o_custkey = c.c_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT
    r.r_name,
    COALESCE(hvo.total_order_value, 0) AS high_value_order_total,
    sp.total_avail_qty,
    sp.avg_supply_cost,
    np.order_count,
    COUNT(ch.c_custkey) AS customer_count
FROM region r
LEFT JOIN HighValueOrders hvo ON hvo.o_custkey = (SELECT c_custkey FROM customer WHERE c_nationkey = r.r_regionkey LIMIT 1)
LEFT JOIN SupplierPerformance sp ON sp.s_suppkey = (SELECT MIN(ps.ps_suppkey) FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 500))
LEFT JOIN NationPerformance np ON np.n_nationkey = r.r_regionkey
LEFT JOIN CustomerHierarchy ch ON ch.c_nationkey = r.r_regionkey
WHERE sp.avg_supply_cost IS NOT NULL OR np.order_count IS NOT NULL
GROUP BY r.r_name, hvo.total_order_value, sp.total_avail_qty, sp.avg_supply_cost, np.order_count
ORDER BY r.r_name;
