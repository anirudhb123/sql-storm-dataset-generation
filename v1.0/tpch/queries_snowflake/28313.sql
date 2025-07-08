SELECT 
    CONCAT_WS(' - ', 
        SUBSTRING(p_name, 1, 20), 
        p_brand,
        p_container,
        CAST(p_retailprice AS CHAR)
    ) AS part_summary, 
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS total_returned_quantity,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    AVG(l_extendedprice) AS avg_extended_price,
    r_name AS region_name
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
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    part_summary, r_name
ORDER BY 
    total_returned_quantity DESC, avg_extended_price DESC
LIMIT 50;