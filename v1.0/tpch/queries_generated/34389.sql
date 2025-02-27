WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
AggregatedOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM lineitem l
    WHERE l.l_returnflag = 'R' AND l.l_shipmode = 'MAIL'
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(COALESCE(ss.total_supply_cost, 0)) AS total_supply_cost,
    AVG(a.total_spent) AS avg_customer_spending
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierStats ss ON l.l_partkey = ss.ps_partkey
JOIN AggregatedOrders a ON c.c_custkey = a.o_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_acctbal > 1000
WHERE r.r_comment LIKE '%international%'
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC, avg_customer_spending ASC;
