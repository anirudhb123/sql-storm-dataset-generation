SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
    STRING_AGG(DISTINCT l.l_comment, '; ') AS aggregated_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' AND 
    s.s_acctbal > 1000.00
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
ORDER BY 
    total_quantity DESC, 
    o.o_orderdate ASC
LIMIT 100;