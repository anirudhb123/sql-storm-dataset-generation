SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name AS supplier_nation, 
    SUM(CASE 
            WHEN l_returnflag = 'R' THEN l_quantity 
            ELSE 0 
        END) AS total_returned_quantity,
    AVG(l_extendedprice * (1 - l_discount)) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS combined_comments
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
    p.p_name LIKE '%full%' AND 
    o.o_orderdate >= '1996-01-01' AND 
    o.o_orderdate < '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_returned_quantity DESC, avg_price_after_discount ASC
LIMIT 10;