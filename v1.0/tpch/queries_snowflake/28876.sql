
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    LENGTH(p.p_comment) AS comment_length
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
    p.p_name ILIKE '%widget%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    AVG(l.l_extendedprice) DESC, SUM(ps.ps_availqty) ASC;
