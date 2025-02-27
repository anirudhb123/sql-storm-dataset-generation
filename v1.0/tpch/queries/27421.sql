SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    MAX(l.l_shipdate) AS latest_ship_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC,
    average_price ASC;
