
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
NonEmptyParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    FROM part p
    WHERE p.p_size IS NOT NULL AND p.p_retailprice > 0
),
TotalOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierPerformance AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN NonEmptyParts p ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON l.l_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey
),
FinalReport AS (
    SELECT n.n_name AS nation_name, 
           COUNT(DISTINCT o.o_orderkey) AS order_count, 
           AVG(o.total_value) AS avg_order_value,
           COUNT(DISTINCT sh.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN TotalOrderValue o ON n.n_nationkey = (SELECT DISTINCT s_nationkey FROM supplier WHERE s_suppkey = o.o_orderkey)
    LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
    GROUP BY n.n_name
)
SELECT fr.nation_name, fr.order_count, fr.avg_order_value, 
       COALESCE(sp.total_supply_cost, 0) AS total_supply_cost
FROM FinalReport fr
LEFT JOIN SupplierPerformance sp ON fr.supplier_count = sp.s_suppkey
WHERE fr.order_count IS NOT NULL 
  AND (fr.avg_order_value > 500 OR sp.total_supply_cost IS NOT NULL)
ORDER BY fr.order_count DESC, fr.avg_order_value ASC;
