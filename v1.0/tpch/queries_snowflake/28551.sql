
SELECT 
    s.s_name AS supplier_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    LISTAGG(DISTINCT p.p_name, ',') WITHIN GROUP (ORDER BY p.p_name) AS part_names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND 
    l.l_shipdate < '1998-01-01'
GROUP BY 
    s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_sales DESC
LIMIT 10;
