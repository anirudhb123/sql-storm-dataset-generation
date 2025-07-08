
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
OrderStats AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
PartSupplierStats AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    CONCAT(p.p_name, ' - ', p.p_mfgr) AS part_details,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
    (SELECT COUNT(DISTINCT o.o_orderkey) 
     FROM lineitem l
     JOIN orders o ON l.l_orderkey = o.o_orderkey
     WHERE l.l_partkey = p.p_partkey AND o.o_orderdate > DATEADD(YEAR, -1, '1998-10-01')) AS recent_orders,
    (SELECT MAX(pss.total_supply_cost)
     FROM PartSupplierStats pss 
     WHERE pss.ps_partkey = p.p_partkey AND pss.rn = 1) AS max_supply_cost,
    CASE 
        WHEN MAX(l.l_extendedprice) IS NULL THEN 'No sales'
        ELSE 'Sales recorded'
    END AS sales_record_status,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice) DESC) AS regional_sales_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, r.r_name
HAVING SUM(l.l_quantity) > (SELECT AVG(total_orders) FROM OrderStats) OR SUM(l.l_quantity) < (SELECT MIN(total_orders) FROM OrderStats)
ORDER BY regional_sales_rank DESC NULLS LAST;
