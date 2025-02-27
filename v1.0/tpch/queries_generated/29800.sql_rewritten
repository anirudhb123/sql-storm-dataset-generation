SELECT 
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, s.s_nationkey
ORDER BY 
    total_quantity DESC, average_price ASC
LIMIT 10;