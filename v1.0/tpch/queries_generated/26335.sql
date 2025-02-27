SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderdate, 
    o.o_totalprice,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS truncated_comment,
    CONCAT(s.s_name, ' from ', SUBSTRING_INDEX(s.s_address, ' ', 1), ', ', n.n_name) AS supplier_info
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    p.p_name LIKE '%steel%' 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND s.s_acctbal > 1000 
ORDER BY 
    o.o_totalprice DESC 
LIMIT 10;
