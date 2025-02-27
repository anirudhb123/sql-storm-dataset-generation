WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000.00
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000.00
    AND ch.level < 5
),
SupplierRegions AS (
    SELECT n.n_nationkey, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_disctext IS NOT NULL
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT 
    ch.c_custkey,
    ch.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    sr.r_name AS supplier_region,
    ss.s_name AS supplier_name,
    ss.total_available,
    ss.avg_cost,
    ho.total_order_value AS high_value_order
FROM CustomerHierarchy ch
LEFT JOIN CustomerOrders cs ON ch.c_custkey = cs.c_custkey
LEFT JOIN SupplierRegions sr ON sr.n_nationkey = ch.c_nationkey
LEFT JOIN SupplierStats ss ON ss.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
    ORDER BY ps.ps_availqty DESC
    LIMIT 1
)
LEFT JOIN HighValueOrders ho ON ho.o_orderkey = (
    SELECT ho2.o_orderkey
    FROM HighValueOrders ho2
    WHERE ho2.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    ORDER BY ho2.total_order_value DESC
    LIMIT 1
)
WHERE 
    cs.total_spent > 5000 OR ss.total_available IS NOT NULL
ORDER BY ch.c_name, total_spent DESC;
