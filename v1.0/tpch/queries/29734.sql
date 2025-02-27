SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' from ', r.r_name), ', ') AS customer_names,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%' AND 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    number_of_orders DESC, total_quantity DESC;