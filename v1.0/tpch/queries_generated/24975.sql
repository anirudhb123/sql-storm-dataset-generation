WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal < ch.c_acctbal
),
SupplierCosts AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
ExpensiveParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, s.total_supply_cost
    FROM part p
    JOIN SupplierCosts s ON s.ps_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = p.p_partkey
        ORDER BY ps.ps_supplycost * ps.ps_availqty DESC
        LIMIT 1
    )
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT DISTINCT ch.c_name, ch.level, ep.p_name, ep.p_retailprice
FROM CustomerHierarchy ch
LEFT JOIN ExpensiveParts ep ON ch.c_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_discount IS NOT NULL AND l.l_discount > 0.1
    )
)
WHERE (ch.level IS NULL OR (ch.level BETWEEN 2 AND 5))
AND ep.p_retailprice IS NOT NULL
ORDER BY ch.c_name, ep.p_retailprice DESC
FETCH FIRST 100 ROWS ONLY;
