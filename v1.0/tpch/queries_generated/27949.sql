SELECT 
    CONCAT('Part Name: ', p.p_name, ' | Brand: ', p.p_brand, ' | Size: ', p.p_size, ' | Container: ', p.p_container, 
           ' | Retail Price: $', FORMAT(p.p_retailprice, 2), ' | Comment: ', p.p_comment) AS part_details,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderdate,
    o.o_totalprice
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
    p.p_size >= 10 AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' AND 
    c.c_mktsegment = 'BUILDING'
ORDER BY 
    o.o_totalprice DESC
LIMIT 100;
