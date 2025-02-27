WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_supplycost,
           p.p_name, p.p_brand, p.p_container, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_supplycost,
           p.p_name, p.p_brand, p.p_container,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplyChain sc ON s.s_suppkey <> sc.s_suppkey
    WHERE ps.ps_availqty > 0
),
FilteredSupply AS (
    SELECT s.*, 
           LEAD(s.s_acctbal) OVER (PARTITION BY s.p_brand ORDER BY s.p_supplycost) AS next_acctbal,
           COUNT(*) OVER (PARTITION BY s.p_brand) AS total_suppliers
    FROM SupplyChain s
    WHERE s.rn = 1
)
SELECT r.r_name, 
       SUM(f.ps_supplycost) AS total_supply_cost,
       AVG(f.s_acctbal) AS average_acct_balance,
       COUNT(DISTINCT f.s_suppkey) AS unique_suppliers,
       MAX(f.next_acctbal) AS highest_next_acctbal
FROM FilteredSupply f
JOIN supplier s ON f.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE f.total_suppliers > 10
AND r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(f.ps_supplycost) > 10000
ORDER BY total_supply_cost DESC
LIMIT 10;
