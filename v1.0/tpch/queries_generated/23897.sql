WITH RECURSIVE Supplier_CTE AS (
    SELECT s_suppkey, s_name, s_acctbal, 
           (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_suppkey = s.s_suppkey) AS avg_supply_cost
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 1.1, 
           (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_suppkey = s.s_suppkey) AS avg_supply_cost
    FROM supplier s
    JOIN Supplier_CTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.avg_supply_cost IS NOT NULL
    AND sc.s_acctbal < 1000
),
Part_Supplier AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, s.s_name,
           CASE 
               WHEN ps.ps_supplycost IS NULL THEN 0
               ELSE ps.ps_supplycost
           END AS supply_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
Filtered_Parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(MAX(costs.supply_cost), 0) AS max_cost,
           SUM(CASE WHEN s.s_nationkey IS NULL THEN 1 ELSE 0 END) AS null_suppliers_count
    FROM Part_Supplier costs
    LEFT JOIN nation n ON costs.s_suppkey = n.n_nationkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT p.part, AVG(p.retailprice - fp.max_cost) AS avg_profit_margin, 
       SUM(fp.null_suppliers_count) AS total_null_suppliers,
       CASE 
           WHEN AVG(fp.max_cost) > 100 THEN 'High Margin'
           WHEN AVG(fp.max_cost) < 50 THEN 'Low Margin'
           ELSE 'Medium Margin'
       END AS margin_category
FROM part p
JOIN Filtered_Parts fp ON p.p_partkey = fp.p_partkey
WHERE p.p_retailprice IS NOT NULL
  AND (EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = p.p_partkey) 
       OR fp.max_cost < 100)
GROUP BY p.p_partkey, fp.max_cost
HAVING AVG(p.retailprice) IS NOT NULL
ORDER BY avg_profit_margin DESC, total_null_suppliers ASC
LIMIT 10;
