WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, CAST(s_name AS varchar(255)) AS hierarchy_path, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'Germany')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CONCAT(sh.hierarchy_path, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_nationkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MIN(l.l_shipdate) AS in_stock_date,
    MAX(l.l_shipdate) AS last_sold_date,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY total_revenue DESC) AS revenue_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
WHERE (l.l_returnflag = 'N' AND l.l_linestatus = 'O') 
    OR (l.l_returnflag IS NULL AND l.l_linestatus IS NULL)
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT ps.ps_suppkey) > 0 
    AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    AND MIN(l.l_shipdate) > CURRENT_DATE - INTERVAL '90 days'
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;

SELECT r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS regional_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(total_revenue) FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
        FROM lineitem
        GROUP BY l_orderkey
    ) AS avg_revenue
)
ORDER BY regional_revenue DESC;
