WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_comment, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS unique_customers, 
       COUNT(DISTINCT l.l_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(COALESCE(ps.total_supply_cost, 0)) AS average_supply_cost,
       COUNT(DISTINCT CASE WHEN l.l_shipmode = 'AIR' AND l.l_returnflag = 'R' THEN l.l_orderkey END) AS air_returned_orders,
       SUM(CASE WHEN l.l_tax IS NULL THEN 0 ELSE l.l_tax END) AS total_tax_collected
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN PartStats ps ON l.l_partkey = ps.p_partkey
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
