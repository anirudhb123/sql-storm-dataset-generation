SELECT 
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    l.l_orderkey AS line_item_order_key,
    l.l_linenumber AS line_item_number,
    CASE 
        WHEN LENGTH(p.p_comment) > 15 THEN SUBSTRING(p.p_comment, 1, 15) || '...' 
        ELSE p.p_comment 
    END AS short_comment,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
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
    p.p_brand LIKE 'Brand%'
    AND s.s_acctbal > 1000
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, l.l_orderkey, l.l_linenumber, p.p_comment, r.r_name, n.n_name
ORDER BY 
    total_value DESC;
