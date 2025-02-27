WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    WHERE oh.level < 5
), 

PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

RichSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 10
), 

LineItemStatistics AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS line_count,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT oh.o_orderkey, 
       oh.o_orderdate, 
       oh.o_totalprice,
       li.total_revenue, 
       ps.total_availqty,
       rs.part_count,
       CASE 
           WHEN oh.level = 5 THEN 'Max Level' 
           ELSE 'Within Level' 
       END AS order_hierarchy_status,
       COALESCE(p.p_name, 'Unknown Part') AS part_name
FROM OrderHierarchy oh
LEFT JOIN LineItemStatistics li ON oh.o_orderkey = li.l_orderkey
LEFT JOIN PartSupplier ps ON ps.ps_partkey = (SELECT ps_partkey FROM partsupp ORDER BY RANDOM() LIMIT 1)
LEFT JOIN RichSuppliers rs ON rs.s_suppkey = (SELECT s_suppkey FROM supplier ORDER BY RANDOM() LIMIT 1)
LEFT JOIN part p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = ps.avg_supplycost)
WHERE oh.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY oh.o_orderdate DESC, rs.part_count DESC;
