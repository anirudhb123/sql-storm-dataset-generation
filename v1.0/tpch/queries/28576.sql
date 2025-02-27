SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
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
GROUP BY 
    p.p_name, r.r_name, n.n_name 
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_retail_price DESC
LIMIT 10;
