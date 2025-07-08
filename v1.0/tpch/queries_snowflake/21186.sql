WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           s.s_nationkey,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           s.s_nationkey,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal <= sh.s_acctbal * 1.5
),
PartUsage AS (
    SELECT ps.ps_partkey,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
           AVG(l.l_extendedprice) AS avg_price,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 50000
),
CombinedData AS (
    SELECT p.p_partkey,
           p.p_name,
           COALESCE( pu.total_returned, 0 ) AS total_returned,
           COALESCE( pu.avg_price, 0 ) AS avg_price,
           COALESCE( pu.order_count, 0 ) AS order_count,
           sh.level,
           ts.total_supplycost
    FROM part p
    LEFT JOIN PartUsage pu ON p.p_partkey = pu.ps_partkey
    LEFT JOIN SupplierHierarchy sh ON p.p_partkey = sh.s_suppkey
    LEFT JOIN TopSuppliers ts ON p.p_partkey = ts.s_suppkey
    WHERE p.p_size BETWEEN 1 AND 50
)
SELECT c.c_custkey,
       c.c_name,
       COALESCE(cd.total_returned, 0) AS customer_returned_total,
       cd.avg_price,
       cd.order_count,
       CASE 
           WHEN cd.level IS NULL THEN 'Not Applicable'
           ELSE 'Level ' || cd.level
       END AS supplier_level,
       cd.total_supplycost
FROM customer c
LEFT JOIN CombinedData cd ON c.c_nationkey = cd.level
WHERE c.c_acctbal > 100 AND (cd.total_supplycost IS NOT NULL OR cd.total_supplycost IS NULL)
ORDER BY cd.avg_price DESC, c.c_name ASC
LIMIT 100;
