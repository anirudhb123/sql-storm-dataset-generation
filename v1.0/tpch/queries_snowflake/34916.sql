WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 2
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_custkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
    AND c.c_acctbal IS NOT NULL
),
SupplierPartInfo AS (
    SELECT p.p_partkey, p.p_name, COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    nh.n_name AS nation_name,
    sh.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(tp.total_spent) AS revenue,
    SUM(sp.total_supply_cost) AS total_supply_cost
FROM nation nh
LEFT JOIN supplier sh ON nh.n_nationkey = sh.s_nationkey
LEFT JOIN HighValueOrders o ON sh.s_suppkey = o.o_orderkey
LEFT JOIN TotalLineItems tp ON o.o_orderkey = tp.l_orderkey
LEFT JOIN SupplierPartInfo sp ON sh.s_suppkey = sp.p_partkey
GROUP BY nh.n_name, sh.s_name
HAVING SUM(tp.total_spent) > (SELECT AVG(total_spent) FROM TotalLineItems)
ORDER BY total_orders DESC, revenue DESC;
