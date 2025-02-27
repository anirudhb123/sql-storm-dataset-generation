WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name AS region_name,
    nh.n_name AS nation_name,
    cs.c_name AS customer_name,
    cs.order_count,
    cs.avg_order_value,
    ps.total_available,
    ps.total_cost,
    ro.o_orderkey,
    ro.o_totalprice
FROM region r
LEFT JOIN nation nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN CustomerOrders cs ON cs.c_custkey IN (
    SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nh.n_nationkey
)
LEFT JOIN PartSupplierStats ps ON ps.p_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = nh.n_nationkey
)
LEFT JOIN RankedOrders ro ON ro.c_custkey = cs.c_custkey AND ro.order_rank = 1
WHERE cs.order_count > 0
  AND ps.total_available IS NOT NULL
  AND ps.total_cost > 1000.00
ORDER BY r.r_name, nh.n_name, cs.c_name, ro.o_totalprice DESC;
