SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE NULL 
        END) AS avg_return_amt,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', s.s_comment), '; ') AS supplier_comments,
    REGEXP_REPLACE(UPPER(p.p_name), '[^A-Z0-9 ]', '') AS sanitized_part_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    AVG(l.l_quantity) > 5
ORDER BY 
    total_revenue DESC;