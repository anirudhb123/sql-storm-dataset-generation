WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandA' 
           AND p.p_retailprice < (
               SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type LIKE '%Type%'
           )
    ))
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    AVG(l.l_quantity) AS average_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE 
    l.l_shipdate >= '2023-01-01' 
    AND l.l_shipdate < '2024-01-01'
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
    AND (c.c_acctbal > 1000 OR c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'U%'))
GROUP BY r.r_name
HAVING total_revenue > (
    SELECT AVG(total_revenue) FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
        FROM lineitem
        GROUP BY l_orderkey
    ) AS revenue_per_order
)
ORDER BY last_ship_date DESC, total_orders DESC
LIMIT 10;
