WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
    AND p.p_retailprice IS NOT NULL
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(s.s_suppkey) > 0
),
CustomerOrder AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
HighValueParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps 
    JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
    WHERE rp.rn = 1
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT DISTINCT 
    np.n_name AS nation_name,
    p.p_name AS part_name,
    cv.total_spent,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(lp.total_supply_cost, 0) AS total_supply_cost
FROM NationSupplier np
LEFT JOIN supplier s ON np.n_nationkey = s.s_nationkey
JOIN customer c ON c.c_nationkey = np.n_nationkey
JOIN CustomerOrder cv ON c.c_custkey = cv.c_custkey
LEFT JOIN lineitem li ON li.l_suppkey = s.s_suppkey
LEFT JOIN HighValueParts lp ON li.l_partkey = lp.ps_partkey
WHERE cv.total_spent > (SELECT AVG(total_spent) FROM CustomerOrder)
AND (s.s_name IS NULL OR s.s_comment NOT LIKE '%test%')
ORDER BY np.n_name, p.p_name;
