WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 

PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

CustomerOrderSummary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent, 
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

HighVolumeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)

SELECT 
    nh.n_name AS nation_name,
    COALESCE(SUM(ps.total_availqty), 0) AS total_quantity_available,
    COALESCE(SUM(hvo.total_value), 0) AS total_high_volume_order_value,
    COUNT(DISTINCT cs.c_custkey) AS distinct_customers,
    MAX(cs.total_spent) AS max_customer_spent
FROM nation nh
LEFT JOIN supplier s ON nh.n_nationkey = s.s_nationkey
LEFT JOIN PartStats ps ON s.s_suppkey = ps.p_partkey
LEFT JOIN HighVolumeOrders hvo ON hvo.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nh.n_nationkey)
)
LEFT JOIN CustomerOrderSummary cs ON cs.c_custkey = s.s_nationkey
GROUP BY nh.n_name
ORDER BY total_quantity_available DESC;
