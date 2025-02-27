WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_retailprice, 0 AS level
    FROM part
    WHERE p_size = (SELECT MAX(p_size) FROM part)
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ph.level + 1
    FROM part_hierarchy ph
    JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ph.level < (SELECT COUNT(*) FROM part) AND ph.p_retailprice < p.p_retailprice
)
, customer_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) IS NOT NULL
), 
supply_summary AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    coalesce(c.c_name, 'Unknown Customer') AS customer_name,
    ph.p_name AS part_name,
    ph.p_retailprice AS price,
    c.total_spent,
    ss.total_supply_cost,
    CASE 
        WHEN ss.total_supply_cost IS NULL OR ss.total_supply_cost < 1000 THEN 'Low Supply Cost'
        ELSE 'High Supply Cost'
    END AS supply_cost_category
FROM part_hierarchy ph
LEFT JOIN customer_summary c ON ph.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty = (SELECT MAX(ps_availqty) FROM partsupp))
LEFT JOIN supply_summary ss ON ph.p_partkey = ss.s_suppkey
WHERE ph.level < 5
ORDER BY ph.level, customer_name DESC
LIMIT 100 OFFSET 10;
