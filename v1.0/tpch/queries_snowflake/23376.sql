
WITH EnhancedCost AS (
    SELECT ps_partkey,
           SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
           COUNT(*) AS supplier_count
    FROM partsupp
    GROUP BY ps_partkey
),
MaxCost AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_retailprice,
           ec.total_supply_cost,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY ec.total_supply_cost DESC) AS brand_rank
    FROM part p
    JOIN EnhancedCost ec ON p.p_partkey = ec.ps_partkey
),
FilteredSuppliers AS (
    SELECT s.s_nationkey, 
           SUM(s.s_acctbal) AS total_balance,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
    HAVING SUM(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)
),
FinalJoin AS (
    SELECT m.p_partkey,
           m.p_name,
           m.p_brand,
           m.total_supply_cost,
           COALESCE(fs.total_balance, 0) AS nation_balance,
           ROW_NUMBER() OVER (PARTITION BY m.p_brand ORDER BY m.total_supply_cost DESC) AS cost_rank,
           f.n_nationkey
    FROM MaxCost m
    LEFT JOIN FilteredSuppliers fs ON fs.s_nationkey = (SELECT s_nationkey FROM supplier WHERE supplier.s_suppkey = m.p_partkey LIMIT 1)
    LEFT JOIN nation f ON fs.s_nationkey = f.n_nationkey
    WHERE m.brand_rank = 1 OR m.total_supply_cost IS NULL
)
SELECT f.*, 
       CASE 
           WHEN f.nation_balance IS NULL THEN 'No Suppliers' 
           ELSE 'Suppliers Available' 
       END AS supplier_status
FROM FinalJoin f
WHERE f.total_supply_cost > 1000 
  AND f.cost_rank <= 5 
  AND (f.n_nationkey IS NOT NULL OR f.p_brand LIKE '%special%')
ORDER BY f.total_supply_cost DESC, f.p_brand ASC;
