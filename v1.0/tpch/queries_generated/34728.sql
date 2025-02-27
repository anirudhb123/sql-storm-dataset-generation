WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > sh.s_acctbal
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice) DESC) AS type_rank,
    COALESCE(n.n_name, 'Undefined') AS nation_name,
    p.p_container || ' - ' || COALESCE(s.s_name, 'No Supplier') AS description
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 1 AND 10
    AND (s.s_acctbal IS NOT NULL OR s.s_acctbal IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice, n.n_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
    OR EXISTS (SELECT 1 FROM orders o WHERE o.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey = p.p_partkey) AND o.o_orderstatus = 'F')
ORDER BY 
    discounted_sales DESC, type_rank
LIMIT 50;
