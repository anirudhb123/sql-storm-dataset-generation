SELECT 
    p.p_name, 
    CONCAT(n.n_name, ' (', s.s_name, ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT SUBSTRING(l.l_comment, 1, 20), '; ') AS truncated_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    p.p_name, n.n_name, s.s_name
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;