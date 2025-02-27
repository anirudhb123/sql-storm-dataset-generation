SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    o.o_orderdate AS order_date,
    l.l_shipdate AS ship_date,
    CASE 
        WHEN l.l_returnflag = 'Y' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CONCAT('Order ', CAST(o.o_orderkey AS CHAR), ' shipped on ', DATE_FORMAT(l.l_shipdate, '%Y-%m-%d')) AS shipment_info,
    LOWER(CONCAT(p.p_name, ' supplied by ', s.s_name)) AS combined_info,
    LENGTH(p.p_comment) AS comment_length,
    SUBSTRING_INDEX(s.s_comment, ' ', 5) AS supplier_comment_excerpt
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND o.o_orderstatus = 'O'
    AND p.p_retailprice > 20.00
ORDER BY 
    l.l_shipdate DESC, 
    o.o_orderkey ASC
LIMIT 100;
