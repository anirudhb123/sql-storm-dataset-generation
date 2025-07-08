
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1998-10-01'
    AND o.o_orderstatus IN ('O', 'F')
    AND s.s_acctbal IS NOT NULL
    AND (s.s_comment LIKE '%priority%' OR s.s_comment IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_type
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 10
    AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    revenue_rank, total_revenue DESC
LIMIT 100;
