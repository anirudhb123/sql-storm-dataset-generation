SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
GROUP BY 
    n.n_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    nation_name;
