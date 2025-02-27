SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_total_price,
    STRING_AGG(DISTINCT s.s_address, '; ') AS supplier_addresses,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_acctbal > 1000 AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' AND 
    l.l_returnflag = 'N'
GROUP BY 
    c.c_name, s.s_name, p.p_name
ORDER BY 
    total_quantity DESC, order_count DESC
LIMIT 100;