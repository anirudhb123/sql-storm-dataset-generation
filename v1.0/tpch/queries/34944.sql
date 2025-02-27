WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 20000
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 100000
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
)
SELECT rh.level, ps.p_name, COUNT(DISTINCT ho.o_orderkey) AS order_count,
       AVG(ho.o_totalprice) AS avg_order_price,
       SUM(ps.total_supply_cost) AS total_cost_of_parts
FROM SupplierHierarchy rh
LEFT JOIN PartSummary ps ON rh.s_nationkey = ps.p_partkey
LEFT JOIN HighValueOrders ho ON ho.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_discount > 0.05 AND l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '1 year'
)
LEFT JOIN RankedSuppliers r ON rh.s_suppkey = r.s_suppkey
WHERE r.rank <= 5 OR r.s_suppkey IS NULL
GROUP BY rh.level, ps.p_name
ORDER BY rh.level, total_cost_of_parts DESC;