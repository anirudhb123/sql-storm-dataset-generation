WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 5000
),
HighValueSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, sh.level, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    GROUP BY sh.s_suppkey, sh.s_name, sh.level
)
SELECT r.r_name, COUNT(DISTINCT nc.n_nationkey) AS nation_count, 
       SUM(cs.total_orders) AS total_customer_orders,
       AVG(ps.total_avail) AS avg_part_available,
       SUM(hvs.part_count) AS total_unique_parts
FROM region r
JOIN nation nc ON r.r_regionkey = nc.n_regionkey
LEFT JOIN CustomerOrders cs ON nc.n_nationkey = cs.c_custkey
LEFT JOIN PartStatistics ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
LEFT JOIN HighValueSuppliers hvs ON hvs.s_suppkey IN (SELECT ps_suppkey FROM partsupp)
GROUP BY r.r_name
HAVING SUM(cs.total_orders) > 10 AND COUNT(DISTINCT hvs.s_suppkey) > 0
ORDER BY nation_count DESC, avg_part_available DESC;
