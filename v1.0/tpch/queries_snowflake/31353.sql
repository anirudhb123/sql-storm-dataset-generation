
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS STRING) AS full_name, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CONCAT(sh.full_name, ' -> ', s.s_name) AS full_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT l.l_orderkey) FILTER (WHERE l.l_returnflag = 'R') AS return_count,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_within_type,
    (SELECT AVG(s.s_acctbal) FROM supplier s WHERE s.s_nationkey = p.p_partkey) AS avg_supplier_acctbal,
    COALESCE((SELECT AVG(ps.ps_supplycost) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey), 0) AS avg_supply_cost,
    CASE 
        WHEN AVG(l.l_discount) IS NULL THEN 'No Discounts'
        ELSE 'Discounts Available'
    END AS discount_status
FROM 
    part p 
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = l.l_suppkey)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, sh.s_nationkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;
