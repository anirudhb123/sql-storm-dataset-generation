WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, sh.level + 1
    FROM supplier s2
    INNER JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartAvailability AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY ps.ps_partkey
),
OrderStatistics AS (
    SELECT o.o_orderkey, 
           COUNT(DISTINCT l.l_partkey) AS distinct_parts,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    COALESCE(pa.total_avail_qty, 0) AS available_quantity, 
    COALESCE(os.total_revenue, 0) AS revenue,
    sh.s_name AS supplier_name,
    CASE 
        WHEN sh.level IS NULL THEN 'No Supplier'
        ELSE CONCAT('Supplier Level ', sh.level)
    END AS supplier_level,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(os.total_revenue, 0) DESC) AS revenue_rank
FROM part p
LEFT JOIN PartAvailability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN OrderStatistics os ON os.distinct_parts > (SELECT COUNT(*) FROM part) / 10
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost LIMIT 1)
WHERE (p.p_retailprice > CAST(50.00 AS DECIMAL) OR NULLIF(p.p_comment, '') IS NOT NULL)
  AND (sh.s_acctbal IS NOT NULL OR p.p_size BETWEEN 5 AND 100)
ORDER BY revenue_rank DESC, available_quantity DESC;
