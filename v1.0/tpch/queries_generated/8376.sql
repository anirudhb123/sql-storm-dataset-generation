WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, p.p_name, p.p_brand, p.p_type
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, p.p_name, p.p_brand, p.p_type
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplyChain sc ON p.p_partkey = sc.ps_partkey
)
SELECT 
    sc.s_name,
    SUM(sc.ps_availqty) AS total_available_quantity,
    AVG(sc.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT sc.ps_partkey) AS unique_parts_supplied
FROM SupplyChain sc
GROUP BY sc.s_name
HAVING SUM(sc.ps_availqty) > 50
ORDER BY average_supply_cost DESC, total_available_quantity DESC
LIMIT 10;
