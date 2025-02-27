SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_quantity_available,
    AVG(p.p_retailprice) AS average_part_price,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE 0 
    END) AS total_returned_quantity,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
WHERE 
    r.r_name LIKE 'Asia%' 
    AND s.s_comment NOT LIKE '%promotional%'
GROUP BY 
    s.s_name
ORDER BY 
    total_parts_supplied DESC, total_quantity_available DESC;
