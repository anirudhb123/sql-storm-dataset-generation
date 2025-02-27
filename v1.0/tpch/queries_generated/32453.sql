WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
),
PartSupply AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
TotalOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT to.*, RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM TotalOrders to
)
SELECT ch.c_name, ch.level,
       COUNT(DISTINCT ro.o_orderkey) AS order_count,
       SUM(ro.total_revenue) AS total_revenue,
       MAX(ps.total_cost) AS max_supply_cost
FROM CustomerHierarchy ch
LEFT JOIN RankedOrders ro ON ch.c_custkey = ro.o_orderkey
LEFT JOIN PartSupply ps ON ro.o_orderkey = ps.p_partkey
GROUP BY ch.c_name, ch.level
HAVING SUM(ro.total_revenue) > 10000
ORDER BY max_supply_cost DESC, order_count DESC

