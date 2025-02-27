SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    COUNT(l.l_linenumber) AS line_item_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT n.n_name, ', ') AS supplier_nations,
    CONCAT('Info: ', p.p_comment, ' | ', s.s_comment) AS combined_comments
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
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
HAVING 
    SUM(l.l_extendedprice) > 1000
ORDER BY 
    total_extended_price DESC, line_item_count ASC;
