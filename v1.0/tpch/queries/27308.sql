SELECT 
    DISTINCT p.p_name, 
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info, 
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned' 
    END AS return_status,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_name LIKE '%Steel%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_name, s.s_name, s.s_phone, l.l_returnflag 
ORDER BY 
    total_price DESC, p.p_name;