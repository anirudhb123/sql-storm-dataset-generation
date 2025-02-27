SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part Name: ', p.p_name, ' | Order Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d'), 
           ' | Total Price: $', FORMAT(o.o_totalprice, 2), 
           ' | Nationality: ', n.n_name, ' | Region: ', r.r_name) AS detailed_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND 
    p.p_retailprice > 50.00
ORDER BY 
    o.o_orderdate DESC, s.s_name ASC;
