SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS max_filled_order_value,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ': ', c.c_acctbal), '; ') AS customer_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 10 AND 
    AVG(ps.ps_supplycost) < (
        SELECT AVG(ps2.ps_supplycost) 
        FROM partsupp ps2 
        JOIN part p2 ON ps2.ps_partkey = p2.p_partkey
    )
ORDER BY 
    p.p_name;
