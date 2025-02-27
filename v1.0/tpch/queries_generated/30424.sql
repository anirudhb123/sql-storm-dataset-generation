WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
), SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerStats AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, SUM(os.total_order_value) AS total_spent
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT coalesce(nh.n_name, 'Unknown') AS nation_name,
       cs.c_mktsegment, 
       SUM(cs.total_spent) AS total_revenue,
       AVG(ss.total_supply_cost) AS avg_supply_cost
FROM CustomerStats cs
LEFT JOIN NationHierarchy nh ON cs.c_custkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name LIKE '%' || cs.c_name || '%')
LEFT JOIN SupplierStats ss ON ss.part_count > 5
GROUP BY nh.n_name, cs.c_mktsegment 
HAVING SUM(cs.total_spent) > 10000
ORDER BY total_revenue DESC
LIMIT 10;
