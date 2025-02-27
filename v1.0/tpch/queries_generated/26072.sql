SELECT 
    p.p_name, 
    s.s_name, 
    l.l_quantity, 
    l.l_extendedprice, 
    o.o_orderdate, 
    c.c_mktsegment,
    CONCAT(s.s_name, ' supplied ', p.p_name, ' with quantity ', CAST(l.l_quantity AS varchar), ' on ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD')) AS order_details
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate BETWEEN TO_DATE('2023-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-12-31', 'YYYY-MM-DD')
AND 
    c.c_mktsegment LIKE 'B%'
ORDER BY 
    o.o_orderdate DESC, 
    l.l_extendedprice DESC
LIMIT 100;
