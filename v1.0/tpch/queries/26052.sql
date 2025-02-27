SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_tax) AS max_tax,
    MIN(l.l_discount) AS min_discount,
    STRING_AGG(DISTINCT CONCAT(l.l_shipmode, ' (', l.l_returnflag, ')'), '; ') AS shipping_modes,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS location_info
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1996-01-01'
    AND l.l_shipdate < '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;