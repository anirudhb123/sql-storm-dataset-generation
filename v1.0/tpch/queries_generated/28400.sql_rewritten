SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(p.p_retailprice) AS average_price, 
    STRING_AGG(DISTINCT l.l_comment, '; ') AS comments_summary
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
    n.n_regionkey IN (
        SELECT r.r_regionkey 
        FROM region r 
        WHERE r.r_name LIKE '%west%'
    ) 
    AND l.l_shipdate >= '1997-01-01' 
GROUP BY 
    p.p_name, s.s_name, n.n_name 
ORDER BY 
    total_quantity DESC, average_price ASC 
LIMIT 10;