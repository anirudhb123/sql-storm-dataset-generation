SELECT 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    SUM(l.l_quantity) AS total_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    STRING_AGG(DISTINCT CONCAT(c.c_address, ' ', c.c_phone), '; ') AS customer_details,
    CONCAT(r.r_name, ' (', r.r_regionkey, ')') AS region_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%brass%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, r.r_regionkey
ORDER BY 
    total_quantity DESC, avg_extended_price DESC
LIMIT 100;