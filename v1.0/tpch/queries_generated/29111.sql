SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    o.o_orderdate AS order_date,
    l.l_quantity AS quantity_ordered,
    l.l_extendedprice AS extended_price,
    l.l_discount AS discount_amount,
    (l.l_extendedprice * (1 - l.l_discount)) AS final_price,
    SUBSTRING_INDEX(SUBSTRING_INDEX(s.s_address, ' ', 3), ' ', -1) AS address_line,
    CONCAT('Order: ', o.o_orderkey, ' - Part: ', p.p_name, ' from Supplier: ', s.s_name) AS order_summary,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        WHEN l.l_linestatus = 'F' THEN 'Finished'
        ELSE 'Unknown'
    END AS order_status,
    LENGTH(p.p_comment) AS comment_length,
    REPLACE(p.p_comment, 'old', 'new') AS updated_comment
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
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    final_price DESC, order_date ASC
LIMIT 100;
