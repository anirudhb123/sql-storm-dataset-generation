WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'O')
), SupplierPart AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), CustomerStats AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerStats c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT r.r_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       AVG(COALESCE(sp.avg_supply_cost, 0)) AS avg_supply_cost,
       SUM(COALESCE(lo.l_extendedprice, 0)) AS total_order_value,
       COUNT(DISTINCT hv.c_custkey) AS high_value_customer_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN SupplierPart sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN lineitem lo ON s.s_suppkey = lo.l_suppkey
LEFT JOIN RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
LEFT JOIN HighValueCustomers hv ON hv.c_custkey = (SELECT c_custkey FROM customer WHERE c_nationkey = n.n_nationkey LIMIT 1)
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 2 AND AVG(sp.avg_supply_cost) IS NOT NULL
ORDER BY r.r_name;
