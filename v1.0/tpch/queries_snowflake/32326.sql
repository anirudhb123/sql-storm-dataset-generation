
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 0 AS level 
    FROM supplier 
    WHERE s_acctbal IS NOT NULL 
      AND s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1 
    FROM supplier s 
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5 
)
SELECT 
    p.p_name, 
    p.p_brand, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_revenue, 
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
WHERE 
    p.p_size > 10 
    AND (s.s_acctbal IS NOT NULL AND s.s_acctbal < 1000 OR s.s_comment LIKE '%urgent%')
GROUP BY 
    p.p_name, 
    p.p_brand, 
    p.p_partkey
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10 
ORDER BY 
    returned_revenue DESC
LIMIT 5;
