WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 50000.00 AND sh.level < 3
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_totalprice IS NOT NULL
),
AggregatedData AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           AVG(l.l_discount) AS avg_discount
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT rh.s_name AS supplier_name, 
       COUNT(DISTINCT oo.o_orderkey) AS total_orders, 
       COALESCE(SUM(ag.total_supply_cost), 0) AS total_supply_costs,
       MAX(ag.avg_discount) AS max_discount
FROM SupplierHierarchy rh
LEFT JOIN RankedOrders oo ON oo.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
)
LEFT JOIN AggregatedData ag ON ag.total_supply_cost IS NOT NULL
WHERE rh.level = 1 AND ag.total_supply_cost > 0
GROUP BY rh.s_name
HAVING COUNT(DISTINCT oo.o_orderkey) > 10
ORDER BY total_orders DESC
LIMIT 10;