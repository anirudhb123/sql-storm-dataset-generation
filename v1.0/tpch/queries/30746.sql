
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'ORDERED'
        ELSE 'NOT ORDERED' 
    END AS order_status,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS revenue_rank,
    CONCAT(s.s_name, ' (', s.s_suppkey, ')') AS supplier_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 100)
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, s.s_name, s.s_suppkey
HAVING 
    SUM(l.l_quantity) IS NOT NULL
ORDER BY 
    revenue_rank, total_revenue DESC
LIMIT 50;
