SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    COUNT(l.l_orderkey) AS line_item_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_shipdate) AS latest_ship_date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT p.p_comment, '|') AS part_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10 AND
    s.s_acctbal > 500 AND
    o.o_orderdate >= DATE '1997-01-01' AND
    o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    total_extended_price DESC, line_item_count ASC
LIMIT 50;