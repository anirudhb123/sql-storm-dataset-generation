WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CONCAT(sh.hierarchy_path, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.supplier_count,
    ps.total_available,
    ps.avg_supply_cost,
    th.s_name AS top_supplier_name,
    th.s_acctbal AS top_supplier_balance,
    CASE 
        WHEN ps.avg_supply_cost IS NULL THEN 'No Suppliers'
        WHEN ps.avg_supply_cost > 500 THEN 'Expensive'
        ELSE 'Affordable' 
    END AS cost_category,
    sh.hierarchy_path
FROM PartSupplierStats ps
JOIN part p ON ps.p_partkey = p.p_partkey
LEFT JOIN TopSuppliers th ON th.rnk = 1
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = p.p_partkey % 10 -- Just a made-up relation for demonstration
WHERE p.p_size BETWEEN 10 AND 20
  AND (p.p_retailprice IS NOT NULL OR p.p_comment IS NOT NULL)
ORDER BY ps.avg_supply_cost DESC, th.s_acctbal DESC;
