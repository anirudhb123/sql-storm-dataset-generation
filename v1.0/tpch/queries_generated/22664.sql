WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 0 AS level
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey <> ch.c_custkey AND c.c_acctbal > ch.c_acctbal
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, 
           ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM supplier s
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING total_revenue IS NULL OR total_revenue > 10000
),
FinalReport AS (
    SELECT ch.c_name, ch.level, p.p_name, ps.ps_supplycost
    FROM CustomerHierarchy ch
    JOIN PartSupplier ps ON ch.c_nationkey = ps.p_partkey
    JOIN part p ON ps.p_partkey = p.p_partkey
    WHERE ps.rn = 1
    ORDER BY ch.level, p.p_name
)
SELECT f.c_name, f.level, f.p_name, f.ps_supplycost, 
       CASE 
           WHEN f.ps_supplycost IS NULL THEN 'No Supply Cost'
           ELSE f.ps_supplycost::VARCHAR
       END AS supply_cost_displayed,
       CASE 
           WHEN EXISTS (SELECT 1 FROM HighValueSuppliers s WHERE s.s_acctbal > 50000) 
           THEN 'High Value Supplier Exists' 
           ELSE 'No High Value Supplier' 
       END AS supplier_status
FROM FinalReport f
LEFT JOIN HighValueSuppliers s ON f.p_name LIKE '%' || s.s_name || '%'
WHERE (f.level = (SELECT MAX(level) FROM FinalReport) OR f.ps_supplycost < 20)
ORDER BY f.c_name, f.p_name DESC
LIMIT 100;
