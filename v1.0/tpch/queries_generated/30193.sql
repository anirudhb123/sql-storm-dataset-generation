WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING AVG(ps.ps_supplycost) < 100
),
RegionAggregates AS (
    SELECT n.n_regionkey, r.r_name, SUM(fs.total_spent) AS total_spent_by_region
    FROM CustomerOrders fs
    JOIN customer c ON fs.c_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT r.r_name, 
       ra.total_spent_by_region, 
       COALESCE(SH.s_name, 'No Suppliers') AS supplier_name, 
       pp.p_name,
       pp.avg_supplycost,
       CASE 
           WHEN ra.total_spent_by_region > 100000 THEN 'High Spend'
           WHEN ra.total_spent_by_region BETWEEN 50000 AND 100000 THEN 'Medium Spend'
           ELSE 'Low Spend' 
       END AS spend_category
FROM RegionAggregates ra
LEFT JOIN SupplierHierarchy SH ON ra.total_spent_by_region < 50000
CROSS JOIN FilteredParts pp
ORDER BY ra.total_spent_by_region DESC, pp.avg_supplycost ASC;
