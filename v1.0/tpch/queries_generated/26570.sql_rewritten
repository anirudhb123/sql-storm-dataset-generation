SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT CONCAT(l.l_shipmode, ' ', l.l_shipinstruct), '; ') AS shipping_details
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
    p.p_brand LIKE '%BrandX%' 
    AND s.s_comment NOT LIKE '%discount%'
    AND o.o_orderdate >= '1995-01-01' 
    AND o.o_orderdate < '1996-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name
ORDER BY 
    total_quantity DESC, avg_price ASC
LIMIT 100;