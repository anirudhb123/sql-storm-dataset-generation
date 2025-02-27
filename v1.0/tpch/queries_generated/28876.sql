SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    CHAR_LENGTH(p.p_comment) AS comment_length
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    p.p_name, s.s_name, region_nation
HAVING 
    total_available_quantity > 100
ORDER BY 
    average_extended_price DESC, total_available_quantity ASC;
