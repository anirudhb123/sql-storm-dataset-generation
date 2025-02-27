WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as rn,
           ps.ps_supplycost,
           p.p_size,
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'No Balance'
               WHEN s.s_acctbal < 1000 THEN 'Low Balance'
               ELSE 'Sufficient Balance'
           END AS balance_status 
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50 AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container = 'SM CASE')
),
NationSuppliers AS (
    SELECT n.n_nationkey, n.n_name, 
           COUNT(s.s_suppkey) AS total_suppliers,
           SUM(ps.ps_supplycost) AS total_supplycost,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, 
       NS.total_suppliers, 
       NS.total_supplycost, 
       RANK() OVER (ORDER BY NS.total_supplycost DESC) AS cost_rank,
       CASE 
           WHEN NS.total_suppliers IS NULL THEN 'No Suppliers'
           ELSE 'Available Suppliers'
       END AS supplier_status,
       CONCAT_WS(' - ', RATIO_TO_REPORT(total_supplycost) OVER () * 100, 'percent of total cost') AS percentage_cost
FROM region r
JOIN NationSuppliers NS ON r.r_regionkey = NS.n_nationkey
FULL OUTER JOIN RankedSuppliers RS ON NS.total_suppliers = RS.rn
WHERE (NS.avg_acctbal IS NOT NULL OR RS.balance_status = 'Low Balance')
  AND (RS.ps_supplycost IS NULL OR RS.ps_supplycost < 500)
ORDER BY r.r_name, cost_rank;
