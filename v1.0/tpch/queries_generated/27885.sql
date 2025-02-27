SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    CONCAT(s.s_address, ', ', n.n_name) AS supplier_location, 
    LISTAGG(DISTINCT r.r_name, ', ') WITHIN GROUP (ORDER BY r.r_name) AS regions_served, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price_per_line,
    SUM(l.l_discount) AS total_discount,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_price_per_line ASC
LIMIT 10;
