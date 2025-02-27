SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(l.l_extendedprice) AS min_extended_price,
    ROUND(AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END), 2) AS avg_price_after_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE '%metal%'
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    avg_retail_price DESC, 
    supplier_count DESC
LIMIT 10;