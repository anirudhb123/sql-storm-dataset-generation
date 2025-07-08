
WITH RECURSIVE SupplierPartHierarchy AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, 0 AS level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, p.p_partkey, p.p_name, sp.level + 1
    FROM SupplierPartHierarchy sp
    JOIN partsupp ps ON sp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE sp.level < 3
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
OrderMetrics AS (
    SELECT c.c_nationkey, AVG(o.o_totalprice) AS avg_order_price, 
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_nationkey
)
SELECT r.r_name, rs.nation_count, rs.total_supplier_balance,
       om.avg_order_price, om.total_orders,
       COALESCE(sp.p_name, 'No Parts') AS part_name,
       CASE 
           WHEN om.avg_order_price IS NULL THEN 'Unknown'
           WHEN om.total_orders > 5 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS order_category
FROM RegionStats rs
JOIN region r ON r.r_name = rs.r_name
LEFT JOIN OrderMetrics om ON r.r_regionkey = om.c_nationkey
LEFT JOIN SupplierPartHierarchy sp ON sp.s_suppkey = (
    SELECT s.s_suppkey 
    FROM supplier s 
    WHERE s.s_acctbal = (
        SELECT MAX(s_acctbal) 
        FROM supplier 
        WHERE s_nationkey = r.r_regionkey
    ) 
    LIMIT 1
)
WHERE rs.nation_count > 1 OR (sp.p_name IS NOT NULL AND rs.total_supplier_balance IS NOT NULL)
ORDER BY r.r_name, om.avg_order_price DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
