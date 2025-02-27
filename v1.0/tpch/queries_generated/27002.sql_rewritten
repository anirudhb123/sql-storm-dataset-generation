SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE 0 
    END) AS total_returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    CONCAT('Brand: ', p.p_brand, ' | Type: ', p.p_type) AS branding_info
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
WHERE 
    p.p_brand <> 'Brand#34' 
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_returned_quantity DESC, total_orders ASC;