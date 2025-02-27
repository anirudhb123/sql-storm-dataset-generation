SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    r.r_name AS region_name,
    o.o_orderkey,
    o.o_orderdate,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT CONCAT('Comment: ', l.l_comment), '; ') AS combined_comments
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%rubber%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, o.o_orderkey, o.o_orderdate
ORDER BY 
    total_quantity DESC, average_price ASC;