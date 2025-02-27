SELECT 
    p.p_name, 
    p.p_brand, 
    CONCAT('Brand: ', p.p_brand, ' | Name: ', p.p_name) AS detailed_description,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names,
    SUM(l.l_quantity) AS total_quantity_sold,
    AVG(CASE 
        WHEN LENGTH(s.s_comment) > 50 THEN LENGTH(s.s_comment) 
        ELSE NULL 
    END) AS avg_long_supplier_comment_length
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
    p.p_retailprice > 100
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate <= DATE '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_quantity_sold DESC;