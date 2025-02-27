SELECT 
    CONCAT(p.p_name, ' (', s.s_name, ')') AS part_supplier,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    MAX(l.l_tax) AS max_tax,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_comment LIKE '%critical%'
GROUP BY 
    part_supplier
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;