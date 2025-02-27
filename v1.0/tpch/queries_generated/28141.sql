SELECT 
    CONCAT('Part Name: ', p.p_name, ' | Supplier: ', s.s_name, ' | Quantity: ', ps.ps_availqty, ' | Total Price: ', 
           ROUND(l.l_extendedprice * (1 - l.l_discount), 2), ' | Order Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d'))
    AS benchmark_string
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
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    p.p_name, s.s_name;
