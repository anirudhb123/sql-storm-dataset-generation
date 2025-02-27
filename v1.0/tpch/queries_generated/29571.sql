SELECT 
    CONCAT_WS(' ', c.c_name, s.s_name, p.p_name) AS full_description,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_price,
    SUM(CASE 
            WHEN l.l_discount > 0 THEN l.l_quantity * (1 - l.l_discount) 
            ELSE l.l_quantity 
        END) AS total_quantity_discounted,
    REGEXP_REPLACE(r.r_name, 'Region', 'Area') AS modified_region_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND l.l_returnflag = 'N'
GROUP BY 
    full_description, modified_region_name
HAVING 
    total_orders > 5
ORDER BY 
    total_orders DESC, avg_price ASC;
