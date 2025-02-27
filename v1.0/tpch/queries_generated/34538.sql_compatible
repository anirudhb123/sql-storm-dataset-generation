
WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(l.l_orderkey) AS line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
DetailedResults AS (
    SELECT c.c_custkey, c.c_name, SUM(hvo.total_value) AS total_order_value,
           SUM(s.total_available) AS total_available,
           MAX(s.avg_supply_cost) AS max_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(hvo.total_value) DESC) AS rank
    FROM customer c
    LEFT JOIN HighValueOrders hvo ON c.c_custkey = hvo.o_custkey
    LEFT JOIN SupplierStats s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_size > 10
    )
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(hvo.total_value) IS NOT NULL
)
SELECT d.c_name AS customer_name, d.total_order_value, d.total_available, d.max_supply_cost
FROM DetailedResults d
WHERE d.rank = 1
ORDER BY d.total_order_value DESC
LIMIT 10;
