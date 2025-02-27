SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT(s.s_name, ' from ', s.s_address, ' in ', n.n_name) AS supplier_details,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS comments_collected
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
    p.p_name LIKE '%Wood%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
ORDER BY 
    total_quantity DESC, avg_price DESC;