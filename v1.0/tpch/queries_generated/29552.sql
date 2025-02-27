SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    STUFF((
        SELECT 
            ',' + s.s_name 
        FROM 
            supplier s 
        INNER JOIN 
            partsupp ps ON ps.ps_suppkey = s.s_suppkey 
        WHERE 
            ps.ps_partkey = p.p_partkey 
        FOR XML PATH(''))
    , 1, 1, '') AS supplier_names
FROM 
    part p 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
WHERE 
    o.o_orderdate >= '2023-01-01' 
    AND o.o_orderdate < '2024-01-01' 
GROUP BY 
    p.p_name 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 
ORDER BY 
    total_sales DESC;
