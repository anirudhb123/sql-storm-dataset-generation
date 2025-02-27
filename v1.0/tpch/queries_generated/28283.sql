SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(*) AS supply_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    MAX(l.l_extendedprice) AS max_extended_price,
    STRING_AGG(CASE 
                WHEN l.l_returnflag = 'R' THEN l.l_comment 
                ELSE NULL 
                END, '; ') AS return_comments,
    SUBSTRING(REPLACE(p.p_comment, ' ', '-') FROM 1 FOR 20) AS truncated_comment,
    CONCAT('[', r.r_name, ']: ', n.n_name) AS region_nation_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%' AND
    s.s_comment NOT LIKE '%test%'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name
HAVING 
    total_available_quantity > 1000
ORDER BY 
    supply_count DESC, average_supply_cost ASC;
