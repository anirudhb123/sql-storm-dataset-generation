SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(l.l_extendedprice) AS max_price,
    MIN(l.l_extendedprice) AS min_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' - ', s.s_comment), '; ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_size > 0 
    AND s.s_acctbal > 5000
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name
ORDER BY 
    total_available_quantity DESC, 
    p.p_name;
