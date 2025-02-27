WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS avg_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    o.o_orderstatus = 'F' 
    AND (l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' OR l.l_tax IS NULL)
    AND (p.p_retailprice * l.l_quantity) > 1000
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    total_quantity DESC
LIMIT 10;