SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    SUBSTRING(p.p_comment FROM 1 FOR 20) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10 AND 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' AND
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
ORDER BY 
    total_quantity DESC
LIMIT 10;
