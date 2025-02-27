WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    AND sh.level < 5
),
QualifiedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COALESCE(p.p_retailprice * (1 - (SELECT MAX(l_discount) FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R')), 
                                        p.p_retailprice) AS effective_price,
           p.p_type
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IS NOT NULL AND
          (p.p_mfgr LIKE 'Manufacturer%' OR p.p_comment IS NULL)
),
FilteredOrders AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(l.l_linenumber) AS line_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FinalSelection AS (
    SELECT rp.p_partkey, 
           rp.effective_price,
           fo.total_order_value, 
           fo.line_count,
           CASE WHEN fo.line_count > 10 THEN 'High' ELSE 'Low' END AS order_volume_category,
           RANK() OVER (ORDER BY fo.total_order_value DESC) AS order_rank
    FROM QualifiedParts rp
    JOIN FilteredOrders fo ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < fo.total_order_value)
    WHERE rp.effective_price IS NOT NULL
)
SELECT n.n_name,
       COUNT(DISTINCT fs.p_partkey) AS parts_count,
       AVG(fs.effective_price) AS average_effective_price,
       SUM(fs.total_order_value) AS summed_order_value,
       MIN(fs.order_rank) AS highest_rank
FROM FinalSelection fs
JOIN supplier s ON fs.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE n.n_comment LIKE '%important%'
GROUP BY n.n_name
HAVING COUNT(DISTINCT fs.p_partkey) > 5
ORDER BY summed_order_value DESC
LIMIT 10;
