
WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank_within_segment
    FROM customer c
)
SELECT nh.n_name AS nation_name, 
       COALESCE(SUM(so.total_order_value), 0) AS total_order_value,
       COUNT(DISTINCT so.o_orderkey) AS total_orders,
       AVG(ss.total_supply_cost) AS average_supply_cost,
       LISTAGG(DISTINCT cs.c_name, ', ') AS top_customers
FROM NationHierarchy nh
LEFT JOIN (
    SELECT o.o_orderkey, o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
) so ON so.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nh.n_nationkey)
LEFT JOIN SupplierStats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)) 
LEFT JOIN CustomerRanked cs ON cs.c_custkey = so.o_custkey
GROUP BY nh.n_name
HAVING COUNT(DISTINCT so.o_orderkey) > 10
ORDER BY total_order_value DESC;
