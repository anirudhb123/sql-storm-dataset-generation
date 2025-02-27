SELECT 
    COUNT(*) AS total_orders, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue, 
    SUBSTRING(n_name, 1, 3) || '...' AS short_nation_name,
    STRING_AGG(DISTINCT p_type, ', ') AS unique_part_types,
    AVG(l_quantity) AS average_quantity_per_line_item
FROM 
    orders o 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    part p ON l.l_partkey = p.p_partkey 
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31' 
    AND l_returnflag = 'N' 
GROUP BY 
    short_nation_name
ORDER BY 
    total_revenue DESC;