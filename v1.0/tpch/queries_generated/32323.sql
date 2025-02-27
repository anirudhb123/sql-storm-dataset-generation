WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(s.s_name AS varchar(100)) AS full_name,
           1 AS level
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(sh.full_name, ' -> ', s.s_name),
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
SalesData AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' 
      AND o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, 
           ps.ps_availqty, ps.ps_supplycost, s.s_suppkey, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_cost DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE p.p_size > 10
),
BestSuppliers AS (
    SELECT p.p_partkey, p.p_name, s.s_name AS supplier_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0 AND ps.ps_supplycost < 100
)
SELECT r.r_name, COALESCE(SUM(sd.total_sales), 0) AS total_sales, COUNT(DISTINCT bh.s_suppkey) AS supplier_count,
       CONCAT('Total Suppliers: ', COUNT(DISTINCT bh.s_suppkey)) AS supplier_summary,
       STRING_AGG(DISTINCT CONCAT(bh.s_name, ' (', bh.level, ')'), ', ') AS supplier_hierarchy
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy bh ON n.n_nationkey = bh.s_nationkey
LEFT JOIN SalesData sd ON sd.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = bh.s_nationkey)
LEFT JOIN BestSuppliers bsup ON bsup.p_partkey IN (SELECT ps.p_partkey FROM partsupp ps WHERE ps.ps_suppkey = bh.s_suppkey)
GROUP BY r.r_name
ORDER BY total_sales DESC, r.r_name;
