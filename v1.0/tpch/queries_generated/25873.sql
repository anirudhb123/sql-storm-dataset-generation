SELECT 
    CONCAT(
        'Supplier: ', s.s_name, 
        ' | Region: ', r.r_name, 
        ' | Customer: ', c.c_name, 
        ' | Total Price: ', FORMAT(o.o_totalprice, 2), 
        ' | Order Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d'), 
        ' | Line Count: ', COUNT(l.l_orderkey)
    ) AS benchmark_output
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
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE 'special%'
GROUP BY 
    s.s_name, r.r_name, c.c_name, o.o_totalprice, o.o_orderdate
ORDER BY 
    o.o_orderdate DESC, COUNT(l.l_orderkey) DESC;
