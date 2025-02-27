WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 2
),
TotalOrderValue AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, s.s_name, ps.ps_availqty, ps.ps_supplycost,
           DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS supply_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 100
)
SELECT ch.c_name, ch.c_acctbal, tov.total_value, sp.p_name, sp.s_name, sp.ps_availqty
FROM CustomerHierarchy ch
LEFT JOIN TotalOrderValue tov ON ch.c_custkey = tov.o_custkey
FULL OUTER JOIN SupplierPartDetails sp ON sp.supply_rank = 1
WHERE ch.c_acctbal IS NOT NULL AND (tov.total_value IS NULL OR tov.total_value > 1000)
ORDER BY ch.c_name, sp.p_name;
