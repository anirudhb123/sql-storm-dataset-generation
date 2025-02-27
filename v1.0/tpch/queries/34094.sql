WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, sh.s_name, sh.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    INNER JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 3
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(MAX(s.s_acctbal), 0) AS max_supplier_balance,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier_hierarchy sh ON l.l_suppkey = sh.s_suppkey
LEFT JOIN 
    supplier s ON sh.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100
    AND (p.p_size BETWEEN 10 AND 20 OR p.p_name LIKE '%Widget%')
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 30000)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_price DESC
LIMIT 10;
