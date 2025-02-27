WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE oh.level < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PriceStatistics AS (
    SELECT p.p_partkey, 
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
           SUM(l.l_extendedprice) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS rn
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
FinalResults AS (
    SELECT n.n_name AS nation_name,
           COUNT(DISTINCT d.o_orderkey) AS total_orders,
           SUM(d.o_totalprice) AS total_sales,
           STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
           MAX(ps.avg_price) AS max_avg_price,
           MIN(ps.total_revenue) AS min_total_revenue,
           SUM(CASE WHEN s.total_parts IS NULL THEN 0 ELSE s.total_parts END) AS suppliers_with_parts
    FROM OrderHierarchy d
    JOIN customer c ON d.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN SupplierDetails s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p ORDER BY p.p_partkey LIMIT 1) LIMIT 1)
    JOIN PriceStatistics ps ON ps.p_partkey = (SELECT p.p_partkey FROM part p ORDER BY p.p_partkey LIMIT 1)
    GROUP BY n.n_name
)
SELECT fr.nation_name, 
       fr.total_orders, 
       fr.total_sales, 
       COALESCE(fr.suppliers, 'No suppliers') AS supplier_names,
       fr.max_avg_price, 
       fr.min_total_revenue, 
       fr.suppliers_with_parts
FROM FinalResults fr
WHERE fr.total_sales IS NOT NULL 
ORDER BY fr.total_sales DESC 
LIMIT 10;