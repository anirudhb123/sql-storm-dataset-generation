SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), '; ') AS part_details,
    SUM(o.o_totalprice) AS total_order_value,
    RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS order_value_rank
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    o.o_orderdate >= DATE '1996-01-01'
GROUP BY 
    s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_order_value DESC
LIMIT 10;