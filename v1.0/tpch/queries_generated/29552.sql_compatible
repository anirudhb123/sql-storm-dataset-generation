
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    STRING_AGG(s.s_name, ',') AS supplier_names
FROM 
    part p 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1998-01-01' 
GROUP BY 
    p.p_name 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 
ORDER BY 
    total_sales DESC;
