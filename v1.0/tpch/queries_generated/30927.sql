WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TotalLineItems AS (
    SELECT l.l_partkey,
           COUNT(*) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_partkey
),
FinalReport AS (
    SELECT p.p_name,
           ps.total_supplycost,
           tl.line_count,
           tl.total_price,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY total_price DESC) AS price_rank
    FROM part p
    LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN TotalLineItems tl ON p.p_partkey = tl.l_partkey
)
SELECT f.p_name, 
       f.total_supplycost, 
       f.line_count, 
       f.total_price,
       CASE WHEN f.total_price IS NULL THEN 'No Sales' 
            WHEN f.total_supplycost IS NOT NULL THEN 'Above Average' 
            ELSE 'Below Average' END AS price_analysis,
       r.r_name AS supplier_region
FROM FinalReport f
LEFT JOIN nation n ON f.total_supplycost IS NOT NULL AND n.n_nationkey = (
    SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (
        SELECT MIN(sup.s_suppkey) FROM SupplierHierarchy sup
    )
)
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE f.price_rank <= 10
ORDER BY f.total_price DESC NULLS LAST;
