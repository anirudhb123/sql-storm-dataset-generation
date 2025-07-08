
SELECT 
    p.p_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    LISTAGG(DISTINCT p.p_comment, '; ') WITHIN GROUP (ORDER BY p.p_comment) AS combined_comments,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, p.p_comment
ORDER BY 
    total_quantity DESC, avg_extended_price DESC
LIMIT 100;
