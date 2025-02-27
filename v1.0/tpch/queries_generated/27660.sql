SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type, ', Price: ', FORMAT(p.p_retailprice, 2), ', Comment: ', p.p_comment) AS part_details,
    GROUP_CONCAT(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')') SEPARATOR '; ') AS suppliers,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    SUM(l.l_quantity) AS total_quantity
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
WHERE 
    p.p_size BETWEEN 1 AND 12
AND 
    o.o_orderdate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY 
    p.p_partkey
HAVING 
    order_count > 5
ORDER BY 
    total_quantity DESC
LIMIT 10;
