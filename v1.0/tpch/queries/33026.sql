
WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CAST(s.s_name AS VARCHAR(255)) AS path
    FROM 
        supplier s
    WHERE 
        s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CAST(CONCAT(sh.path, ' -> ', s.s_name) AS VARCHAR(255))
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', s.s_name), '; ') AS supplier_names
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100.00 AND 
    l.l_shipdate >= '1997-01-01' AND 
    o.o_orderstatus = 'F'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > (SELECT AVG(total_price) FROM (SELECT 
                    SUM(l_extendedprice * (1 - l_discount)) AS total_price 
                    FROM lineitem GROUP BY l_orderkey) AS avg_price)
ORDER BY 
    total_revenue DESC;
