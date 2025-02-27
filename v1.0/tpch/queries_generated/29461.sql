SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE 
            WHEN LENGTH(p.p_name) > 30 THEN 1 
            ELSE 0 
        END) AS long_name_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    SUBSTRING(LOWER(p.p_comment) FROM 1 FOR 23) AS short_comment,
    r.r_name AS region_name,
    o.o_orderstatus,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
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
    r.r_name LIKE '%America%' 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, r.r_name, o.o_orderstatus
ORDER BY 
    revenue DESC, supplier_count DESC;
