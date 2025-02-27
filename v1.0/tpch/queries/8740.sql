WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, s.s_acctbal, s.s_comment
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 50000
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp) 
)
SELECT 
    ns.n_name, 
    COUNT(DISTINCT ns.s_suppkey) AS supplier_count, 
    SUM(hvp.ps_availqty) AS total_available_quantity, 
    AVG(hvp.ps_supplycost) AS average_supply_cost
FROM NationSupplier ns
JOIN HighValueParts hvp ON ns.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hvp.p_partkey)
GROUP BY ns.n_name
ORDER BY total_available_quantity DESC
LIMIT 10;
