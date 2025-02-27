WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 0 AS level, c_comment
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1, c.c_comment
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5 AND c.custkey <> ch.c_custkey
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
), SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           STRING_AGG(DISTINCT (CASE WHEN ps.ps_availqty IS NOT NULL THEN CAST(ps.ps_availqty AS VARCHAR) END), ', ') AS avail_qtys
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT ch.c_custkey, ch.c_name, ch.level, ch.c_acctbal, ho.total_value, ss.avg_supply_cost, ss.part_count, ss.avail_qtys
FROM CustomerHierarchy ch
LEFT JOIN HighValueOrders ho ON ch.c_custkey = ho.o_custkey
JOIN SupplierStats ss ON ss.avg_supply_cost > (
    SELECT MAX(avg_supply_cost) FROM SupplierStats
) * 0.5
WHERE ch.c_comment IS NOT NULL
ORDER BY ch.c_acctbal DESC, ho.total_value NULLS LAST
FETCH FIRST 10 ROWS ONLY;
