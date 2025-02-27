WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
), CountryStats AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
), HighlightedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT r.r_name AS region, 
       cs.n_name AS nation, 
       cs.customer_count, 
       cs.fulfilled_orders, 
       hp.p_name AS highlighted_part, 
       hp.avg_supply_cost,
       COUNT(DISTINCT lo.l_orderkey) AS order_count,
       SUM(lo.l_extendedprice) AS total_extended_price
FROM region r
JOIN nation cs ON r.r_regionkey = cs.n_regionkey
LEFT JOIN CountryStats cs ON cs.n_name = cs.n_name
LEFT JOIN lineitem lo ON lo.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE price_rank <= 10)
LEFT JOIN HighlightedParts hp ON hp.p_partkey IN (SELECT l_partkey FROM lineitem)
WHERE hp.avg_supply_cost IS NOT NULL
GROUP BY r.r_name, cs.n_name, cs.customer_count, cs.fulfilled_orders, hp.p_name, hp.avg_supply_cost
ORDER BY region, nation, order_count DESC;
