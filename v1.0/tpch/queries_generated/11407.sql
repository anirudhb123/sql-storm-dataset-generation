SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    o.o_orderdate >= '2022-01-01' AND o.o_orderdate <= '2022-12-31'
GROUP BY 
    p.p_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;
